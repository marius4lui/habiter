# Install Habiter on Windows

## Support status

The release workflow builds and installer CI tests Windows x64 on `windows-latest`. The payload is the complete Flutter Windows ZIP, not a standalone `habiter.exe`. Windows ARM64 is not published. Desktop ZIPs have release SHA-256 metadata; Authenticode signing is not claimed until a release artifact explicitly reports it as signed.

## Recommended installation

Open PowerShell as your normal user:

```powershell
irm https://get.habiter.dev/install.ps1 | iex
```

The installer prints architecture, channel/version, artifact, byte size, checksum, destination, Start Menu entry, and command integration. It downloads to a unique temporary directory, verifies SHA-256, extracts the complete bundle, and stages replacement under:

```text
%LOCALAPPDATA%\Programs\Habiter
```

Preview without downloading or changing files:

```powershell
& ([scriptblock]::Create((irm https://get.habiter.dev/install.ps1))) -DryRun -VerboseOutput
```

Do not globally weaken PowerShell execution policy. If organizational policy blocks in-memory scripts, use the manual verified ZIP method or ask the administrator responsible for that policy.

## What changes

- installs the full application bundle in `%LOCALAPPDATA%\Programs\Habiter`;
- creates `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Habiter.lnk`;
- creates `bin\habiter.cmd` inside the install directory;
- appends that exact `bin` directory to the current user's PATH only when absent.

No machine-wide path or administrator permission is required by default. `-System` is explicit and does not bypass access control.

## Manual ZIP installation and SHA-256

```powershell
$meta = Invoke-RestMethod 'https://get.habiter.dev/api/v1/install/windows/x64?channel=stable'
if ($meta.artifact.url -notlike 'https://*') { throw 'Non-HTTPS artifact URL' }
$zip = Join-Path $env:TEMP $meta.artifact.fileName
Invoke-WebRequest $meta.artifact.url -OutFile $zip
$actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $meta.artifact.sha256) { throw 'SHA-256 mismatch' }
Expand-Archive $zip -DestinationPath "$env:LOCALAPPDATA\Programs\Habiter.manual"
```

Confirm the extracted directory contains `habiter.exe`, DLLs, and `data`; do not copy only the executable. Replace an existing install only after the check succeeds and Habiter is closed.

## Update

Rerun the recommended installer. It verifies and stages the new bundle before moving the previous install aside, and restores the previous directory if replacement fails. A repeated installation of the same release is safe.

## Uninstall

Close Habiter, then remove installer-owned files and the exact user PATH entry:

```powershell
$root = Join-Path $env:LOCALAPPDATA 'Programs\Habiter'
$bin = Join-Path $root 'bin'
$path = [Environment]::GetEnvironmentVariable('Path', 'User')
$clean = (($path -split ';' | Where-Object { $_ -and $_ -ne $bin }) -join ';')
[Environment]::SetEnvironmentVariable('Path', $clean, 'User')
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Habiter.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item $root -Recurse -Force
```

This does not remove local Habiter data. Review/export it separately.

## SmartScreen and signing

Current unsigned desktop releases may show a reputation warning. Verify that the file URL came from the resolver and that SHA-256 matches before deciding whether to run it. Use the Windows Security/SmartScreen details UI available under your policy; do not disable SmartScreen globally. When signing is introduced, the installer contract will add Authenticode verification in addition to SHA-256.

## Download, extraction, and runtime errors

```powershell
$PSVersionTable
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsArchitecture
Get-AuthenticodeSignature "$env:LOCALAPPDATA\Programs\Habiter\habiter.exe"
Get-ChildItem "$env:LOCALAPPDATA\Programs\Habiter" | Select-Object Name, Length
```

TLS/proxy failures should be fixed in the managed network rather than bypassing certificate checks. If `habiter.exe` reports a missing runtime DLL, confirm the full ZIP was extracted and capture the exact DLL/error; do not download DLLs from third-party sites.

## Safe diagnostics

Include Habiter version, Windows version/architecture, PowerShell version, reviewed installer `-VerboseOutput`, exact error text, resolver status, and the installed executable's Authenticode status. Never post tokens, habits, browser history, unrelated environment variables, or the contents of secure storage.
