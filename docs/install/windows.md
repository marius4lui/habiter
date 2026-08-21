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

Add `-Diagnostics` after a failure to print a safe support summary containing the failing phase, PowerShell/Windows architecture, selected channel and destination. It does not dump environment variables, tokens, habit data, browser history or secure storage. Every failure includes a stable `HAB-WIN-NNN` code and a short Install ID that can be included in a support report.

Common code families are: `HAB-WIN-01x` platform detection, `02x` resolver or unsafe metadata, `03x` temporary storage/download, `04x` checksum, `05x` archive validation, `06x` process locks or replacement, `07x` desktop integration and `999` unexpected failures. The installer prints a concrete recovery action with each code. Never bypass HTTPS or checksum validation to work around an error.

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

## Uninstall safely

Download the maintained script, inspect it, and preview the complete plan:

```powershell
$script = Join-Path $env:TEMP 'habiter-uninstall.ps1'
Invoke-WebRequest https://get.habiter.dev/uninstall.ps1 -OutFile $script
Get-Content $script
powershell.exe -NoProfile -File $script -DryRun -VerboseOutput
```

If the candidate, canonical root, version, ownership evidence, Start Menu shortcut, and PATH entry are correct, run the same downloaded file without `-DryRun`. Interactive removal first asks `Continue with this exact removal plan? [y/N]`, then requires the printed `UNINSTALL HABITER <canonical-path>` challenge. Blank input, EOF, redirected input, a mismatch, or a running `habiter.exe` stops before mutation; the script never kills the process or bypasses permissions.

Use `-System` for `%ProgramFiles%\Habiter`, or `-InstallDir 'C:\exact\custom\Habiter'` for one explicit custom installation. Zero candidates exit unchanged. Multiple candidates or conflicting ownership signals abort until one exact `-InstallDir` is selected. A malformed, unsupported, redirected, or path-escaping manifest is rejected. Legacy installs require the expected executable, matching Start Menu shortcut, and matching `bin\habiter.cmd`, and are marked with an extra warning.

Automation is deliberately target-bound: provide both `-InstallDir` and `-ConfirmTarget 'UNINSTALL HABITER C:\exact\canonical\path'`. A generic `-Force` is unsupported and cannot authorize an auto-discovered target.

The uninstaller stages the verified application and owned shortcut beside their original locations, restores them and the original user PATH when staging/finalization fails where recovery is still possible, and never overwrites an existing quarantine. Its error includes a stable `HAB-UNWIN-NNN` code, phase, recovery instruction, and Uninstall ID.

Normal uninstall preserves databases, preferences, reminders, credentials, backups, exports, clipboard history, and operating-system backups. Export a backup before making a separate data-removal decision; this first version exposes no data-deletion flag.

### Manual fallback after script failure

Use a manual fallback only after the script has identified the exact blocker. Inspect `.habiter-install.json`, resolve the root with `[IO.Path]::GetFullPath`, reject drive/profile/`Program Files`/`%LOCALAPPDATA%\Programs` roots and every reparse point, verify that `executable` is exactly `<root>\habiter.exe`, inspect the `.lnk` target through `WScript.Shell`, and compare the exact normalized `bin` component in the user PATH. Preserve any mismatch.

After those checks, rename each verified literal target to a unique adjacent quarantine first. Delete the quarantine only after every rename succeeds; never use a wildcard or an unresolved variable. Do not remove parent directories, unrelated PATH entries, or application data. If any check is unclear, reinstall Habiter to recreate the manifest and rerun the maintained uninstaller instead of guessing.

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
