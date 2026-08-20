$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$installer = Join-Path $root 'scripts\install\install.ps1'
$env:HABITER_TEST_MODE = 'functions'
. $installer

if ((Get-NormalizedArchitecture 'AMD64') -ne 'x64') { throw 'AMD64 normalization failed' }
if ((Get-NormalizedArchitecture 'aarch64') -ne 'arm64') { throw 'ARM64 normalization failed' }
try { Get-NormalizedArchitecture 'sparc'; throw 'Unsupported architecture accepted' } catch { if ($_.Exception.Message -eq 'Unsupported architecture accepted') { throw } }
try { Get-NormalizedArchitecture $null; throw 'Missing architecture accepted' } catch { if ($_.Exception.Message -eq 'Missing architecture accepted') { throw } }
try { Get-NormalizedArchitecture 'sparc' } catch { if ($_.Exception.Data['InstallerCode'] -ne 'HAB-WIN-011') { throw 'Missing architecture error code' } }
$savedProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
if ((Get-DetectedArchitecture $null) -ne 'x64') { throw 'Environment architecture fallback failed' }
$env:PROCESSOR_ARCHITECTURE = $savedProcessorArchitecture

$valid = [pscustomobject]@{
    version = '1.6.0'; platform = 'windows'; architecture = 'x64'
    artifact = [pscustomobject]@{ format = 'zip'; fileName = 'habiter.zip'; url = 'https://example.com/habiter.zip'; sha256 = ('a' * 64); size = 42 }
}
Assert-ResolverResponse $valid
$invalid = $valid | ConvertTo-Json -Depth 4 | ConvertFrom-Json
$invalid.artifact.url = 'http://example.com/habiter.zip'
try { Assert-ResolverResponse $invalid; throw 'Insecure URL accepted' } catch {
    if ($_.Exception.Message -eq 'Insecure URL accepted') { throw }
    if ($_.Exception.Data['InstallerCode'] -ne 'HAB-WIN-026') { throw 'Missing insecure URL error code' }
}

$dryRoot = Join-Path ([IO.Path]::GetTempPath()) ("habiter-dry-run-" + [guid]::NewGuid().ToString('N'))
$env:HABITER_TEST_MODE = ''
$env:HABITER_ARCHITECTURE = 'AMD64'
$env:HABITER_RESOLVER_JSON = $valid | ConvertTo-Json -Depth 4 -Compress
$hostExecutable = (Get-Process -Id $PID).Path
& $hostExecutable -NoProfile -File $installer -DryRun -InstallDir $dryRoot | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Dry run failed' }
if (Test-Path -LiteralPath $dryRoot) { throw 'Dry run mutated the install directory' }

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("habiter-installer-test-" + [guid]::NewGuid().ToString('N'))
$source = Join-Path $testRoot 'source'
$tempRoot = Join-Path $testRoot 'temp'
$archive = Join-Path $testRoot 'habiter.zip'
$installRoot = Join-Path $testRoot 'installed'
New-Item -ItemType Directory -Path (Join-Path $source 'data') -Force | Out-Null
'test executable' | Set-Content -LiteralPath (Join-Path $source 'habiter.exe') -Encoding Ascii
'test dll' | Set-Content -LiteralPath (Join-Path $source 'flutter_windows.dll') -Encoding Ascii
Compress-Archive -Path (Join-Path $source '*') -DestinationPath $archive
$valid.artifact.sha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
$valid.artifact.size = (Get-Item -LiteralPath $archive).Length
$env:HABITER_RESOLVER_JSON = $valid | ConvertTo-Json -Depth 4 -Compress
$env:HABITER_ARCHIVE_PATH = $archive
$env:HABITER_TEMP_ROOT = $tempRoot

& $hostExecutable -NoProfile -File $installer -InstallDir $installRoot -NoDesktopIntegration | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $installRoot 'habiter.exe'))) { throw 'Real test install failed' }
'old' | Set-Content -LiteralPath (Join-Path $installRoot 'old.txt')
& $hostExecutable -NoProfile -File $installer -InstallDir $installRoot -NoDesktopIntegration | Out-Null
if ($LASTEXITCODE -ne 0 -or (Test-Path (Join-Path $installRoot 'old.txt'))) { throw 'Repeated install did not replace cleanly' }

$startMenu = Join-Path $testRoot 'start-menu'
$env:HABITER_START_MENU_DIR = $startMenu
$env:HABITER_SKIP_PATH_UPDATE = '1'
& $hostExecutable -NoProfile -File $installer -InstallDir $installRoot | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $startMenu 'Habiter.lnk'))) { throw 'Start Menu integration failed' }
if (-not (Test-Path (Join-Path $installRoot 'bin\habiter.cmd'))) { throw 'Command integration failed' }

$badRoot = Join-Path $testRoot 'bad-install'
$valid.artifact.sha256 = 'b' * 64
$env:HABITER_RESOLVER_JSON = $valid | ConvertTo-Json -Depth 4 -Compress
$previousErrorAction = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $hostExecutable -NoProfile -File $installer -InstallDir $badRoot -NoDesktopIntegration 2>$null | Out-Null
$badExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorAction
if ($badExitCode -eq 0 -or (Test-Path $badRoot)) { throw 'Checksum mismatch did not fail closed' }
if ((Get-ChildItem -LiteralPath $tempRoot -Force | Measure-Object).Count -ne 0) { throw 'Temporary files were not cleaned' }

Remove-Item -LiteralPath $testRoot -Recurse -Force
Remove-Item Env:HABITER_TEST_MODE, Env:HABITER_ARCHITECTURE, Env:HABITER_RESOLVER_JSON, Env:HABITER_ARCHIVE_PATH, Env:HABITER_TEMP_ROOT, Env:HABITER_START_MENU_DIR, Env:HABITER_SKIP_PATH_UPDATE -ErrorAction SilentlyContinue
Write-Host 'install.ps1 tests passed'
