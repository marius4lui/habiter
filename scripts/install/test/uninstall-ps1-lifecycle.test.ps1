$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$uninstaller = Join-Path $root 'scripts\install\uninstall.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("habiter-uninstall-lifecycle-" + [guid]::NewGuid().ToString('N'))
$profileRoot = Join-Path $testRoot 'profile'
$localRoot = Join-Path $profileRoot 'AppData\Local'
$programFilesRoot = Join-Path $testRoot 'Program Files'
$startMenuRoot = Join-Path $profileRoot 'Start Menu\Programs'
$installRoot = Join-Path $localRoot 'Programs\Habiter'
$shortcutPath = Join-Path $startMenuRoot 'Habiter.lnk'
$binPath = Join-Path $installRoot 'bin'
$commandPath = Join-Path $binPath 'habiter.cmd'
$pathState = Join-Path $testRoot 'user-path.txt'
$hostExecutable = (Get-Process -Id $PID).Path

function Invoke-Uninstaller([array]$Arguments) {
    $stdout = Join-Path $testRoot 'stdout'; $stderr = Join-Path $testRoot 'stderr'
    $previousErrorAction = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $hostExecutable -NoProfile -File $uninstaller @Arguments 1>$stdout 2>$stderr
    $exitCode = $LASTEXITCODE; $ErrorActionPreference = $previousErrorAction
    return [pscustomobject]@{ ExitCode = $exitCode; Output = ((Get-Content -Raw -LiteralPath $stdout -ErrorAction SilentlyContinue) + (Get-Content -Raw -LiteralPath $stderr -ErrorAction SilentlyContinue)) }
}
function Assert-Failure([string]$Code, [array]$Arguments) {
    $result = Invoke-Uninstaller $Arguments
    if ($result.ExitCode -eq 0 -or $result.Output -notmatch [regex]::Escape($Code)) { throw "Expected $Code, got exit $($result.ExitCode): $($result.Output)" }
}
function Assert-InstallationPresent {
    if (-not (Test-Path -LiteralPath (Join-Path $installRoot 'habiter.exe')) -or -not (Test-Path -LiteralPath $shortcutPath)) { throw 'Installation was not restored' }
}

