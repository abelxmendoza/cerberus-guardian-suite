# Privacy Policy — CERBERUS Guardian Security Suite

**Last Updated**: October 2026

CERBERUS (`CerberusGuardian-SecuritySuite`) and its three platform Guardians (`MacGuardianWatchdog`, `LinuxGuardianWatchdog`, and `WindowsGuardianWatchdog`) are built on a strict **local-first, zero-telemetry** design.

## Core Privacy Commitments

1. **No Telemetry or Analytics**: Neither the CERBERUS web portal nor any of the three desktop Guardians includes analytics trackers, usage telemetry, or background data uploads.
2. **Local Data Storage Only**:
   - **macOS (`MacGuardianWatchdog`)**: `~/.macguardian/` and `~/Library/Application Support/MacGuardian/`
   - **Linux (`LinuxGuardianWatchdog`)**: `~/.linuxguardian/`
   - **Windows (`WindowsGuardianWatchdog`)**: `%LocalAppData%\WindowsGuardianWatchdog\` and `%ProgramData%\WindowsGuardianWatchdog\`
3. **Metadata-Only Inspection**:
   - File integrity monitoring computes and compares SHA-256 hashes and metadata, not document contents.
   - Network monitoring inspects socket/connection metadata (addresses, ports, protocols, owning PIDs), never packet payloads.
4. **Opt-In External Requests Only**:
   - Threat intelligence feed updates (e.g., abuse.ch) run only when explicitly triggered or configured by the operator.
   - Email reports (macOS/Windows) are sent only when the operator configures their own SMTP server and recipient address.
   - Linux optional AI explanations (`ai_investigator.py`) are disabled by default; when enabled, operators can choose local Ollama (100% offline) or opt-in cloud analysis with automatic redaction (`ai_safety.py`).

## Platform-Specific Privacy Policies

- [macOS Privacy Policy](MacGuardianWatchdog/PRIVACY.md)
- [Linux Privacy Policy](LinuxGuardianWatchdog/PRIVACY.md)
- [Windows Privacy Policy](WindowsGuardianWatchdog/PRIVACY.md)
