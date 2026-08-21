# Habiter PowerShell installer
param(
    [ValidateSet('stable', 'beta')][string]$Channel = 'stable',
    [ValidatePattern('^$|^\d+\.\d+\.\d+$')][string]$Version = '',
    [string]$InstallDir = '',
    [switch]$DryRun,
    [switch]$VerboseOutput,
    [switch]$Diagnostics,
    [switch]$System,
    [switch]$NoDesktopIntegration
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$script:TempDirectory = $null
$script:BackupDirectory = $null
$script:FinalDirectory = $null
$script:Phase = 'startup'
$script:InstallId = [guid]::NewGuid().ToString('N').Substring(0, 12)
$script:IntegrationPaths = @()
$script:PathEntry = $null
$script:PathEntryAddedByInstaller = $false
$ApiBase = if ($env:HABITER_API_BASE) { $env:HABITER_API_BASE } else { 'https://get.habiter.dev' }

function Write-Step([int]$Number, [string]$Message) { Write-Host "[$Number/7] $Message" }
function Write-Detail([string]$Message) { Write-Host "      $Message" }
function Write-DebugDetail([string]$Message) { if ($VerboseOutput) { Write-Detail $Message } }
function Throw-InstallerError([string]$Code, [string]$Message, [string]$Hint = '', [int]$ExitCode = 1) {
    $exception = [InvalidOperationException]::new($Message)
    $exception.Data['InstallerCode'] = $Code
    $exception.Data['Hint'] = $Hint
    $exception.Data['ExitCode'] = $ExitCode
    throw $exception
}
function Write-InstallerDiagnostics {
    if (-not ($Diagnostics -or $VerboseOutput)) { return }
    [Console]::Error.WriteLine('Diagnostics:')
    [Console]::Error.WriteLine("  installId=$script:InstallId phase=$script:Phase")
    [Console]::Error.WriteLine("  powershell=$($PSVersionTable.PSVersion) edition=$($PSVersionTable.PSEdition)")
    [Console]::Error.WriteLine("  os=$([Environment]::OSVersion.VersionString) process64=$([Environment]::Is64BitProcess) os64=$([Environment]::Is64BitOperatingSystem)")
    [Console]::Error.WriteLine("  channel=$Channel version=$(if ($Version) { $Version } else { 'latest' }) system=$([bool]$System) dryRun=$([bool]$DryRun)")
    [Console]::Error.WriteLine("  installDir=$(if ($script:FinalDirectory) { $script:FinalDirectory } elseif ($InstallDir) { $InstallDir } else { 'not-resolved' })")
}
function Write-InstallerFailure($ErrorRecord) {
    $code = if ($ErrorRecord.Exception.Data['InstallerCode']) { $ErrorRecord.Exception.Data['InstallerCode'] } else { 'HAB-WIN-999' }
    $hint = $ErrorRecord.Exception.Data['Hint']
    $exitCode = if ($ErrorRecord.Exception.Data['ExitCode']) { [int]$ErrorRecord.Exception.Data['ExitCode'] } else { 1 }
    [Console]::Error.WriteLine('')
    [Console]::Error.WriteLine("Habiter installer failed [$code]")
    [Console]::Error.WriteLine("  Phase: $script:Phase")
    [Console]::Error.WriteLine("  Error: $($ErrorRecord.Exception.Message)")
    if ($hint) { [Console]::Error.WriteLine("  Fix: $hint") }
    [Console]::Error.WriteLine("  Install ID: $script:InstallId")
    Write-InstallerDiagnostics
    return $exitCode
}

function Get-NormalizedArchitecture([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { Throw-InstallerError 'HAB-WIN-010' 'Unable to detect the Windows architecture.' 'Set HABITER_ARCHITECTURE to AMD64 or ARM64 and retry.' 10 }
    switch ($Value.ToLowerInvariant()) {
        { $_ -in @('amd64', 'x86_64', 'x64') } { return 'x64' }
        { $_ -in @('arm64', 'aarch64') } { return 'arm64' }
        default { Throw-InstallerError 'HAB-WIN-011' "Unsupported architecture: $Value" 'Windows x64 is supported; Windows ARM64 is not currently published.' 10 }
    }
}

function Get-DetectedArchitecture($RuntimeArchitecture) {
    if ($null -ne $RuntimeArchitecture) {
        return Get-NormalizedArchitecture ([string]$RuntimeArchitecture)
    }
    foreach ($candidate in @($env:PROCESSOR_ARCHITEW6432, $env:PROCESSOR_ARCHITECTURE)) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            return Get-NormalizedArchitecture $candidate
        }
    }
    Throw-InstallerError 'HAB-WIN-010' 'Unable to detect the Windows architecture.' 'Set HABITER_ARCHITECTURE to AMD64 or ARM64 and retry.' 10
}

