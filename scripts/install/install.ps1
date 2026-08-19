# Habiter PowerShell installer
param(
    [ValidateSet('stable', 'beta')][string]$Channel = 'stable',
    [ValidatePattern('^$|^\d+\.\d+\.\d+$')][string]$Version = '',
    [string]$InstallDir = '',
    [switch]$DryRun,
    [switch]$VerboseOutput,
    [switch]$System,
    [switch]$NoDesktopIntegration
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$script:TempDirectory = $null
$script:BackupDirectory = $null
$script:FinalDirectory = $null
$ApiBase = if ($env:HABITER_API_BASE) { $env:HABITER_API_BASE } else { 'https://get.habiter.dev' }

function Write-Step([int]$Number, [string]$Message) { Write-Host "[$Number/7] $Message" }
function Write-Detail([string]$Message) { Write-Host "      $Message" }
function Write-DebugDetail([string]$Message) { if ($VerboseOutput) { Write-Detail $Message } }

function Get-NormalizedArchitecture([string]$Value) {
    switch ($Value.ToLowerInvariant()) {
        { $_ -in @('amd64', 'x86_64', 'x64') } { return 'x64' }
        { $_ -in @('arm64', 'aarch64') } { return 'arm64' }
        default { throw "Unsupported architecture: $Value" }
    }
}

function Assert-ResolverResponse($Response) {
    if ($Response.version -notmatch '^\d+\.\d+\.\d+$') { throw 'Resolver returned an invalid version.' }
    if ($Response.platform -ne 'windows' -or $Response.architecture -notin @('x64', 'arm64')) { throw 'Resolver returned an invalid target.' }
    if ($Response.artifact.format -ne 'zip') { throw 'Resolver did not return a Windows ZIP.' }
    if ($Response.artifact.fileName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]+$') { throw 'Resolver returned an invalid file name.' }
    if ($Response.artifact.url -notmatch '^https://') { throw 'Resolver returned a non-HTTPS URL.' }
    if ($Response.artifact.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'Resolver returned an invalid checksum.' }
    if ([long]$Response.artifact.size -lt 1) { throw 'Resolver returned an invalid size.' }
}

function Resolve-HabiterRelease([string]$Architecture) {
    if ($env:HABITER_RESOLVER_JSON) {
        $response = $env:HABITER_RESOLVER_JSON | ConvertFrom-Json
    } else {
        $query = "channel=$Channel"
        if ($Version) { $query += "&version=$Version" }
        $uri = "$ApiBase/api/v1/install/windows/$Architecture`?$query"
        Write-DebugDetail "Resolver: $uri"
        $response = Invoke-RestMethod -Uri $uri -Method Get -MaximumRedirection 0 -Headers @{ Accept = 'application/json' }
    }
    Assert-ResolverResponse $response
    return $response
}

function Assert-HabiterChecksum([string]$Path, [string]$Expected) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected) { throw 'SHA-256 mismatch. Installation aborted.' }
    return $actual
}

function Restore-PreviousInstall {
    if ($script:BackupDirectory -and (Test-Path -LiteralPath $script:BackupDirectory) -and $script:FinalDirectory) {
        Remove-Item -LiteralPath $script:FinalDirectory -Recurse -Force -ErrorAction SilentlyContinue
        Move-Item -LiteralPath $script:BackupDirectory -Destination $script:FinalDirectory
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

    $binDirectory = Join-Path $Root 'bin'
    New-Item -ItemType Directory -Path $binDirectory -Force | Out-Null
    '@echo off' + [Environment]::NewLine + '"%~dp0..\habiter.exe" %*' | Set-Content -LiteralPath (Join-Path $binDirectory 'habiter.cmd') -Encoding Ascii
    if (-not $env:HABITER_SKIP_PATH_UPDATE) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $entries = @($userPath -split ';' | Where-Object { $_ })
        if ($entries -notcontains $binDirectory) {
            [Environment]::SetEnvironmentVariable('Path', (($entries + $binDirectory) -join ';'), 'User')
            Write-Detail "Added command directory to user PATH: $binDirectory"
        }
    }
}

function Invoke-HabiterInstall {
    Write-Host 'Habiter installer'
    Write-Host ''
    Write-Step 1 'Detecting system'
    $architectureSource = if ($env:HABITER_ARCHITECTURE) { $env:HABITER_ARCHITECTURE } else { [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() }
    $architecture = Get-NormalizedArchitecture $architectureSource
    Write-Detail "Windows · $architecture"

    Write-Step 2 'Resolving release'
    $release = Resolve-HabiterRelease $architecture
    Write-Detail "$Channel · $($release.version) · $($release.artifact.format)"
    $root = if ($InstallDir) { $InstallDir } elseif ($System) { Join-Path $env:ProgramFiles 'Habiter' } else { Join-Path $env:LOCALAPPDATA 'Programs\Habiter' }
    $script:FinalDirectory = $root

    if ($DryRun) {
        Write-Step 3 'Dry run'
        Write-Detail "Would download $($release.artifact.fileName) ($($release.artifact.size) bytes)"
        Write-Step 4 'SHA-256 verification'
        Write-Detail "Would verify $($release.artifact.sha256)"
        Write-Step 5 'Installing application'
        Write-Detail "Would install the complete bundle to $root"
    } else {
        $tempRoot = if ($env:HABITER_TEMP_ROOT) { $env:HABITER_TEMP_ROOT } else { [IO.Path]::GetTempPath() }
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $script:TempDirectory = Join-Path $tempRoot ("habiter-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:TempDirectory | Out-Null
        $archive = Join-Path $script:TempDirectory $release.artifact.fileName
        Write-Step 3 'Downloading'
        Write-Detail "$($release.artifact.fileName) ($($release.artifact.size) bytes)"
        if ($env:HABITER_ARCHIVE_PATH) {
            Copy-Item -LiteralPath $env:HABITER_ARCHIVE_PATH -Destination $archive
        } else {
            Invoke-WebRequest -Uri $release.artifact.url -OutFile $archive -MaximumRedirection 5
        }
        Write-Step 4 'Verifying SHA-256'
        $actual = Assert-HabiterChecksum $archive $release.artifact.sha256
        Write-Detail "OK  $actual"
        $extracted = Join-Path $script:TempDirectory 'extracted'
        Expand-Archive -LiteralPath $archive -DestinationPath $extracted
        $executable = Get-ChildItem -LiteralPath $extracted -Filter habiter.exe -Recurse | Select-Object -First 1
        if (-not $executable) { throw 'Archive does not contain the complete Habiter Windows bundle.' }
        $bundle = $executable.Directory.FullName
        $parent = Split-Path $root -Parent
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $staged = "$root.new"
        Remove-Item -LiteralPath $staged -Recurse -Force -ErrorAction SilentlyContinue
        Move-Item -LiteralPath $bundle -Destination $staged
        if (Test-Path -LiteralPath $root) {
            $script:BackupDirectory = "$root.backup"
            Remove-Item -LiteralPath $script:BackupDirectory -Recurse -Force -ErrorAction SilentlyContinue
            Move-Item -LiteralPath $root -Destination $script:BackupDirectory
        }
        Move-Item -LiteralPath $staged -Destination $root
        Write-Step 5 'Installing application'
        Write-Detail $root
        if (-not $NoDesktopIntegration) { Install-DesktopIntegration $root }
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
    catch { Restore-PreviousInstall; Write-Error $_; exit 1 }
    finally { if ($script:TempDirectory) { Remove-Item -LiteralPath $script:TempDirectory -Recurse -Force -ErrorAction SilentlyContinue } }
}
