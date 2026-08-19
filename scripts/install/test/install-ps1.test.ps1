$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$installer = Join-Path $root 'scripts\install\install.ps1'
$env:HABITER_TEST_MODE = 'functions'
. $installer

if ((Get-NormalizedArchitecture 'AMD64') -ne 'x64') { throw 'AMD64 normalization failed' }
if ((Get-NormalizedArchitecture 'aarch64') -ne 'arm64') { throw 'ARM64 normalization failed' }
try { Get-NormalizedArchitecture 'sparc'; throw 'Unsupported architecture accepted' } catch { if ($_.Exception.Message -eq 'Unsupported architecture accepted') { throw } }

$valid = [pscustomobject]@{
    version = '1.6.0'; platform = 'windows'; architecture = 'x64'
    artifact = [pscustomobject]@{ format = 'zip'; fileName = 'habiter.zip'; url = 'https://example.com/habiter.zip'; sha256 = ('a' * 64); size = 42 }
}
Assert-ResolverResponse $valid
$invalid = $valid | ConvertTo-Json -Depth 4 | ConvertFrom-Json
$invalid.artifact.url = 'http://example.com/habiter.zip'
try { Assert-ResolverResponse $invalid; throw 'Insecure URL accepted' } catch { if ($_.Exception.Message -eq 'Insecure URL accepted') { throw } }

$dryRoot = Join-Path ([IO.Path]::GetTempPath()) ("habiter-dry-run-" + [guid]::NewGuid().ToString('N'))
$env:HABITER_TEST_MODE = ''
$env:HABITER_ARCHITECTURE = 'AMD64'
$env:HABITER_RESOLVER_JSON = $valid | ConvertTo-Json -Depth 4 -Compress
$hostExecutable = (Get-Process -Id $PID).Path
& $hostExecutable -NoProfile -File $installer -DryRun -InstallDir $dryRoot | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Dry run failed' }
if (Test-Path -LiteralPath $dryRoot) { throw 'Dry run mutated the install directory' }
Remove-Item Env:HABITER_TEST_MODE, Env:HABITER_ARCHITECTURE, Env:HABITER_RESOLVER_JSON -ErrorAction SilentlyContinue
Write-Host 'install.ps1 tests passed'
