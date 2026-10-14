import type { Guardian } from "./types";
import { releases } from "./releases";

export const evidenceDate = "14 October 2026";

export const guardians: Guardian[] = [
  {
    id: "windows",
    name: "WindowsGuardianWatchdog",
    platform: "Microsoft Windows",
    themeColor: "#00BFFF",
    description:
      "The least complete Guardian, and still in development. It is a WinUI 3 / .NET 8 app for Windows. There is no desktop download yet.",
    repositoryUrl: "https://github.com/abelxmendoza/WindowsGuardianWatchdog",
    release: releases.windows,
    supportedVersions: [
      "Windows 10 version 1809 (build 17763) or later",
      "Windows 11",
      "Project target: net8.0-windows10.0.19041.0, platform win-x64",
    ],
    verifiedFeatures: [
      "Process and security-status monitoring (Core/SecurityMonitor.cs)",
      "File integrity monitoring (Core/FileIntegrityMonitor.cs)",
      "Security audit and hardening modules (Core/SecurityAudit.cs, Core/Hardening/)",
      "Remediation with dry-run defaulting to true (Core/RemediationEngine.cs)",
    ],
    permissions: [
      "app.manifest requests requireAdministrator. The process is designed to run elevated.",
      "A Windows service installer is included (InstallService.ps1) and also expects an administrator.",
    ],
    networkBehavior: [
      "NetworkMonitor.cs monitors connections on the machine.",
      "ThreatFeedService.cs can request a feed URL, but the list shipped in the repository is empty. No default feed host is configured.",
      "A telemetry client was not identified in that feed service. This page does not claim the whole Windows app has been audited for every outbound call.",
    ],
    install: [
      "Clone https://github.com/abelxmendoza/WindowsGuardianWatchdog.",
      "Build with the .NET 8 SDK. The project uses WinUI 3 and targets win-x64.",
      "From the repository: dotnet build.",
      "The manifest requests administrator rights when the built app starts.",
    ],
    uninstall: [
      "No published installer means there is no published uninstaller package.",
      "If the optional service was installed, InstallService.ps1 -Uninstall removes that service. Run it from an elevated PowerShell session.",
      "Delete the local build output after the service is removed.",
    ],
    limitations: [
      "Least complete of the three Guardians. Still in development, with no desktop download.",
      "The repository has no LICENSE file and no SECURITY.md.",
      "No automated test project was found. GitHub Actions does build the desktop app and runs CodeQL.",
      "Optional MSIX signing exists as a local script when the operator supplies a certificate. Public signed release assets were not found.",
    ],
    docs: [
      {
        label: "README",
        href: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/blob/main/README.md",
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
      "On 13 October 2026 the Windows desktop build and CodeQL workflows completed successfully on main. That is a compile and code scan, not a published test report.",
    ciUrl: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/actions",
    license: "No LICENSE file in the repository.",
  },
  {
    id: "linux",
    name: "LinuxGuardianWatchdog",
    platform: "Linux",
    themeColor: "#A020F0",
    description:
      "Ready and functional. A Linux desktop toolkit for security posture, integrity monitoring, exposure checks, and controlled remediation. Download it and run it on your computer.",
    repositoryUrl: "https://github.com/abelxmendoza/LinuxGuardianWatchdog",
    release: releases.linux,
    supportedVersions: [
      "Verified target in docs/RELEASE_READINESS.md: Ubuntu 22.04, GNOME on X11",
      "Other distributions are outside that published test matrix",
    ],
    verifiedFeatures: [
      "Security posture assessment (linux_security_audit.sh, hardening.py)",
      "Network exposure monitoring (linux_exposure.sh)",
      "System integrity checks (integrity.py, linux_watchdog.sh)",
      "Security configuration auditing (linux_hardening.sh, tripwires.py)",
    ],
    permissions: [
      "Routine monitoring is designed to run as the logged-in user.",
      "Actions that change the system go through a fixed script and a polkit password prompt. docs/RELEASE_READINESS.md says those privileged flows were tested against stand-in programs, not the real apt, ufw, freshclam, or rkhunter tools.",
    ],
    networkBehavior: [
      "threat_intel.py downloads public known-bad address lists when an operator runs an update. It is not described as always on.",
      "An optional AI explainer can use local Ollama or Claude. Claude sends content off the machine. The project documents it as opt-in and off by default.",
      "The readiness note says scan results are kept in the user data folder. There is no separate PRIVACY.md in the repository.",
    ],
    install: [
      "Click Download for Linux. The zip saves to your downloads folder.",
      "Unzip it. The folder name starts with LinuxGuardianWatchdog-.",
      "Open a terminal in LinuxGuardianSuiteUI and run ./run_ui.sh.",
      "Built for Ubuntu 22.04 with GNOME on X11. This zip is the app itself, not a .deb.",
    ],
    uninstall: [
      "There is no distribution uninstaller.",
      "install_desktop_entry.sh adds a desktop entry. tests/test_packaging.py covers removing that entry and LinuxGuardian user timers in a disposable home directory.",
      "Remove the checkout and the user data directory the README documents if you want the local files gone.",
    ],
    limitations: [
      "The download is the desktop project archive, not a .deb or a package-manager install.",
      "The same document records a local pytest run of 1398 passed, and says privileged tools were stubbed. Real-attack detection quality is stated as unmeasured.",
      "The latest completed CI workflow on main, 13 October 2026, failed. Local notes and GitHub Actions do not currently say the same thing.",
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
      "CI and CodeQL workflows exist. The latest completed CI run on main failed on 13 October 2026. Read the workflow log before treating the local pytest note as current.",
    ciUrl: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/actions",
    license: "MIT License",
  },
  {
    id: "macos",
    name: "MacGuardianWatchdog",
    platform: "Apple macOS",
    themeColor: "#FF1493",
    description:
      "Ready and functional. A macOS security monitoring and system hardening app, with a SwiftUI interface and shell tools. Download it and install it on your Mac.",
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
      "Remediation previews first and applies one category at a time (mac_remediation.sh --only)",
      "Self-check of its own scripts, file permissions, app signature and background jobs (self_check.sh)",
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
      "PRIVACY.md says telemetry and usage statistics are not transmitted. This page repeats that as the project's own statement, not as an independent packet capture.",
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
      "On 14 October 2026 the MacGuardian CI workflow passed on main for commit e337fad: syntax, unit, integration, functional, end-to-end and security tests, a secret scan, and an app build.",
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