function Assert-ResolverResponse($Response) {
    if (-not $Response -or $Response.version -notmatch '^\d+\.\d+\.\d+$') { Throw-InstallerError 'HAB-WIN-022' 'Resolver returned an invalid version.' 'Retry later; if it persists, report the Install ID.' 22 }
    if ($Response.platform -ne 'windows' -or $Response.architecture -notin @('x64', 'arm64')) { Throw-InstallerError 'HAB-WIN-023' 'Resolver returned an invalid target.' 'Do not install this artifact; report the Install ID.' 22 }
    if ($Response.artifact.format -ne 'zip') { Throw-InstallerError 'HAB-WIN-024' 'Resolver did not return a Windows ZIP.' 'Do not install this artifact; report the Install ID.' 22 }
    if ($Response.artifact.fileName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]+$') { Throw-InstallerError 'HAB-WIN-025' 'Resolver returned an invalid file name.' 'Do not install this artifact; report the Install ID.' 22 }
    if ($Response.artifact.url -notmatch '^https://') { Throw-InstallerError 'HAB-WIN-026' 'Resolver returned a non-HTTPS URL.' 'Do not bypass HTTPS validation.' 22 }
    if ($Response.artifact.sha256 -notmatch '^[a-f0-9]{64}$') { Throw-InstallerError 'HAB-WIN-027' 'Resolver returned an invalid checksum.' 'Do not install this artifact; report the Install ID.' 22 }
    if ([long]$Response.artifact.size -lt 1) { Throw-InstallerError 'HAB-WIN-028' 'Resolver returned an invalid size.' 'Do not install this artifact; report the Install ID.' 22 }
}

function Resolve-HabiterRelease([string]$Architecture) {
    if ($env:HABITER_RESOLVER_JSON) {
        $response = $env:HABITER_RESOLVER_JSON | ConvertFrom-Json
    } else {
        $query = "channel=$Channel"
        if ($Version) { $query += "&version=$Version" }
        $uri = "$ApiBase/api/v1/install/windows/$Architecture`?$query"
        Write-DebugDetail "Resolver: $uri"
        try { $response = Invoke-RestMethod -Uri $uri -Method Get -MaximumRedirection 0 -Headers @{ Accept = 'application/json' } }
        catch { Throw-InstallerError 'HAB-WIN-020' "Release resolver request failed: $($_.Exception.Message)" 'Check internet, proxy, TLS and get.habiter.dev, then retry with -Diagnostics.' 20 }
    }
    Assert-ResolverResponse $response
    return $response
}

function Assert-HabiterChecksum([string]$Path, [string]$Expected) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected) { Throw-InstallerError 'HAB-WIN-040' 'SHA-256 mismatch. Installation aborted.' 'Delete any cached artifact and retry; never bypass checksum verification.' 40 }
    return $actual
}

function Restore-PreviousInstall {
    if ($script:BackupDirectory -and (Test-Path -LiteralPath $script:BackupDirectory) -and $script:FinalDirectory) {
        Remove-Item -LiteralPath $script:FinalDirectory -Recurse -Force -ErrorAction SilentlyContinue
        Move-Item -LiteralPath $script:BackupDirectory -Destination $script:FinalDirectory
    }
}

function Assert-HabiterNotRunning([string]$Root) {
    $running = @(Get-Process -Name habiter -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0 -and (Test-Path -LiteralPath $Root)) {
        $ids = ($running | ForEach-Object Id) -join ', '
        Throw-InstallerError 'HAB-WIN-060' "Habiter is still running (PID: $ids)." 'Close Habiter, or run: Get-Process habiter | Stop-Process, then retry.' 60
    }
}

