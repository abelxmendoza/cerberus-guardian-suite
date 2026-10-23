# CERBERUS (`CerberusGuardian-SecuritySuite`)

**The Guardian Security Suite.** Three platforms. One guardian.

Built by an engineer, for people who value privacy, security, and control.

CERBERUS (`CerberusGuardian-SecuritySuite`) is the unified open-source security monitoring and system hardening monorepo for **Windows**, **Linux**, and **macOS**. It brings together all three native desktop Guardians, their shared cross-platform schemas (`shared/`), and the public web portal ([cerberus-guardian-suite.vercel.app](https://cerberus-guardian-suite.vercel.app)) in a single repository.

CERBERUS does not replace antivirus or endpoint protection. It watches, explains, and — where a Guardian supports it — previews a change before anything on the machine is modified.

| Guardian | Local Path | Standalone Repository | Stack | Status |
| --- | --- | --- | --- | --- |
| **[MacGuardianWatchdog](MacGuardianWatchdog/README.md)** | `MacGuardianWatchdog/` | [github.com/abelxmendoza/MacGuardianWatchdog](https://github.com/abelxmendoza/MacGuardianWatchdog) | SwiftUI app + Bash & Python | Active development |
| **[LinuxGuardianWatchdog](LinuxGuardianWatchdog/README.md)** | `LinuxGuardianWatchdog/` | [github.com/abelxmendoza/LinuxGuardianWatchdog](https://github.com/abelxmendoza/LinuxGuardianWatchdog) | GTK4 / libadwaita + Python & Bash | Active development |
| **[WindowsGuardianWatchdog](WindowsGuardianWatchdog/README.md)** | `WindowsGuardianWatchdog/` | [github.com/abelxmendoza/WindowsGuardianWatchdog](https://github.com/abelxmendoza/WindowsGuardianWatchdog) | WinUI 3 / .NET 8 (C#) | Active development (Least ready) |

---

## Unified Monorepo Layout

```text
CerberusGuardian-SecuritySuite/
├── MacGuardianWatchdog/          # Native macOS Guardian (SwiftUI + Bash/Python)
│   ├── MacGuardianSuite/         # Core macOS security scripts, FIM, Blue Team, Self-Check
│   ├── MacGuardianSuiteUI/       # Native macOS SwiftUI application
│   ├── install.sh                # One-step macOS builder & installer (no sudo)
│   └── uninstall.sh              # Clean uninstaller
├── LinuxGuardianWatchdog/        # Native Linux Guardian (GTK4/libadwaita + Python/Bash)
│   ├── LinuxGuardianSuite/       # 40+ read-only sensors, FIM, quarantine, polkit helpers
│   ├── LinuxGuardianSuiteUI/     # Native GTK4 / libadwaita desktop UI & 1398+ pytest suite
│   └── tests/                    # Shell test suites for privileged scripts
├── WindowsGuardianWatchdog/      # Native Windows Guardian (WinUI 3 / .NET 8)
│   ├── Core/                     # FIM, BlueTeam, ChangeWatch, QuarantineVault, Exposure, SelfCheck
│   ├── Services/                 # Windows Service, ReportGenerator, ScheduledReportService
│   └── Views/                    # 19 WinUI 3 views with Omega Dark theme
├── shared/                       # Unified cross-platform schemas & design system (synced to all 3)
│   ├── schemas/                  # event_spec_v1.json, report_schema.json, config_schema.json
│   ├── ml/                       # feature_vector.schema.json
│   ├── compliance/               # hipaa.json, gdpr.json, pci_dss.json
│   └── design/                   # omega_design_system.json
├── src/                          # CERBERUS web portal (React, TypeScript, Tailwind, Vite)
├── e2e/                          # Playwright end-to-end verification tests
├── cerberus.sh                   # Unified CLI launcher & cross-platform verification script
├── LICENSE                       # MIT License (unified across root and all 3 Guardians)
├── SECURITY.md                   # Unified security policy & checksum verification guide
└── PRIVACY.md                    # Unified local-first, zero-telemetry privacy policy
```

---

## Quick Verification & Unified CLI (`cerberus.sh`)

From the monorepo root on macOS, Linux, or WSL:

```bash
./cerberus.sh --verify   # Verify all 3 Guardians, shared JSON schemas, and governance files
./cerberus.sh --status   # Show platform detection and status of all 3 Guardians
./cerberus.sh --launch   # Launch the native Guardian for the current OS
./cerberus.sh --web      # Start the CERBERUS web portal dev server
```

---

## Get the Desktop Apps (Pinned Source Archives)

All three Guardians can also be downloaded directly from the landing page or from their standalone GitHub repositories as pinned commit archives:

| Platform | Download | SHA-256 |
| --- | --- | --- |
| **Linux** | [LinuxGuardianWatchdog archive `b923c19`](https://github.com/abelxmendoza/LinuxGuardianWatchdog/archive/b923c198aa37eb6d0712c61b49f67862729ae289.zip) | `3dabde32802a4b466f1254e43a4f7a6d5e616ed564045e0b9730b50957819f2d` |
| **macOS** | [MacGuardianWatchdog archive `fed9b33`](https://github.com/abelxmendoza/MacGuardianWatchdog/archive/fed9b33dc85fb6ec50b3e51ae906f0819a2374e0.zip) | `386d037db3a1e0e24024462465aeebec52c8e75b2ba9f515283bf1c798f2afa6` |
| **Windows** | [WindowsGuardianWatchdog archive `7b3f424`](https://github.com/abelxmendoza/WindowsGuardianWatchdog/archive/7b3f424ab921c03b63142185e709fcdb9fd3ba39.zip) | `b40ce993c60eefed7864149b4df597e497a798f41b5ce8781b8634c9f6309c66` |

Hashes were computed from those exact zip files on 22 October 2026.

### 1. Linux (`LinuxGuardianWatchdog/`)

Verified target: Ubuntu 22.04 with GNOME on X11.

```bash
cd LinuxGuardianWatchdog/LinuxGuardianSuiteUI
./run_ui.sh
```

Covers: scored posture audit, ClamAV and rkhunter scans, SHA-256 file integrity, 12 live read-only sensors (logins, processes, network, startup entries, accounts, USB, tripwires, decoys, defenses, setuid watch), incidents with a timeline, reversible quarantine, hardening checklist, exposure checks, ROS 2 firewall helper, self-check, and optional opt-in AI explanations (local Ollama or Claude, off by default). Local data stays in `~/.linuxguardian/`. See [`LinuxGuardianWatchdog/README.md`](LinuxGuardianWatchdog/README.md).

### 2. macOS (`MacGuardianWatchdog/`)

Requires macOS 14+ and full Xcode for the SwiftUI app (shell tools run on macOS 12+).

```bash
cd MacGuardianWatchdog
# Double-click Install MacGuardian.command, or:
bash install.sh
```

Covers: ClamAV and rkhunter scanning, SHA-256 file integrity, blue-team view of processes and network connections, threat-intelligence matching, scored security audit (FileVault, SIP, Gatekeeper, firewall), reversible quarantine, cache cleaning, process control, Homebrew and app updates, self-check, and local HTML reports. Scan data stays in `~/.macguardian/`. Remove with `bash uninstall.sh`. See [`MacGuardianWatchdog/README.md`](MacGuardianWatchdog/README.md).

### 3. Windows (`WindowsGuardianWatchdog/`)

Requires Windows 10 (build 19041+) or Windows 11 and the .NET 8 SDK.

```powershell
cd WindowsGuardianWatchdog
dotnet build -c Release
```

Covers: real-time process and network monitoring, SHA-256 file integrity, blue-team detection, scored security audit, dry-run remediation, plus capabilities ported from Mac and Linux in commit `7b3f424`: notices and change watch (`Core/Sensors/ChangeWatch.cs`, `Core/Incidents/EventTimeline.cs`), reversible quarantine (`Core/Quarantine/QuarantineVault.cs`), network exposure inventory (`Core/Network/ExposureInventory.cs`), app self-check (`Core/SelfCheck/AppSelfCheck.cs`), reports (`Views/ReportsView.xaml`), and app/Windows updates. See [`WindowsGuardianWatchdog/README.md`](WindowsGuardianWatchdog/README.md).

---

## How the Three Guardians Line Up

Each Guardian keeps the same mission: look at the machine, score the posture, watch for change, and let the operator decide before a fix is applied.

| Aspect | macOS (`MacGuardianWatchdog`) | Linux (`LinuxGuardianWatchdog`) | Windows (`WindowsGuardianWatchdog`) |
| --- | --- | --- | --- |
| **Interface** | SwiftUI | GTK4 and libadwaita | WinUI 3 |
| **Work behind the UI** | Shell and Python | Shell and Python | C# (.NET 8) |
| **Scheduling** | `launchd` | `systemd` user timers | Windows Service & Task Scheduler |
| **File integrity** | SHA-256 baseline | SHA-256 baseline | SHA-256 baseline |
| **Change watch & timeline** | `event_timeline.py` | `sensors.py`, `defenses.py`, `tripwires.py`, `timeline.py` | `ChangeWatch.cs`, `EventTimeline.cs` |
| **Reversible quarantine** | `quarantine_manager.sh` | `quarantine.py` | `QuarantineVault.cs` |
| **Network exposure** | `mac_blueteam.sh` | `exposure_inventory.py` | `ExposureInventory.cs` |
| **Self-check** | `self_check.sh` | `self_check.py` | `AppSelfCheck.cs` |
| **Shared schemas** | `shared/` | `shared/` | `shared/` |
| **Local data** | `~/.macguardian/` & Application Support | `~/.linuxguardian/` | `%LocalAppData%\WindowsGuardianWatchdog` |
| **Governance** | [`LICENSE`](MacGuardianWatchdog/LICENSE), [`SECURITY.md`](MacGuardianWatchdog/SECURITY.md), [`PRIVACY.md`](MacGuardianWatchdog/PRIVACY.md) | [`LICENSE`](LinuxGuardianWatchdog/LICENSE), [`SECURITY.md`](LinuxGuardianWatchdog/SECURITY.md), [`PRIVACY.md`](LinuxGuardianWatchdog/PRIVACY.md) | [`LICENSE`](WindowsGuardianWatchdog/LICENSE), [`SECURITY.md`](WindowsGuardianWatchdog/SECURITY.md), [`PRIVACY.md`](WindowsGuardianWatchdog/PRIVACY.md) |

---

## CERBERUS Web Portal

The root web portal is a static React application (Vite, TypeScript, Tailwind).

```bash
npm install
npm run dev
```

Checks:

```bash
npm run typecheck
npm run lint
npm test
npm run build
npm run test:e2e
```

To build for the portfolio path (`https://www.abelxmendoza.com/projects/cerberus`):

```bash
VITE_BASE=/projects/cerberus/ npm run build
```

## Author

Abel Mendoza. Computer Science, California State University, Fullerton.

- [abelxmendoza.com](https://www.abelxmendoza.com)
- [github.com/abelxmendoza](https://github.com/abelxmendoza)
- [LinkedIn](https://www.linkedin.com/in/abelxmendoza/)
