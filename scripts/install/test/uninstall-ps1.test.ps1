$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$uninstaller = Join-Path $root 'scripts\install\uninstall.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("habiter-uninstall-discovery-" + [guid]::NewGuid().ToString('N'))
$profileRoot = Join-Path $testRoot 'profile'
$localRoot = Join-Path $profileRoot 'AppData\Local'
$programFilesRoot = Join-Path $testRoot 'Program Files'
$startMenuRoot = Join-Path $profileRoot 'Start Menu\Programs'
$userRoot = Join-Path $localRoot 'Programs\Habiter'
$systemRoot = Join-Path $programFilesRoot 'Habiter'
$hostExecutable = (Get-Process -Id $PID).Path

function Reset-Fixtures {
    Remove-Item -LiteralPath $profileRoot, $programFilesRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $localRoot, $programFilesRoot, $startMenuRoot -Force | Out-Null
}
function Write-Manifest([string]$InstallRoot, [string]$Scope = 'user', [array]$Integrations = @()) {
    $value = [ordered]@{
        schemaVersion = 1; product = 'habiter'; applicationId = 'dev.habiter.Habiter'; installId = 'fixture-install'
        version = '1.7.1'; scope = $Scope; canonicalInstallRoot = [IO.Path]::GetFullPath($InstallRoot)
        executable = Join-Path ([IO.Path]::GetFullPath($InstallRoot)) 'habiter.exe'; integrationPaths = $Integrations
        pathEntry = $null; pathEntryAddedByInstaller = $false
    }
    $value | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $InstallRoot '.habiter-install.json') -Encoding UTF8
}
function New-Install([string]$InstallRoot, [string]$Scope = 'user') {
    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
    'fixture executable' | Set-Content -LiteralPath (Join-Path $InstallRoot 'habiter.exe') -Encoding Ascii
    Write-Manifest $InstallRoot $Scope
}
function Add-DesktopIntegration([string]$InstallRoot, [string]$ShortcutTarget = '') {
    $bin = Join-Path $InstallRoot 'bin'
    New-Item -ItemType Directory -Path $bin, $startMenuRoot -Force | Out-Null
    '@echo off' + [Environment]::NewLine + '"%~dp0..\habiter.exe" %*' | Set-Content -LiteralPath (Join-Path $bin 'habiter.cmd') -Encoding Ascii
    $shortcutPath = Join-Path $startMenuRoot 'Habiter.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = if ($ShortcutTarget) { $ShortcutTarget } else { Join-Path $InstallRoot 'habiter.exe' }
    $shortcut.WorkingDirectory = $InstallRoot
    $shortcut.Save()
    return $shortcutPath
}
function Invoke-Uninstaller([array]$Arguments) {
    $stdout = Join-Path $testRoot 'stdout'; $stderr = Join-Path $testRoot 'stderr'
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $hostExecutable -NoProfile -File $uninstaller @Arguments 1>$stdout 2>$stderr
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    return [pscustomobject]@{ ExitCode = $exitCode; Output = ((Get-Content -Raw -LiteralPath $stdout -ErrorAction SilentlyContinue) + (Get-Content -Raw -LiteralPath $stderr -ErrorAction SilentlyContinue)) }
}
function Assert-Failure([string]$Code, [array]$Arguments) {
    $result = Invoke-Uninstaller $Arguments
    if ($result.ExitCode -eq 0 -or $result.Output -notmatch [regex]::Escape($Code)) { throw "Expected $Code, got exit $($result.ExitCode): $($result.Output)" }
}

