import type { Guardian } from "./types";
import { releases } from "./releases";

export const evidenceDate = "22 October 2026";

export const guardians: Guardian[] = [
  {
    id: "windows",
    name: "WindowsGuardianWatchdog",
    platform: "Microsoft Windows",
    themeColor: "#00BFFF",
    description:
      "In active development, and the least ready Guardian. A WinUI 3 / .NET 8 app for Windows with ported change watch, reversible quarantine, exposure inventory, self-check, and reports.",
    repositoryUrl: "https://github.com/abelxmendoza/WindowsGuardianWatchdog",
    release: releases.windows,
    supportedVersions: [
      "Windows 11, or Windows 10 version 2004 (build 19041) or later",
      "Project target: net8.0-windows10.0.19041.0, platform win-x64",
    ],
    verifiedFeatures: [
      "Process and security-status monitoring (Core/SecurityMonitor.cs)",
      "File integrity monitoring (Core/FileIntegrityMonitor.cs)",
      "Notices and change watch for defenses and persistence keys (Core/Sensors/ChangeWatch.cs, Core/Incidents/EventTimeline.cs)",
      "Reversible quarantine vault with SHA-256 verification (Core/Quarantine/QuarantineVault.cs)",
      "Network exposure inventory of listening TCP/UDP ports (Core/Network/ExposureInventory.cs)",
      "App self-check and reports (Core/SelfCheck/AppSelfCheck.cs, Views/ReportsView.xaml)",
      "Security audit, hardening, and dry-run remediation (Core/SecurityAudit.cs, Core/Hardening/, Core/RemediationEngine.cs)",
    ],
    permissions: [
      "app.manifest requests requireAdministrator. The process is designed to run elevated.",
      "A Windows service installer is included (InstallService.ps1) and also expects an administrator.",
    ],
    networkBehavior: [
      "NetworkMonitor.cs and ExposureInventory.cs monitor local connections and listening ports on the machine.",
      "ThreatFeedService.cs can request a feed URL, but the list shipped in the repository is empty. No default feed host is configured.",
      "Local data stays under %LocalAppData%\\WindowsGuardianWatchdog and %ProgramData%\\WindowsGuardianWatchdog.",
    ],
    install: [
      "Click Download for Windows. The zip saves to your downloads folder.",
      "Unzip it. The folder name starts with WindowsGuardianWatchdog-.",
      "You need Windows 10 (build 19041+) or Windows 11, and the .NET 8 SDK.",
      "In that folder run dotnet build -c Release, then start the app from bin/Release/net8.0-windows10.0.19041.0/.",
      "The app asks for administrator approval. This zip is the project, not a signed MSIX.",
    ],
    uninstall: [
      "There is no signed installer, so there is no packaged uninstaller.",
      "If the optional service was installed, InstallService.ps1 -Uninstall removes that service. Run it from an elevated PowerShell session.",
      "Delete the unzipped folder and its build output.",
    ],
    limitations: [
      "Least ready of the three Guardians, and still in active development.",
      "The download is the project archive. DISTRIBUTION.md says the public installer is a signed MSIX, and that file is not published.",
      "Unified LICENSE, SECURITY.md, and PRIVACY.md are included in the CerberusGuardian-SecuritySuite monorepo.",
      "No automated test project was found in the standalone Windows repo. GitHub Actions builds the desktop app and runs CodeQL.",
      "Optional MSIX signing exists as a local script when the operator supplies a certificate. Public signed release assets were not found.",
    ],
    docs: [
      {
        label: "README",
        href: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/blob/main/README.md",
      },
      {
        label: "Alignment roadmap",
        href: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/blob/main/ALIGNMENT_ROADMAP.md",
      },
      {
        label: "Distribution notes",
        href: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/blob/main/DISTRIBUTION.md",
      },
      {
        label: "Windows app standards",
        href: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/blob/main/WINDOWS_APP_STANDARDS.md",
      },
    ],
    ciNote:
      "On 22 October 2026 commit 7b3f424 unified the Mac and Linux capabilities (change watch, quarantine, exposure, self-check, reports, and app updates) into WindowsGuardianWatchdog.",
    ciUrl: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/actions",
    license: "MIT License (unified in CerberusGuardian-SecuritySuite)",
  },
  {
    id: "linux",
    name: "LinuxGuardianWatchdog",
    platform: "Linux",
    themeColor: "#A020F0",
    description:
      "In active development. A Linux desktop toolkit for security posture, integrity monitoring, live sensors, reversible quarantine, exposure checks, and controlled remediation.",
    repositoryUrl: "https://github.com/abelxmendoza/LinuxGuardianWatchdog",
    release: releases.linux,
    supportedVersions: [
      "Verified target in docs/RELEASE_READINESS.md: Ubuntu 22.04, GNOME on X11",
      "Other distributions are outside that published test matrix",
    ],
    verifiedFeatures: [
      "Security posture assessment and hardening (linux_security_audit.sh, hardening.py, linux_hardening.sh)",
      "Network exposure monitoring and ROS 2 firewall helper (linux_exposure.sh, exposure_inventory.py, ros_firewall.py)",
      "System integrity checks and tripwires (integrity.py, linux_watchdog.sh, tripwires.py, decoys.py)",
      "Live blue-team sensors and incident timeline (sensors.py, defenses.py, setuid_watch.py, incidents.py, timeline.py)",
      "Reversible quarantine and self-check (quarantine.py, self_check.py)",
    ],
    permissions: [
      "Routine monitoring is designed to run as the logged-in user.",
      "Actions that change the system go through a fixed script and a polkit password prompt. docs/RELEASE_READINESS.md says those privileged flows were tested against stand-in programs, not the real apt, ufw, freshclam, or rkhunter tools.",
    ],
    networkBehavior: [
      "threat_intel.py downloads public known-bad address lists when an operator runs an update. It is not always on.",
      "An optional AI explainer can use local Ollama or Claude. Claude sends redacted content off the machine and is documented as opt-in and off by default.",
      "Scan results and incident timelines stay in ~/.linuxguardian/.",
    ],
    install: [
      "Click Download for Linux. The zip saves to your downloads folder.",
      "Unzip it. The folder name starts with LinuxGuardianWatchdog-.",
      "Open a terminal in LinuxGuardianSuiteUI and run ./run_ui.sh.",
      "Built for Ubuntu 22.04 with GNOME on X11. This zip is the app itself, not a .deb.",
    ],
    uninstall: [
      "There is no distribution uninstaller.",
      "install_desktop_entry.sh --uninstall removes the desktop entry and user timers.",
      "Remove the checkout and ~/.linuxguardian/ if you want the local files gone.",
    ],
    limitations: [
      "The download is the desktop project archive, not a .deb or a package-manager install.",
      "docs/RELEASE_READINESS.md records a local pytest run of 1398 passed (plus 8 shell suites), and notes privileged tools were tested against stand-ins.",
      "Real-attack detection quality is stated as unmeasured.",
      "No code-signed package, reproducible-build attestation, or independent security audit is published.",
    ],
    docs: [
      {
        label: "README",
        href: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/blob/main/README.md",
      },
      {
        label: "Release readiness",
        href: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/blob/main/docs/RELEASE_READINESS.md",
      },
      {
        label: "Testing",
        href: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/blob/main/docs/TESTING.md",
      },
      {
        label: "Architecture",
        href: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/blob/main/docs/ARCHITECTURE.md",
      },
    ],
    ciNote:
      "1398 automated pytest tests and 8 shell suites pass locally in the repository test suite; CI and CodeQL workflows are configured in .github/workflows.",
    ciUrl: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/actions",
    license: "MIT License",
  },
  {
    id: "macos",
    name: "MacGuardianWatchdog",
    platform: "Apple macOS",
    themeColor: "#FF1493",
    description:
      "In active development. The original macOS security monitoring and system hardening suite, with a native SwiftUI interface, shell/Python engines, one-step installer, and self-check.",
    repositoryUrl: "https://github.com/abelxmendoza/MacGuardianWatchdog",
    release: releases.macos,
    supportedVersions: [
      "Shell tools: macOS 12 Monterey or later (README)",
      "SwiftUI app: macOS 14 Sonoma or later (README)",
      "Building the app needs the full Xcode; the installer checks for it and says what to run if anything is missing",
    ],
    verifiedFeatures: [
      "File integrity monitoring (MacGuardianSuite/mac_watchdog.sh)",
      "Security posture checks (mac_security_audit.sh, hardening_assessment.sh)",
      "Blue-team process and network checks (mac_blueteam.sh)",
      "Remediation previews first and applies one category at a time with reversible quarantine (mac_remediation.sh --only, quarantine_manager.sh)",
      "Self-check of its own scripts, file permissions, app signature and background jobs (self_check.sh)",
      "Complete Homebrew and app update controls (package_updates.sh, commit fed9b33)",
    ],
    permissions: [
      "SECURITY.md: install.sh never uses sudo. If administrator rights are needed (for example accepting the Xcode license), it stops and shows the command to run.",
      "The rootkit scan needs administrator rights; the app opens it in Terminal so the user sees and approves it.",
      "macOS may ask for access to Documents or Desktop when file-integrity checks read them.",
      "Background jobs run a private copy of the scripts from ~/Library/Application Support/MacGuardian.",
    ],
    networkBehavior: [
      "PRIVACY.md says scan results, reports and logs stay on the Mac, in ~/.macguardian.",
      "Threat-intelligence feeds are downloaded from abuse.ch only when that script is run.",
      "Email reports leave the machine only if the operator configures SMTP, and go only to the address the operator sets. No recipient is built in.",
      "During install: Homebrew and freshclam only if the user accepts them, and Swift Package Manager fetching one pinned dependency (Yams).",
      "PRIVACY.md says telemetry and usage statistics are not transmitted.",
    ],
    install: [
      "Click Download for macOS. The zip saves to your downloads folder. Optionally compare its SHA-256 with the checksum shown here.",
      "Unzip it. The folder name starts with MacGuardianWatchdog-.",
      "Double-click Install MacGuardian.command (or run bash install.sh in Terminal). If macOS won't open it, right-click it and choose Open.",
      "The installer moves MacGuardian out of Downloads, builds the app with Xcode, installs it to Applications, asks before installing ClamAV, rkhunter or background jobs, and finishes with a self-check. macOS 14 or later and the full Xcode are required.",
    ],
    uninstall: [
      "Run uninstall.sh (in ~/Library/Application Support/MacGuardian/Suite after a zip install, or the project folder for a git clone).",
      "It removes the app, every MacGuardian background job and the private script copy.",
      "Scan results in ~/.macguardian are kept unless you run uninstall.sh --all.",
    ],
    limitations: [
      "The download is the project source. The app is built on your Mac, so the full Xcode is required, and it is ad-hoc signed locally rather than notarized by Apple.",
      "The self-check detects changes after install. Verifying the download checksum is what establishes trust in the copy installed.",
      "The tools can invoke ClamAV and rkhunter when those separate programs are installed. CERBERUS is not a replacement for antivirus or endpoint protection.",
      "Real-attack detection quality has not been independently measured.",
    ],
    docs: [
      {
        label: "README",
        href: "https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/README.md",
      },
      {
        label: "SECURITY.md",
        href: "https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/SECURITY.md",
      },
      {
        label: "PRIVACY.md",
        href: "https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/PRIVACY.md",
      },
      {
        label: "Release guide",
        href: "https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/RELEASE.md",
      },
    ],
    ciNote:
      "On 14 October 2026 the MacGuardian CI workflow passed on main (syntax, unit, integration, functional, end-to-end and security tests, secret scan, and app build) and commit fed9b33 added complete Homebrew and app update controls.",
    ciUrl: "https://github.com/abelxmendoza/MacGuardianWatchdog/actions",
    license: "MIT License",
  },
];

export function getGuardian(id: Guardian["id"]): Guardian {
  const guardian = guardians.find((item) => item.id === id);
  if (!guardian) {
    throw new Error(`Unknown guardian: ${id}`);
  }
  return guardian;
}