function Install-DesktopIntegration([string]$Root) {
    $startMenuDirectory = if ($env:HABITER_START_MENU_DIR) { $env:HABITER_START_MENU_DIR } else { [Environment]::GetFolderPath('Programs') }
    New-Item -ItemType Directory -Path $startMenuDirectory -Force | Out-Null
    $startMenu = Join-Path $startMenuDirectory 'Habiter.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($startMenu)
    $shortcut.TargetPath = Join-Path $Root 'habiter.exe'
    $shortcut.WorkingDirectory = $Root
    $shortcut.Description = 'Habiter'
    $shortcut.Save()
    $script:IntegrationPaths += $startMenu

    $binDirectory = Join-Path $Root 'bin'
    New-Item -ItemType Directory -Path $binDirectory -Force | Out-Null
    '@echo off' + [Environment]::NewLine + '"%~dp0..\habiter.exe" %*' | Set-Content -LiteralPath (Join-Path $binDirectory 'habiter.cmd') -Encoding Ascii
    $script:IntegrationPaths += (Join-Path $binDirectory 'habiter.cmd')
    $script:PathEntry = $binDirectory
    if (-not $env:HABITER_SKIP_PATH_UPDATE) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $entries = @($userPath -split ';' | Where-Object { $_ })
        if ($entries -notcontains $binDirectory) {
            [Environment]::SetEnvironmentVariable('Path', (($entries + $binDirectory) -join ';'), 'User')
            $script:PathEntryAddedByInstaller = $true
            Write-Detail "Added command directory to user PATH: $binDirectory"
        }
    }
}

function Write-OwnershipManifest([string]$Root, [string]$VersionValue, [bool]$SystemScope) {
    $canonicalRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $manifest = [ordered]@{
        schemaVersion = 1
        product = 'habiter'
        applicationId = 'dev.habiter.Habiter'
        installId = $script:InstallId
        version = $VersionValue
        scope = if ($SystemScope) { 'system' } else { 'user' }
        canonicalInstallRoot = $canonicalRoot
        executable = Join-Path $canonicalRoot 'habiter.exe'
        integrationPaths = @($script:IntegrationPaths)
        pathEntry = $script:PathEntry
        pathEntryAddedByInstaller = $script:PathEntryAddedByInstaller
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $canonicalRoot '.habiter-install.json') -Encoding UTF8
}

