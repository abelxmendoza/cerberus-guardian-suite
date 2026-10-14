import type { GuardianId, ReleaseRecord } from "./types";

/**
 * Download configuration for CERBERUS.
 * Each link is a GitHub archive of the commit below.
 * SHA-256 values were computed from those exact files on 14 October 2026.
 * All three Guardians are in active development. Windows is the least ready.
 * Its archive is source, not the signed MSIX described in that repository.
 */
export const releases: Record<GuardianId, ReleaseRecord> = {
  windows: {
    version: "f8b5feb",
    versionNote:
      "Active development, and the least ready Guardian. The button downloads the Windows project archive for commit f8b5feb. Unzip it and build it on your PC. This is not the signed MSIX. That installer is not published.",
    releaseStatus: "beta",
    statusLabel: "Least ready",
    releaseDate: "14 October 2026",
    fileSize: "2.2 MB",
    checksum: "a1baf00e819b04af570328e943cfe83004b5484a9e8fb8300257e9bf8449824e",
    architectures: ["source archive"],
    downloadUrl:
      "https://github.com/abelxmendoza/WindowsGuardianWatchdog/archive/f8b5febb2ba393dd1d3b3cff5f32a29d6e8c826b.zip",
    downloadLabel: "Download for Windows",
    releaseNotesUrl:
      "https://github.com/abelxmendoza/WindowsGuardianWatchdog/commit/f8b5febb2ba393dd1d3b3cff5f32a29d6e8c826b",
    releasePageUrl: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/releases",
  },
  linux: {
    version: "b923c19",
    versionNote:
      "In active development. The button downloads the Linux desktop archive for commit b923c19. Unzip it on your computer and start the app. This is not a .deb.",
    releaseStatus: "stable",
    statusLabel: "Active development",
    releaseDate: "13 October 2026",
    fileSize: "3.3 MB",
    checksum: "3dabde32802a4b466f1254e43a4f7a6d5e616ed564045e0b9730b50957819f2d",
    architectures: ["source archive"],
    downloadUrl:
      "https://github.com/abelxmendoza/LinuxGuardianWatchdog/archive/b923c198aa37eb6d0712c61b49f67862729ae289.zip",
    downloadLabel: "Download for Linux",
    releaseNotesUrl:
      "https://github.com/abelxmendoza/LinuxGuardianWatchdog/commit/b923c198aa37eb6d0712c61b49f67862729ae289",
    releasePageUrl: "https://github.com/abelxmendoza/LinuxGuardianWatchdog",
  },
  macos: {
    version: "e337fad",
    versionNote:
      "In active development. The button downloads the macOS archive for commit e337fad. Unzip it and double-click Install MacGuardian.command: it builds the app on your Mac with Xcode and installs it. This is not a notarized installer.",
    releaseStatus: "stable",
    statusLabel: "Active development",
    releaseDate: "14 October 2026",
    fileSize: "16.3 MB",
    checksum: "c06f1d6df056811ca98efd3e1e43313da2d1d34c9047f8ad831ad8930cfd0c5d",
    architectures: ["source archive"],
    downloadUrl:
      "https://github.com/abelxmendoza/MacGuardianWatchdog/archive/e337fadff778d4a5dd985525de87984802f9362a.zip",
    downloadLabel: "Download for macOS",
    releaseNotesUrl:
      "https://github.com/abelxmendoza/MacGuardianWatchdog/commit/e337fadff778d4a5dd985525de87984802f9362a",
    releasePageUrl: "https://github.com/abelxmendoza/MacGuardianWatchdog",
  },
};

const RELEASE_ASSET =
  /^https:\/\/github\.com\/abelxmendoza\/(?:Windows|Linux|Mac)GuardianWatchdog\/(?:releases\/download\/\S+|archive\/[0-9a-f]{40}\.zip)$/;

/** A download control may be enabled only for a real GitHub Release asset. */
export function isPublishableDownload(release: ReleaseRecord): boolean {
  if (release.releaseStatus !== "beta" && release.releaseStatus !== "stable") {
    return false;
  }
  if (!release.downloadUrl || !release.checksum || !release.version) {
    return false;
  }
  return RELEASE_ASSET.test(release.downloadUrl);
}