try {
    $env:HABITER_TEST_USERPROFILE = $profileRoot
    $env:HABITER_TEST_LOCALAPPDATA = $localRoot
    $env:HABITER_TEST_PROGRAMFILES = $programFilesRoot
    $env:HABITER_TEST_START_MENU_DIR = $startMenuRoot
    Reset-Fixtures

    $help = Invoke-Uninstaller @('-Help')
    if ($help.ExitCode -ne 0 -or $help.Output -notmatch 'Habiter desktop uninstaller') { throw 'Help failed' }

    New-Install $userRoot
    $dry = Invoke-Uninstaller @('-DryRun')
    if ($dry.ExitCode -ne 0 -or $dry.Output -notmatch [regex]::Escape("Application: $userRoot") -or $dry.Output -notmatch 'Application data: preserved') { throw "User dry run failed: $($dry.Output)" }
    if (-not (Test-Path -LiteralPath (Join-Path $userRoot 'habiter.exe'))) { throw 'Dry run mutated the user installation' }

    Reset-Fixtures
    $custom = Join-Path $testRoot 'custom\Habiter'; New-Install $custom
    $dry = Invoke-Uninstaller @('-DryRun', '-InstallDir', $custom)
    if ($dry.ExitCode -ne 0 -or $dry.Output -notmatch [regex]::Escape("Candidate: $custom")) { throw 'Custom discovery failed' }

    Reset-Fixtures
    New-Install $systemRoot 'system'
    $dry = Invoke-Uninstaller @('-DryRun', '-System')
    if ($dry.ExitCode -ne 0 -or $dry.Output -notmatch 'Scope: system') { throw 'System discovery failed' }

    Reset-Fixtures
    Assert-Failure 'HAB-UNWIN-060' @('-DryRun')

    New-Install $userRoot; New-Install $systemRoot 'system'
    Assert-Failure 'HAB-UNWIN-061' @('-DryRun')

    Reset-Fixtures
    New-Install $userRoot
    '{bad json' | Set-Content -LiteralPath (Join-Path $userRoot '.habiter-install.json') -Encoding Ascii
    Assert-Failure 'HAB-UNWIN-030' @('-DryRun')

    Write-Manifest $userRoot
    $manifestPath = Join-Path $userRoot '.habiter-install.json'
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $manifest.schemaVersion = 99; $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Assert-Failure 'HAB-UNWIN-031' @('-DryRun')

    Write-Manifest $userRoot
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $manifest.executable = Join-Path $testRoot 'outside.exe'; $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Assert-Failure 'HAB-UNWIN-036' @('-DryRun')

    Reset-Fixtures
    New-Install $userRoot
    $shortcutPath = Add-DesktopIntegration $userRoot
    Remove-Item -LiteralPath (Join-Path $userRoot '.habiter-install.json')
    $legacy = Invoke-Uninstaller @('-DryRun')
    if ($legacy.ExitCode -ne 0 -or $legacy.Output -notmatch 'conservative legacy identity' -or $legacy.Output -notmatch 'Warning: legacy installation') { throw "Legacy discovery failed: $($legacy.Output)" }

    Write-Manifest $userRoot 'user' @($shortcutPath, (Join-Path $userRoot 'bin\habiter.cmd'))
    Remove-Item -LiteralPath $shortcutPath
    $missing = Invoke-Uninstaller @('-DryRun')
    if ($missing.ExitCode -ne 0 -or $missing.Output -notmatch 'Missing optional integration') { throw "Missing integration was not distinguished: $($missing.Output)" }

    Add-DesktopIntegration $userRoot (Join-Path $testRoot 'unowned.exe') | Out-Null
    Assert-Failure 'HAB-UNWIN-042' @('-DryRun')

    Reset-Fixtures
    $realRoot = Join-Path $testRoot 'real-habiter'; New-Install $realRoot
    New-Item -ItemType Directory -Path (Split-Path $userRoot -Parent) -Force | Out-Null
    New-Item -ItemType Junction -Path $userRoot -Target $realRoot | Out-Null
    Assert-Failure 'HAB-UNWIN-023' @('-DryRun')

    Reset-Fixtures
    Assert-Failure 'HAB-UNWIN-025' @('-DryRun', '-InstallDir', $profileRoot)

    Write-Host 'uninstall.ps1 discovery tests passed'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item Env:HABITER_TEST_USERPROFILE, Env:HABITER_TEST_LOCALAPPDATA, Env:HABITER_TEST_PROGRAMFILES, Env:HABITER_TEST_START_MENU_DIR -ErrorAction SilentlyContinue
}
