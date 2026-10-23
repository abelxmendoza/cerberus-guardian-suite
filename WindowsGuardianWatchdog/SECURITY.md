# Security Policy — WindowsGuardianWatchdog

WindowsGuardianWatchdog is the native Windows Guardian in **CERBERUS — The Guardian Security Suite**.

## Reporting a Vulnerability

Please report security problems privately:

- On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**.
- If that option is not available, open an issue titled `"Security contact request"` **without technical details**, and a private channel will be arranged.

## Verifying Your Download

Compare the SHA-256 hash of the downloaded archive against the checksum published on the CERBERUS download page:

```powershell
Get-FileHash .\WindowsGuardianWatchdog-*.zip -Algorithm SHA256
```

## Privilege & Execution Model

- **Elevation**: `app.manifest` requests `requireAdministrator` so the desktop app can inspect system-wide security posture (Windows Defender, Windows Firewall, UAC, BitLocker, IFEO/Winlogon persistence keys) and manage the optional Windows Service (`InstallService.ps1`).
- **Dry-Run Remediation**: `Core/RemediationEngine.cs` defaults `dryRun` to `true` so changes can be previewed before applying.
- **Reversible Quarantine**: `Core/Quarantine/QuarantineVault.cs` copies, hash-checks, and renames quarantined files so they cannot execute and can be restored safely. Windows system files are refused.
- **Self-Check**: `Core/SelfCheck/AppSelfCheck.cs` verifies the application's own files, permissions, configuration backups, change-watch status, and crash logs.
- **Network Behavior**: `Core/Network/NetworkMonitor.cs` and `Core/Network/ExposureInventory.cs` inspect local connections and listening ports without closing ports or transmitting data externally. `Core/ThreatIntel/ThreatFeedService.cs` ships with an empty feed list by default.
