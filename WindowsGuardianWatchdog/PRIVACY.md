# Privacy Policy — WindowsGuardianWatchdog

**Last Updated**: October 2026

WindowsGuardianWatchdog is designed with a local-only, privacy-first architecture as part of **CERBERUS — The Guardian Security Suite**.

## Data Collection & Storage

- **Where Data Lives**: All baselines, notices, reports, configuration files, and crash logs stay on your PC under `%LocalAppData%\WindowsGuardianWatchdog\` and `%ProgramData%\WindowsGuardianWatchdog\`.
- **What Is Inspected Locally**:
  - Running processes (names, PIDs, resource usage, digital signatures)
  - Network connections and listening TCP/UDP ports (`NetworkMonitor.cs`, `ExposureInventory.cs` — metadata only, no packet capture)
  - File integrity SHA-256 hashes (`FileIntegrityMonitor.cs`)
  - Security settings and persistence tripwires (`SecurityAudit.cs`, `ChangeWatch.cs`)
- **What Is Never Collected or Transmitted**:
  - No telemetry, analytics, or crash reports are uploaded anywhere.
  - `ThreatFeedService.cs` ships with an empty feed URL list by default and makes no outbound connections unless configured by the operator.
  - Quarantined files remain locally in the reversible quarantine vault (`QuarantineVault.cs`) until restored or deleted by the operator.
