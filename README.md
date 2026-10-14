# CERBERUS

**The Guardian Security Suite.** Three platforms. One guardian.

Built by an engineer, for people who value privacy, security, and control.

CERBERUS is an independent, open-source security monitoring and system hardening effort for Windows, Linux, and macOS. Each platform is its own desktop app, in its own repository, with its own interface. This repository is the public front door: the landing page at [cerberus-guardian-suite.vercel.app](https://cerberus-guardian-suite.vercel.app). It does not contain the desktop apps, and it does not host installers.

CERBERUS does not replace antivirus or endpoint protection. It watches, explains, and — where a Guardian supports it — previews a change before anything on the machine is modified.

| Guardian | Status | Repository |
| --- | --- | --- |
| [MacGuardianWatchdog](https://github.com/abelxmendoza/MacGuardianWatchdog) | Active development | SwiftUI app and shell tools for macOS |
| [LinuxGuardianWatchdog](https://github.com/abelxmendoza/LinuxGuardianWatchdog) | Active development | GTK app and shell tools for Linux |
| [WindowsGuardianWatchdog](https://github.com/abelxmendoza/WindowsGuardianWatchdog) | Active development. Least ready. | WinUI 3 / .NET 8 app for Windows |

MacGuardian is the original suite. LinuxGuardian is the Linux desktop port of that idea. WindowsGuardian is the native Windows port and is still the least developed of the three.

## Get the desktop apps

All three can be saved to a computer from the landing page. Each button downloads a GitHub archive of one commit. These are the projects, not a `.deb`, `.dmg`, or signed installer. All three are in active development. Windows is the least ready.

| Platform | Download | SHA-256 |
| --- | --- | --- |
| Linux | [LinuxGuardianWatchdog archive `b923c19`](https://github.com/abelxmendoza/LinuxGuardianWatchdog/archive/b923c198aa37eb6d0712c61b49f67862729ae289.zip) | `3dabde32802a4b466f1254e43a4f7a6d5e616ed564045e0b9730b50957819f2d` |
| macOS | [MacGuardianWatchdog archive `e337fad`](https://github.com/abelxmendoza/MacGuardianWatchdog/archive/e337fadff778d4a5dd985525de87984802f9362a.zip) | `c06f1d6df056811ca98efd3e1e43313da2d1d34c9047f8ad831ad8930cfd0c5d` |
| Windows | [WindowsGuardianWatchdog archive `f8b5feb`](https://github.com/abelxmendoza/WindowsGuardianWatchdog/archive/f8b5febb2ba393dd1d3b3cff5f32a29d6e8c826b.zip) | `a1baf00e819b04af570328e943cfe83004b5484a9e8fb8300257e9bf8449824e` |

Hashes were computed from those exact zip files on 14 October 2026.

### Linux

In active development. The verified target is Ubuntu 22.04 with GNOME on X11. Other distributions are untested.

```bash
unzip LinuxGuardianWatchdog-b923c198aa37eb6d0712c61b49f67862729ae289.zip
cd LinuxGuardianWatchdog-b923c198aa37eb6d0712c61b49f67862729ae289/LinuxGuardianSuiteUI
./run_ui.sh
```

The window needs PyGObject and libadwaita. Scans need ClamAV and rkhunter when you want those scanners. Actions that change the machine go through a fixed script and one polkit password prompt. Nothing is deleted, killed, or changed without a preview and a confirmation. Full package list, terminal commands, and the desktop-entry installer are in the [Linux README](https://github.com/abelxmendoza/LinuxGuardianWatchdog/blob/main/README.md).

What the Linux app covers, from that README: a scored posture audit, ClamAV and rkhunter scans, SHA-256 file integrity, live sensors (logins, processes, network, startup entries, accounts, USB), incidents with a timeline, reversible quarantine, a hardening checklist, exposure checks, and optional opt-in AI explanations (local Ollama or Claude, off by default). Local data stays in `~/.linuxguardian/`.

The Linux project’s own [release readiness note](https://github.com/abelxmendoza/LinuxGuardianWatchdog/blob/main/docs/RELEASE_READINESS.md) is the detailed record of what was tested. It describes owner daily use on Ubuntu 22.04, a local pytest run of 1398 passed, and privileged tools exercised against stand-ins. It is not a `.deb`.

### macOS

In active development. The SwiftUI app needs macOS 14 or later and the full Xcode. The shell tools run on macOS 12 or later.

```bash
unzip MacGuardianWatchdog-e337fadff778d4a5dd985525de87984802f9362a.zip
cd MacGuardianWatchdog-e337fadff778d4a5dd985525de87984802f9362a
# Double-click Install MacGuardian.command, or:
bash install.sh
```

The installer moves the project out of Downloads, builds the app with Xcode, and puts MacGuardian Suite in Applications. It asks before installing ClamAV, rkhunter, or background jobs, then runs a self-check. If macOS will not open the command file, right-click it and choose Open. The app is built on your Mac and signed locally. It is not notarized by Apple.

Remove it with `uninstall.sh`. That script removes the app, the background jobs, and the private script copy. Scan results in `~/.macguardian` stay unless you pass `--all`.

Details, the command-line menu, and scheduling are in the [Mac README](https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/README.md), [SECURITY.md](https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/SECURITY.md), and [PRIVACY.md](https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/PRIVACY.md).

What the Mac app covers, from that README: ClamAV and rkhunter scanning, SHA-256 file integrity, a blue-team view of processes and network connections, threat-intelligence matching, a scored security audit (FileVault, SIP, Gatekeeper, firewall), cache cleaning, process control, and local reports. Scan data stays on the Mac. Email leaves the machine only if you configure it. On 14 October 2026 the MacGuardian CI workflow passed on main for commit `e337fad`.

### Windows

In active development, and the least ready Guardian. The download is the project archive for commit `f8b5feb`, not a signed MSIX. That repository’s [distribution notes](https://github.com/abelxmendoza/WindowsGuardianWatchdog/blob/main/DISTRIBUTION.md) describe a signed `WindowsGuardianWatchdog.msix` as the public installer. No such file is published.

```bash
unzip WindowsGuardianWatchdog-f8b5febb2ba393dd1d3b3cff5f32a29d6e8c826b.zip
cd WindowsGuardianWatchdog-f8b5febb2ba393dd1d3b3cff5f32a29d6e8c826b
dotnet build -c Release
```

Requirements from the Windows README: Windows 10 version 1809 (build 17763) or later, or Windows 11, plus the .NET 8 SDK. The project targets `net8.0-windows10.0.19041.0` and `win-x64`, and the app manifest requests administrator rights. Start the built app from `bin/Release/net8.0-windows10.0.19041.0/`.

The Windows tree is a WinUI 3 app with modules for process monitoring, file integrity, blue-team detection, security audit, remediation that defaults to dry-run, plus app updates, hardening, cache cleanup, and file search. A release workflow can publish a signed MSIX when a trusted certificate is configured. That workflow has not published a release. The repository has no `LICENSE` file and no `SECURITY.md`. Build and service notes are in the [Windows README](https://github.com/abelxmendoza/WindowsGuardianWatchdog/blob/main/README.md).

## How the three apps line up

Each Guardian keeps the same job: look at the machine, score the posture, watch for change, and let the operator decide before a fix is applied. The implementation follows the platform.

| | macOS | Linux | Windows |
| --- | --- | --- | --- |
| Interface | SwiftUI | GTK4 and libadwaita | WinUI 3 |
| Work behind the UI | Shell and Python | Shell and Python | C# |
| Scheduling | `launchd` | systemd user timers | Windows service scripts |
| File integrity | SHA-256 baseline | SHA-256 baseline | SHA-256 baseline |
| Local data | `~/.macguardian/` and Application Support | `~/.linuxguardian/` | Local to the app; no privacy policy file is published |
| License | MIT | MIT | No `LICENSE` file |

Shared capabilities that are present in all three codebases: system integrity, security posture, network monitoring, threat detection, security auditing, and controlled remediation. A capability in one Guardian is not a promise that the others ship the same screen or the same depth. Linux documents the widest set of desktop tools. macOS documents the original suite, including optional email reports and threat feeds. Windows is the earliest port.

## This repository

The site is a static React app (Vite, TypeScript, Tailwind). It has no accounts, no database, and no uploaded binaries. Download links go to GitHub.

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

Playwright downloads Chromium on first use: `npx playwright install chromium`.

The intended portfolio path is `https://www.abelxmendoza.com/projects/cerberus`. The live portfolio is a separate site. To build this page for that path:

```bash
VITE_BASE=/projects/cerberus/ npm run build
```

Copy `dist/` into the portfolio’s `public/projects/cerberus/` directory. Canonical and Open Graph tags live in `index.html`. The share image is `public/og.webp`.

### Changing a download

Linux and macOS links are commit archives, recorded in `src/data/releases.ts` with a version, file size, and SHA-256. A control renders only when `releaseStatus` is `beta` or `stable` and the URL is a GitHub release asset or a 40-character commit archive under `abelxmendoza`. `development` never renders a download, so Windows stays unpublished even if a URL is pasted in. Do not upload executables to this site.

## Author

Abel Mendoza. Computer Science, California State University, Fullerton. The work behind CERBERUS comes from robotics operations, hardware testing, systems validation, and software engineering.

- [abelxmendoza.com](https://www.abelxmendoza.com)
- [github.com/abelxmendoza](https://github.com/abelxmendoza)
- [LinkedIn](https://www.linkedin.com/in/abelxmendoza/)