try {
    New-Item -ItemType Directory -Path $installRoot, $binPath, $startMenuRoot, $programFilesRoot -Force | Out-Null
    'fixture executable' | Set-Content -LiteralPath (Join-Path $installRoot 'habiter.exe') -Encoding Ascii
    '@echo off' + [Environment]::NewLine + '"%~dp0..\habiter.exe" %*' | Set-Content -LiteralPath $commandPath -Encoding Ascii
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $installRoot 'habiter.exe'; $shortcut.WorkingDirectory = $installRoot; $shortcut.Save()
    $manifest = [ordered]@{
        schemaVersion = 1; product = 'habiter'; applicationId = 'dev.habiter.Habiter'; installId = 'lifecycle-fixture'
        version = '1.7.1'; scope = 'user'; canonicalInstallRoot = [IO.Path]::GetFullPath($installRoot)
        executable = Join-Path ([IO.Path]::GetFullPath($installRoot)) 'habiter.exe'
        integrationPaths = @($shortcutPath, $commandPath); pathEntry = $binPath; pathEntryAddedByInstaller = $true
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $installRoot '.habiter-install.json') -Encoding UTF8
    [IO.File]::WriteAllText($pathState, "C:\Tools;$binPath;C:\Other;$binPath-extra")

    $env:HABITER_TEST_USERPROFILE = $profileRoot
    $env:HABITER_TEST_LOCALAPPDATA = $localRoot
    $env:HABITER_TEST_PROGRAMFILES = $programFilesRoot
    $env:HABITER_TEST_START_MENU_DIR = $startMenuRoot
    $env:HABITER_TEST_PATH_STATE_FILE = $pathState
    $env:HABITER_UNINSTALL_TEST = '1'

    $env:HABITER_TEST_RUNNING = '1'; Assert-Failure 'HAB-UNWIN-071' @('-DryRun', '-InstallDir', $installRoot); Remove-Item Env:HABITER_TEST_RUNNING
    $challenge = "UNINSTALL HABITER $([IO.Path]::GetFullPath($installRoot))"
    [IO.File]::WriteAllText($pathState, "C:\Tools;$binPath;$binPath;C:\Other")
    Assert-Failure 'HAB-UNWIN-047' @('-DryRun', '-InstallDir', $installRoot)
    [IO.File]::WriteAllText($pathState, "C:\Tools;$binPath;C:\Other;$binPath-extra")
    $env:HABITER_TEST_NO_TTY = '1'; Assert-Failure 'HAB-UNWIN-074' @('-InstallDir', $installRoot); Remove-Item Env:HABITER_TEST_NO_TTY
    $force = Invoke-Uninstaller @('-Force')
    if ($force.ExitCode -eq 0 -or -not (Test-Path -LiteralPath $installRoot)) { throw 'Generic -Force unexpectedly authorized removal' }
    Assert-Failure 'HAB-UNWIN-075' @('-InstallDir', $installRoot, '-ConfirmTarget', 'UNINSTALL HABITER C:\wrong')

    $confirmFile = Join-Path $testRoot 'confirm.txt'
    [IO.File]::WriteAllLines($confirmFile, @('n')); $env:HABITER_TEST_CONFIRM_FILE = $confirmFile
    Assert-Failure 'HAB-UNWIN-076' @('-InstallDir', $installRoot)
    [IO.File]::WriteAllLines($confirmFile, @('y', 'wrong'))
    Assert-Failure 'HAB-UNWIN-077' @('-InstallDir', $installRoot)
    [IO.File]::WriteAllLines($confirmFile, @('y'))
    Assert-Failure 'HAB-UNWIN-073' @('-InstallDir', $installRoot)
    Remove-Item Env:HABITER_TEST_CONFIRM_FILE

    $env:HABITER_TEST_FAIL_STAGE_AT = '2'
    Assert-Failure 'HAB-UNWIN-081' @('-InstallDir', $installRoot, '-ConfirmTarget', $challenge)
    Remove-Item Env:HABITER_TEST_FAIL_STAGE_AT
    Assert-InstallationPresent
    if ([IO.File]::ReadAllText($pathState) -ne "C:\Tools;$binPath;C:\Other;$binPath-extra") { throw 'PATH changed during staging rollback' }

    $env:HABITER_TEST_FAIL_FINALIZE_AT = $installRoot
    Assert-Failure 'HAB-UNWIN-083' @('-InstallDir', $installRoot, '-ConfirmTarget', $challenge)
    Remove-Item Env:HABITER_TEST_FAIL_FINALIZE_AT
    Assert-InstallationPresent
    if ([IO.File]::ReadAllText($pathState) -ne "C:\Tools;$binPath;C:\Other;$binPath-extra") { throw 'PATH was not restored after finalization failure' }

    $dataRoot = Join-Path $localRoot 'dev.habiter.Habiter'
    New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
    'preserve me' | Set-Content -LiteralPath (Join-Path $dataRoot 'preferences')
    [IO.File]::WriteAllLines($confirmFile, @('y', $challenge)); $env:HABITER_TEST_CONFIRM_FILE = $confirmFile
    $success = Invoke-Uninstaller @('-InstallDir', $installRoot)
    if ($success.ExitCode -ne 0) { throw "Uninstall failed: $($success.Output)" }
    if (Test-Path -LiteralPath $installRoot) { throw 'Application root remained after uninstall' }
    if (Test-Path -LiteralPath $shortcutPath) { throw 'Owned shortcut remained after uninstall' }
    if (-not (Test-Path -LiteralPath (Join-Path $dataRoot 'preferences'))) { throw 'Application data was removed' }
    if ([IO.File]::ReadAllText($pathState) -ne 'C:\Tools;C:\Other;' + "$binPath-extra") { throw "Unrelated PATH entries changed: $([IO.File]::ReadAllText($pathState))" }
    if ($success.Output -notmatch 'Application data, backups, exports, credentials, and OS backups: preserved') { throw 'Completion summary omitted preserved data' }
    Assert-Failure 'HAB-UNWIN-060' @('-DryRun', '-InstallDir', $installRoot)

    Write-Host 'uninstall.ps1 lifecycle tests passed'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:HABITER_TEST_USERPROFILE, Env:HABITER_TEST_LOCALAPPDATA, Env:HABITER_TEST_PROGRAMFILES, Env:HABITER_TEST_START_MENU_DIR, Env:HABITER_TEST_PATH_STATE_FILE, Env:HABITER_UNINSTALL_TEST, Env:HABITER_TEST_RUNNING, Env:HABITER_TEST_NO_TTY, Env:HABITER_TEST_CONFIRM_FILE, Env:HABITER_TEST_FAIL_STAGE_AT, Env:HABITER_TEST_FAIL_FINALIZE_AT -ErrorAction SilentlyContinue
}
