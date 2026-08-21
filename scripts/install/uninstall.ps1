# Habiter PowerShell uninstaller
param(
    [string]$InstallDir = '',
    [switch]$System,
    [switch]$DryRun,
    [switch]$VerboseOutput,
    [string]$ConfirmTarget = '',
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$script:Phase = 'startup'
$script:UninstallId = [guid]::NewGuid().ToString('N').Substring(0, 12)
$script:CandidateCount = 0
$script:SelectedRoot = $null
$script:SelectedExecutable = $null
$script:SelectedScope = $null
$script:SelectedVersion = 'unknown'
$script:SelectedLegacy = $false
$script:SelectedIntegrations = @()
$script:MissingIntegrations = @()
$script:SelectedPathEntry = $null
$script:OriginalUserPath = $null
$script:UpdatedUserPath = $null
$script:PathChanged = $false
$script:Staged = @()

function Write-Step([int]$Number, [string]$Message) { Write-Host "[$Number/7] $Message" }
function Write-Detail([string]$Message) { Write-Host "      $Message" }
function Write-DebugDetail([string]$Message) { if ($VerboseOutput) { Write-Detail $Message } }
function Throw-UninstallError([string]$Code, [string]$Message, [string]$Recovery = '', [int]$ExitCode = 1) {
    $exception = [InvalidOperationException]::new($Message)
    $exception.Data['UninstallCode'] = $Code
    $exception.Data['Recovery'] = $Recovery
    $exception.Data['ExitCode'] = $ExitCode
    throw $exception
}
function Write-UninstallFailure($ErrorRecord) {
    $code = if ($ErrorRecord.Exception.Data['UninstallCode']) { $ErrorRecord.Exception.Data['UninstallCode'] } else { 'HAB-UNWIN-999' }
    $recovery = $ErrorRecord.Exception.Data['Recovery']
    $exitCode = if ($ErrorRecord.Exception.Data['ExitCode']) { [int]$ErrorRecord.Exception.Data['ExitCode'] } else { 1 }
    [Console]::Error.WriteLine('')
    [Console]::Error.WriteLine("Habiter uninstaller stopped [$code]")
    [Console]::Error.WriteLine("  Phase: $script:Phase")
    [Console]::Error.WriteLine("  Error: $($ErrorRecord.Exception.Message)")
    if ($recovery) { [Console]::Error.WriteLine("  Recovery: $recovery") }
    [Console]::Error.WriteLine("  Uninstall ID: $script:UninstallId")
    return $exitCode
}

function Show-Usage {
    Write-Host 'Habiter desktop uninstaller'
    Write-Host 'Usage: uninstall.ps1 [-DryRun] [-VerboseOutput] [-System] [-InstallDir PATH]'
    Write-Host '                     [-ConfirmTarget CHALLENGE] [-Help]'
    Write-Host ''
    Write-Host 'Download and review this repository-backed script before running it.'
}

function Test-PathEqual([string]$Left, [string]$Right) {
    return [string]::Equals($Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

function Get-CanonicalPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { Throw-UninstallError 'HAB-UNWIN-020' 'Empty installation target.' 'Pass one exact absolute path.' 20 }
    if (-not [IO.Path]::IsPathRooted($Path)) { Throw-UninstallError 'HAB-UNWIN-021' "Installation target is not absolute: $Path" 'Use an absolute path.' 20 }
    try { $full = [IO.Path]::GetFullPath($Path) } catch { Throw-UninstallError 'HAB-UNWIN-022' "Cannot canonicalize installation target: $Path" 'Check the exact literal path.' 20 }
    $volume = [IO.Path]::GetPathRoot($full)
    if (-not (Test-PathEqual $full $volume)) { $full = $full.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) }
    return $full
}

function Assert-NoReparsePath([string]$Path, [string]$Label) {
    $current = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    while ($current) {
        if (($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Throw-UninstallError 'HAB-UNWIN-023' "$Label crosses a reparse point: $($current.FullName)" 'Select a real, non-redirected installation path.' 20
        }
        $current = $current.Parent
    }
}

function Assert-SafeRoot([string]$Path) {
    $canonical = Get-CanonicalPath $Path
    if (-not (Test-Path -LiteralPath $canonical -PathType Container)) { Throw-UninstallError 'HAB-UNWIN-024' "Installation root is missing: $canonical" 'Select an existing Habiter installation.' 20 }
    Assert-NoReparsePath $canonical 'Installation root'
    $profile = if ($env:HABITER_TEST_USERPROFILE) { Get-CanonicalPath $env:HABITER_TEST_USERPROFILE } else { Get-CanonicalPath $env:USERPROFILE }
    $local = if ($env:HABITER_TEST_LOCALAPPDATA) { Get-CanonicalPath $env:HABITER_TEST_LOCALAPPDATA } else { Get-CanonicalPath $env:LOCALAPPDATA }
    $programFiles = if ($env:HABITER_TEST_PROGRAMFILES) { Get-CanonicalPath $env:HABITER_TEST_PROGRAMFILES } else { Get-CanonicalPath $env:ProgramFiles }
    $forbidden = @([IO.Path]::GetPathRoot($canonical), $profile, $local, (Join-Path $local 'Programs'), $programFiles)
    if ($forbidden | Where-Object { Test-PathEqual $canonical $_ }) { Throw-UninstallError 'HAB-UNWIN-025' "Refusing broad target: $canonical" 'Select the exact Habiter installation root.' 20 }
    return $canonical
}

function Assert-RegularFile([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-UninstallError 'HAB-UNWIN-040' "$Label is missing or not a regular file: $Path" 'Reinstall Habiter to repair ownership evidence.' 40 }
    Assert-NoReparsePath $Path $Label
}

function Get-ShortcutTarget([string]$Path) {
    try {
        $shell = New-Object -ComObject WScript.Shell
        return Get-CanonicalPath $shell.CreateShortcut($Path).TargetPath
    } catch { Throw-UninstallError 'HAB-UNWIN-041' "Cannot inspect Start Menu shortcut: $Path" 'The shortcut will be preserved for manual review.' 40 }
}

function Get-UserPathValue {
    if ($env:HABITER_TEST_PATH_STATE_FILE) {
        if (-not (Test-Path -LiteralPath $env:HABITER_TEST_PATH_STATE_FILE)) { return '' }
        return [IO.File]::ReadAllText($env:HABITER_TEST_PATH_STATE_FILE)
    }
    return [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Set-UserPathValue([string]$Value) {
    if ($env:HABITER_TEST_PATH_STATE_FILE) {
        if ($env:HABITER_UNINSTALL_TEST -ne '1') { Throw-UninstallError 'HAB-UNWIN-045' 'Test PATH state is disabled.' 'Use the normal user PATH store.' 40 }
        [IO.File]::WriteAllText($env:HABITER_TEST_PATH_STATE_FILE, $Value)
        return
    }
    [Environment]::SetEnvironmentVariable('Path', $Value, 'User')
}

function Get-NormalizedPathEntry([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or -not [IO.Path]::IsPathRooted($Value)) { return $null }
    try { return (Get-CanonicalPath $Value).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) } catch { return $null }
}

function Prepare-PathChange([string]$OwnedEntry) {
    if (-not $OwnedEntry) { return }
    $target = Get-NormalizedPathEntry $OwnedEntry
    if (-not $target) { Throw-UninstallError 'HAB-UNWIN-046' 'Installer-owned PATH entry is unresolved.' 'Refusing PATH cleanup.' 40 }
    $original = [string](Get-UserPathValue)
    $entries = $original.Split([char]';')
    $matches = @()
    for ($index = 0; $index -lt $entries.Length; $index++) {
        $normalized = Get-NormalizedPathEntry $entries[$index]
        if ($normalized -and (Test-PathEqual $normalized $target)) { $matches += $index }
    }
    if ($matches.Count -eq 0) { $script:MissingIntegrations += "PATH entry: $OwnedEntry"; return }
    if ($matches.Count -gt 1) { Throw-UninstallError 'HAB-UNWIN-047' 'Installer-owned PATH entry occurs more than once.' 'Refusing an ambiguous PATH rewrite.' 40 }
    $remaining = for ($index = 0; $index -lt $entries.Length; $index++) { if ($index -ne $matches[0]) { $entries[$index] } }
    $script:OriginalUserPath = $original
    $script:UpdatedUserPath = [string]::Join(';', [string[]]$remaining)
}

function Assert-ShortcutOwned([string]$Path, [string]$Executable) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { $script:MissingIntegrations += $Path; return $false }
    Assert-NoReparsePath $Path 'Start Menu shortcut'
    $target = Get-ShortcutTarget $Path
    if (-not (Test-PathEqual $target $Executable)) { Throw-UninstallError 'HAB-UNWIN-042' "Start Menu shortcut points to another target: $Path" 'It will be preserved for manual review.' 40 }
    return $true
}

function Assert-CommandOwned([string]$Path, [string]$Root) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { $script:MissingIntegrations += $Path; return $false }
    Assert-NoReparsePath $Path 'Habiter command wrapper'
    $expected = Join-Path $Root 'bin\habiter.cmd'
    if (-not (Test-PathEqual (Get-CanonicalPath $Path) (Get-CanonicalPath $expected))) { Throw-UninstallError 'HAB-UNWIN-043' "Command wrapper escapes the selected installation: $Path" 'It will be preserved for manual review.' 40 }
    $content = Get-Content -Raw -LiteralPath $Path
    if ($content -notmatch [regex]::Escape('"%~dp0..\habiter.exe" %*')) { Throw-UninstallError 'HAB-UNWIN-044' "Command wrapper does not target the selected Habiter executable: $Path" 'It will be preserved for manual review.' 40 }
    return $true
}

function Read-OwnershipManifest([string]$Root, [string]$Scope, [string]$StartMenuPath) {
    $manifestPath = Join-Path $Root '.habiter-install.json'
    Assert-RegularFile $manifestPath 'Ownership manifest'
    try { $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json } catch { Throw-UninstallError 'HAB-UNWIN-030' 'Ownership manifest JSON is malformed.' 'Reinstall Habiter before uninstalling.' 30 }
    if ($manifest.schemaVersion -ne 1) { Throw-UninstallError 'HAB-UNWIN-031' "Unsupported ownership manifest schema: $($manifest.schemaVersion)" 'Install a supported Habiter version before uninstalling.' 30 }
    if ($manifest.product -ne 'habiter' -or $manifest.applicationId -ne 'dev.habiter.Habiter') { Throw-UninstallError 'HAB-UNWIN-032' 'Ownership manifest identity mismatch.' 'The target is not verified as Habiter.' 30 }
    if ($manifest.scope -ne $Scope) { Throw-UninstallError 'HAB-UNWIN-033' 'Ownership manifest scope mismatch.' 'Select the matching user or system installation.' 30 }
    if ([string]::IsNullOrWhiteSpace($manifest.installId) -or $manifest.version -notmatch '^\d+\.\d+\.\d+$') { Throw-UninstallError 'HAB-UNWIN-034' 'Ownership manifest lifecycle fields are malformed.' 'Reinstall Habiter before uninstalling.' 30 }
    if (-not (Test-PathEqual (Get-CanonicalPath $manifest.canonicalInstallRoot) $Root)) { Throw-UninstallError 'HAB-UNWIN-035' 'Ownership manifest root mismatch.' 'Refusing a manifest that points outside the selected installation.' 30 }
    $executable = Join-Path $Root 'habiter.exe'
    if (-not (Test-PathEqual (Get-CanonicalPath $manifest.executable) $executable)) { Throw-UninstallError 'HAB-UNWIN-036' 'Ownership manifest executable escapes the selected installation.' 'Refusing the target.' 30 }
    Assert-RegularFile $executable 'Habiter executable'
    $allowedCommand = Join-Path $Root 'bin\habiter.cmd'
    foreach ($pathValue in @($manifest.integrationPaths)) {
        if ([string]::IsNullOrWhiteSpace($pathValue)) { Throw-UninstallError 'HAB-UNWIN-037' 'Ownership manifest contains an empty integration path.' 'Reinstall Habiter before uninstalling.' 30 }
        $path = Get-CanonicalPath ([string]$pathValue)
        if (Test-PathEqual $path $StartMenuPath) {
            if (Assert-ShortcutOwned $path $executable) { $script:SelectedIntegrations += $path }
        } elseif (Test-PathEqual $path $allowedCommand) {
            [void](Assert-CommandOwned $path $Root)
        } else { Throw-UninstallError 'HAB-UNWIN-038' "Manifest contains a non-allow-listed integration path: $path" 'Reinstall Habiter or review the manifest manually.' 30 }
    }
    if ($null -ne $manifest.pathEntry -and -not (Test-PathEqual (Get-CanonicalPath $manifest.pathEntry) (Join-Path $Root 'bin'))) { Throw-UninstallError 'HAB-UNWIN-039' 'Manifest PATH entry escapes the selected installation.' 'Refusing PATH cleanup.' 30 }
    if ($manifest.pathEntryAddedByInstaller -notin @($true, $false)) { Throw-UninstallError 'HAB-UNWIN-039' 'Manifest PATH ownership flag is invalid.' 'Refusing PATH cleanup.' 30 }
    $script:SelectedExecutable = $executable
    $script:SelectedVersion = [string]$manifest.version
    $script:SelectedPathEntry = if ($manifest.pathEntryAddedByInstaller) { Get-CanonicalPath $manifest.pathEntry } else { $null }
    Prepare-PathChange $script:SelectedPathEntry
    $script:SelectedLegacy = $false
}

function Read-LegacyInstallation([string]$Root, [string]$StartMenuPath) {
    $executable = Join-Path $Root 'habiter.exe'
    Assert-RegularFile $executable 'Legacy Habiter executable'
    if (-not (Assert-ShortcutOwned $StartMenuPath $executable)) { Throw-UninstallError 'HAB-UNWIN-050' 'Legacy installation lacks a matching Start Menu shortcut.' 'Reinstall Habiter to create an ownership manifest.' 50 }
    $command = Join-Path $Root 'bin\habiter.cmd'
    if (-not (Assert-CommandOwned $command $Root)) { Throw-UninstallError 'HAB-UNWIN-051' 'Legacy installation lacks a matching command wrapper.' 'Reinstall Habiter to create an ownership manifest.' 50 }
    $script:SelectedExecutable = $executable
    $script:SelectedVersion = 'legacy'
    $script:SelectedIntegrations += $StartMenuPath
    $script:SelectedPathEntry = $null
    $script:SelectedLegacy = $true
}

function Inspect-Candidate([string]$Requested, [string]$Scope, [string]$StartMenuPath) {
    if (-not (Test-Path -LiteralPath $Requested)) { return }
    $root = Assert-SafeRoot $Requested
    $script:CandidateCount++
    if ($script:CandidateCount -gt 1) { Throw-UninstallError 'HAB-UNWIN-061' "Multiple Habiter installations were found: $($script:SelectedRoot) and $root" 'Run again with -InstallDir and one exact candidate.' 60 }
    $script:SelectedRoot = $root
    $script:SelectedScope = $Scope
    $manifest = Join-Path $root '.habiter-install.json'
    if (Test-Path -LiteralPath $manifest) { Read-OwnershipManifest $root $Scope $StartMenuPath } else { Read-LegacyInstallation $root $StartMenuPath }
    Write-Detail "Candidate: $root"
    Write-Detail "Scope: $Scope"
    Write-Detail "Version: $($script:SelectedVersion)"
    Write-Detail $(if ($script:SelectedLegacy) { 'Evidence: conservative legacy identity + integration checks' } else { 'Evidence: ownership manifest + executable/integration checks' })
}

function Find-HabiterInstallation {
    $script:Phase = 'detect-installations'
    $local = if ($env:HABITER_TEST_LOCALAPPDATA) { $env:HABITER_TEST_LOCALAPPDATA } else { $env:LOCALAPPDATA }
    $programFiles = if ($env:HABITER_TEST_PROGRAMFILES) { $env:HABITER_TEST_PROGRAMFILES } else { $env:ProgramFiles }
    $startMenuDir = if ($env:HABITER_TEST_START_MENU_DIR) { $env:HABITER_TEST_START_MENU_DIR } else { [Environment]::GetFolderPath('Programs') }
    $startMenu = Get-CanonicalPath (Join-Path $startMenuDir 'Habiter.lnk')
    $userRoot = Get-CanonicalPath (Join-Path $local 'Programs\Habiter')
    $systemRoot = Get-CanonicalPath (Join-Path $programFiles 'Habiter')
    if ($InstallDir) { Inspect-Candidate $InstallDir $(if ($System) { 'system' } else { 'user' }) $startMenu }
    elseif ($System) { Inspect-Candidate $systemRoot 'system' $startMenu }
    else { Inspect-Candidate $userRoot 'user' $startMenu; Inspect-Candidate $systemRoot 'system' $startMenu }
    if ($script:CandidateCount -eq 0) { Throw-UninstallError 'HAB-UNWIN-060' 'No verified Habiter installation was found.' 'Use -InstallDir with one exact custom installation root.' 60 }
}

function Write-RemovalPlan {
    $script:Phase = 'removal-plan'
    Write-Step 4 'Removal plan'
    Write-Detail "Application: $($script:SelectedRoot)"
    if ($script:SelectedIntegrations.Count -eq 0) { Write-Detail 'Integration: none' } else { $script:SelectedIntegrations | ForEach-Object { Write-Detail "Integration: $_" } }
    $script:MissingIntegrations | ForEach-Object { Write-Detail "Missing optional integration: $_" }
    if ($script:SelectedPathEntry) { Write-Detail "PATH entry owned by installer: $($script:SelectedPathEntry)" }
    Write-Detail 'Application data: preserved'
    Write-Detail 'Backups, exports, credentials, and OS backups: preserved'
    if ($script:SelectedLegacy) { Write-Detail 'Warning: legacy installation without an ownership manifest' }
    Write-Detail "Confirmation challenge: UNINSTALL HABITER $($script:SelectedRoot)"
}

function Assert-HabiterNotRunning {
    $script:Phase = 'check-running-processes'
    $running = @(if ($env:HABITER_TEST_RUNNING -eq '1') { [pscustomobject]@{ Id = 'fixture' } } else { Get-Process -Name habiter -ErrorAction SilentlyContinue })
    if ($running.Count -gt 0) { Throw-UninstallError 'HAB-UNWIN-071' 'Habiter is still running.' 'Close Habiter normally, then rerun the same reviewed plan.' 71 }
    Write-Detail 'Not running'
}

function Read-ConfirmationValue([string]$Prompt) {
    if ($env:HABITER_TEST_CONFIRM_FILE) {
        if ($env:HABITER_UNINSTALL_TEST -ne '1') { Throw-UninstallError 'HAB-UNWIN-072' 'Test confirmation input is disabled.' 'Use an interactive terminal.' 72 }
        if ($null -eq $script:ConfirmationValues) { $script:ConfirmationValues = @(Get-Content -LiteralPath $env:HABITER_TEST_CONFIRM_FILE); $script:ConfirmationIndex = 0 }
        if ($script:ConfirmationIndex -ge $script:ConfirmationValues.Count) { Throw-UninstallError 'HAB-UNWIN-073' 'Confirmation input closed before approval.' 'No files or settings were changed.' 73 }
        $value = $script:ConfirmationValues[$script:ConfirmationIndex]
        $script:ConfirmationIndex++
        return $value
    }
    if ($env:HABITER_TEST_NO_TTY -eq '1' -or [Console]::IsInputRedirected) { Throw-UninstallError 'HAB-UNWIN-074' 'An interactive terminal is required.' 'For automation, pass both -InstallDir and -ConfirmTarget.' 74 }
    return Read-Host $Prompt
}

function Confirm-Removal {
    $script:Phase = 'confirm-removal'
    $challenge = "UNINSTALL HABITER $($script:SelectedRoot)"
    if ($ConfirmTarget) {
        if ($ConfirmTarget -ne $challenge) { Throw-UninstallError 'HAB-UNWIN-075' 'Automation challenge does not match the canonical target.' 'Copy the exact challenge from -DryRun.' 75 }
        Write-Detail 'Exact non-interactive target and challenge accepted'
        return
    }
    $answer = Read-ConfirmationValue 'Continue with this exact removal plan? [y/N]'
    if ($answer -notin @('y', 'Y')) { Throw-UninstallError 'HAB-UNWIN-076' 'Uninstall cancelled at the first confirmation.' 'No files or settings were changed.' 76 }
    $typed = Read-ConfirmationValue "Type $challenge"
    if ($typed -ne $challenge) { Throw-UninstallError 'HAB-UNWIN-077' 'Typed challenge did not match the canonical target.' 'No files or settings were changed.' 77 }
}

function Stage-RemovalPath([string]$Original) {
    $quarantine = "$Original.habiter-uninstall-$($script:UninstallId)"
    if (Test-Path -LiteralPath $quarantine) { Throw-UninstallError 'HAB-UNWIN-080' "Quarantine already exists: $quarantine" 'Review the previous recovery state; nothing was overwritten.' 80 }
    $next = $script:Staged.Count + 1
    if ($env:HABITER_TEST_FAIL_STAGE_AT -eq [string]$next) { Throw-UninstallError 'HAB-UNWIN-081' "Injected staging failure before: $Original" 'Already staged targets will be restored.' 81 }
    try { Move-Item -LiteralPath $Original -Destination $quarantine } catch { Throw-UninstallError 'HAB-UNWIN-082' "Cannot move target to quarantine: $Original" 'Check permissions; already staged targets will be restored.' 82 }
    $script:Staged += [pscustomobject]@{ Original = $Original; Quarantine = $quarantine }
}

function Restore-StagedRemoval {
    if ($script:PathChanged) {
        try { Set-UserPathValue $script:OriginalUserPath; [Console]::Error.WriteLine('  Restored: user PATH') } catch { [Console]::Error.WriteLine("  Recovery warning: could not restore user PATH: $($_.Exception.Message)") }
        $script:PathChanged = $false
    }
    if ($script:Staged.Count -eq 0) { return }
    [Console]::Error.WriteLine('Recovery summary:')
    for ($index = $script:Staged.Count - 1; $index -ge 0; $index--) {
        $item = $script:Staged[$index]
        if (Test-Path -LiteralPath $item.Quarantine) {
            if (Test-Path -LiteralPath $item.Original) { [Console]::Error.WriteLine("  Recovery warning: preserved quarantine because the original path reappeared: $($item.Quarantine)") }
            else { try { Move-Item -LiteralPath $item.Quarantine -Destination $item.Original; [Console]::Error.WriteLine("  Restored: $($item.Original)") } catch { [Console]::Error.WriteLine("  Recovery warning: left in quarantine: $($item.Quarantine)") } }
        } else { [Console]::Error.WriteLine("  Already finalized: $($item.Original)") }
    }
}

function Finalize-StagedItem($Item) {
    if ($env:HABITER_TEST_FAIL_FINALIZE_AT -eq $Item.Original) { Throw-UninstallError 'HAB-UNWIN-083' "Injected finalization failure: $($Item.Original)" 'Recoverable quarantine paths are listed below.' 83 }
    try { Remove-Item -LiteralPath $Item.Quarantine -Recurse -Force } catch { Throw-UninstallError 'HAB-UNWIN-084' "Cannot finalize quarantined target: $($Item.Quarantine)" 'Recoverable quarantine paths are listed below.' 84 }
}

function Remove-SelectedInstallation {
    $script:Phase = 'stage-removal'
    foreach ($path in $script:SelectedIntegrations) { Stage-RemovalPath $path }
    Stage-RemovalPath $script:SelectedRoot
    if ($null -ne $script:UpdatedUserPath) { Set-UserPathValue $script:UpdatedUserPath; $script:PathChanged = $true }
    $script:Phase = 'finalize-removal'
    foreach ($item in @($script:Staged | Sort-Object { if (Test-PathEqual $_.Original $script:SelectedRoot) { 0 } else { 1 } })) { Finalize-StagedItem $item }
    $script:PathChanged = $false
    $script:Staged = @()
}

function Invoke-HabiterUninstall {
    if ($Help) { Show-Usage; return }
    if ($ConfirmTarget -and -not $InstallDir) { Throw-UninstallError 'HAB-UNWIN-005' '-ConfirmTarget requires -InstallDir.' 'Automation must name one exact installation.' 2 }
    Write-Host 'Habiter uninstaller'; Write-Host ''
    Write-Step 1 'Detecting installations'; Find-HabiterInstallation
    Write-Step 2 'Verifying ownership'; Write-Detail "Verified: $($script:SelectedRoot)"
    Write-Step 3 'Checking running processes'; Assert-HabiterNotRunning
    Write-RemovalPlan
    if ($DryRun) { Write-Step 5 'Dry run'; Write-Detail 'No files or settings were changed.'; Write-Step 6 'Removal skipped'; Write-Step 7 'Done'; return }
    Write-Step 5 'Confirming removal'; Confirm-Removal
    Write-Step 6 'Removing and verifying'; Remove-SelectedInstallation
    Write-Step 7 'Done'
    Write-Detail "Removed application: $($script:SelectedRoot)"
    Write-Detail 'Application data, backups, exports, credentials, and OS backups: preserved'
}

if ($env:HABITER_TEST_MODE -ne 'functions') {
    try { Invoke-HabiterUninstall } catch { Restore-StagedRemoval; exit (Write-UninstallFailure $_) }
}
