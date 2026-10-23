# Security Policy — CERBERUS Guardian Security Suite

CERBERUS (`CerberusGuardian-SecuritySuite`) is an open-source, cross-platform security monitoring and system hardening suite comprising three native desktop Guardians:

- **MacGuardianWatchdog** (`MacGuardianWatchdog/`) — macOS 14+ (SwiftUI) / macOS 12+ (CLI)
- **LinuxGuardianWatchdog** (`LinuxGuardianWatchdog/`) — Ubuntu 22.04 GNOME/X11 (GTK4 + libadwaita + Python/Bash)
- **WindowsGuardianWatchdog** (`WindowsGuardianWatchdog/`) — Windows 10/11 (WinUI 3 / .NET 8)

## Reporting a Vulnerability

Please report security issues privately, not in a public issue:

1. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**.
2. If private vulnerability reporting is not enabled on the repository you are viewing, open an issue titled `"Security contact request"` **without any sensitive details**, and a private channel will be arranged.

Include the affected Guardian (`WindowsGuardianWatchdog`, `LinuxGuardianWatchdog`, `MacGuardianWatchdog`, or the web portal), steps to reproduce, and impact.

## Verifying Downloads

Every source archive linked from the CERBERUS portal lists a pinned 40-character git commit and its exact SHA-256 checksum. Verify the archive before extracting or building:

### Linux and macOS

```bash
shasum -a 256 asset.zip
```

### Windows (PowerShell)

```powershell
Get-FileHash .\asset.zip -Algorithm SHA256
```

## Core Security Principles Across All 3 Guardians

1. **Preview / Dry-Run First**: Remediation and system-modifying actions default to dry-run or preview mode and require explicit operator confirmation.
2. **Reversible Quarantine**: Flagged files are moved to a local quarantine vault with SHA-256 verification and restore manifests rather than immediately deleted.
3. **Self-Check**: Each Guardian includes a self-check module (`MacGuardianSuite/self_check.sh`, `LinuxGuardianSuite/self_check.py`, `Core/SelfCheck/AppSelfCheck.cs`) to verify its own files, permissions, and state.
4. **Local-First Operation**: All monitoring, baselines, and posture audits execute locally on the host machine.

## Platform-Specific Security Policies

- [macOS Security Policy](MacGuardianWatchdog/SECURITY.md)
- [Linux Security Policy](LinuxGuardianWatchdog/SECURITY.md)
- [Windows Security Policy](WindowsGuardianWatchdog/SECURITY.md)