function Invoke-HabiterInstall {
    Write-Host 'Habiter installer'
    Write-Host ''
    $script:Phase = 'detect-system'
    Write-Step 1 'Detecting system'
    $architecture = if ($env:HABITER_ARCHITECTURE) {
        Get-NormalizedArchitecture $env:HABITER_ARCHITECTURE
    } else {
        Get-DetectedArchitecture ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture)
    }
    Write-Detail "Windows · $architecture"

    $script:Phase = 'resolve-release'
    Write-Step 2 'Resolving release'
    $release = Resolve-HabiterRelease $architecture
    Write-Detail "$Channel · $($release.version) · $($release.artifact.format)"
    $root = if ($InstallDir) { $InstallDir } elseif ($System) { Join-Path $env:ProgramFiles 'Habiter' } else { Join-Path $env:LOCALAPPDATA 'Programs\Habiter' }
    $script:FinalDirectory = $root
    if (-not $DryRun) { Assert-HabiterNotRunning $root }

    if ($DryRun) {
        Write-Step 3 'Dry run'
        Write-Detail "Would download $($release.artifact.fileName) ($($release.artifact.size) bytes)"
        Write-Step 4 'SHA-256 verification'
        Write-Detail "Would verify $($release.artifact.sha256)"
        Write-Step 5 'Installing application'
        Write-Detail "Would install the complete bundle to $root"
    } else {
        $tempRoot = if ($env:HABITER_TEMP_ROOT) { $env:HABITER_TEMP_ROOT } else { [IO.Path]::GetTempPath() }
        $script:Phase = 'prepare-temporary-directory'
        try { New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null } catch { Throw-InstallerError 'HAB-WIN-030' "Cannot create temporary directory: $($_.Exception.Message)" 'Check disk space, TEMP permissions and security software.' 30 }
        $script:TempDirectory = Join-Path $tempRoot ("habiter-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:TempDirectory | Out-Null
        $archive = Join-Path $script:TempDirectory $release.artifact.fileName
        Write-Step 3 'Downloading'
        Write-Detail "$($release.artifact.fileName) ($($release.artifact.size) bytes)"
        $script:Phase = 'download-artifact'
        if ($env:HABITER_ARCHIVE_PATH) {
            try { Copy-Item -LiteralPath $env:HABITER_ARCHIVE_PATH -Destination $archive } catch { Throw-InstallerError 'HAB-WIN-031' "Cannot read test archive: $($_.Exception.Message)" 'Verify the archive path and permissions.' 30 }
        } else {
            try { Invoke-WebRequest -Uri $release.artifact.url -OutFile $archive -MaximumRedirection 5 } catch { Throw-InstallerError 'HAB-WIN-032' "Artifact download failed: $($_.Exception.Message)" 'Check internet, proxy, free disk space and the release URL, then retry.' 30 }
        }
        if ((Get-Item -LiteralPath $archive).Length -ne [long]$release.artifact.size) { Throw-InstallerError 'HAB-WIN-033' 'Downloaded size does not match release metadata.' 'Delete the temporary download and retry; do not install it.' 30 }
        $script:Phase = 'verify-checksum'
        Write-Step 4 'Verifying SHA-256'
        $actual = Assert-HabiterChecksum $archive $release.artifact.sha256
        Write-Detail "OK  $actual"
        $extracted = Join-Path $script:TempDirectory 'extracted'
        $script:Phase = 'extract-archive'
        try { Expand-Archive -LiteralPath $archive -DestinationPath $extracted } catch { Throw-InstallerError 'HAB-WIN-050' "ZIP extraction failed: $($_.Exception.Message)" 'Check free disk space and retry with a fresh download.' 50 }
        $executable = Get-ChildItem -LiteralPath $extracted -Filter habiter.exe -Recurse | Select-Object -First 1
        if (-not $executable) { Throw-InstallerError 'HAB-WIN-051' 'Archive does not contain the complete Habiter Windows bundle.' 'Do not install this archive; report the Install ID.' 50 }
        $bundle = $executable.Directory.FullName
        $parent = Split-Path $root -Parent
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $staged = "$root.new"
        Remove-Item -LiteralPath $staged -Recurse -Force -ErrorAction SilentlyContinue
        $script:Phase = 'stage-installation'
        try { Move-Item -LiteralPath $bundle -Destination $staged } catch { Throw-InstallerError 'HAB-WIN-061' "Cannot stage installation: $($_.Exception.Message)" 'Check destination permissions, free space and antivirus locks.' 60 }
        if (Test-Path -LiteralPath $root) {
            $script:BackupDirectory = "$root.backup"
            Remove-Item -LiteralPath $script:BackupDirectory -Recurse -Force -ErrorAction SilentlyContinue
            try { Move-Item -LiteralPath $root -Destination $script:BackupDirectory } catch { Throw-InstallerError 'HAB-WIN-062' "Cannot replace the current installation: $($_.Exception.Message)" 'Close Habiter and any process using its files, then retry.' 60 }
        }
        try { Move-Item -LiteralPath $staged -Destination $root } catch { Throw-InstallerError 'HAB-WIN-063' "Cannot activate the staged installation: $($_.Exception.Message)" 'Check destination permissions; the installer will attempt rollback.' 60 }
        Write-Step 5 'Installing application'
        Write-Detail $root
        $script:Phase = 'desktop-integration'
        if (-not $NoDesktopIntegration) { try { Install-DesktopIntegration $root } catch { Throw-InstallerError 'HAB-WIN-070' "Desktop integration failed: $($_.Exception.Message)" 'The app may be installed; retry with -NoDesktopIntegration or check Start Menu and PATH permissions.' 70 } }
        $script:Phase = 'ownership-manifest'
        try { Write-OwnershipManifest $root $release.version ([bool]$System) } catch { Throw-InstallerError 'HAB-WIN-071' "Ownership manifest failed: $($_.Exception.Message)" 'The installation was not finalized; check destination permissions.' 70 }
        if ($script:BackupDirectory) { Remove-Item -LiteralPath $script:BackupDirectory -Recurse -Force; $script:BackupDirectory = $null }
    }
    Write-Step 6 'Desktop integration'
    Write-Detail $(if ($NoDesktopIntegration) { 'skipped' } else { 'Start Menu and habiter command enabled' })
    Write-Step 7 'Done'
    Write-Detail "Version: $($release.version)"
    Write-Detail "Destination: $root"
    Write-Detail 'Run: habiter'
}

if ($env:HABITER_TEST_MODE -ne 'functions') {
    try { Invoke-HabiterInstall }
    catch {
        try { Restore-PreviousInstall } catch { [Console]::Error.WriteLine("Rollback warning: $($_.Exception.Message)") }
        $exitCode = Write-InstallerFailure $_
        exit $exitCode
    }
    finally { if ($script:TempDirectory) { Remove-Item -LiteralPath $script:TempDirectory -Recurse -Force -ErrorAction SilentlyContinue } }
}
