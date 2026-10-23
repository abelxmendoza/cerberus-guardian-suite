import type { GuardianId, ReleaseRecord } from "./types";

/**
 * Download configuration for CERBERUS (CerberusGuardian-SecuritySuite).
 * Each link is a GitHub archive of the latest commit below.
 * SHA-256 values were computed from those exact archives on 22 October 2026.
 * All three Guardians are unified in CerberusGuardian-SecuritySuite and in active development.
 * Windows is the least ready; its archive is source, not the signed MSIX described in that repository.
 */
export const releases: Record<GuardianId, ReleaseRecord> = {
  windows: {
    version: "7b3f424",
    versionNote:
      "Active development, and the least ready Guardian. The button downloads the Windows project archive for commit 7b3f424 (including ported change watch, reversible quarantine, exposure inventory, self-check, and reports). Unzip it and build it on your PC. This is not the signed MSIX.",
    releaseStatus: "beta",
    statusLabel: "Least ready",
    releaseDate: "22 October 2026",
    fileSize: "2.3 MB",
    checksum: "b40ce993c60eefed7864149b4df597e497a798f41b5ce8781b8634c9f6309c66",
    architectures: ["source archive"],
    downloadUrl:
      "https://github.com/abelxmendoza/WindowsGuardianWatchdog/archive/7b3f424ab921c03b63142185e709fcdb9fd3ba39.zip",
    downloadLabel: "Download for Windows",
    releaseNotesUrl:
      "https://github.com/abelxmendoza/WindowsGuardianWatchdog/commit/7b3f424ab921c03b63142185e709fcdb9fd3ba39",
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
    version: "fed9b33",
    versionNote:
      "In active development. The button downloads the macOS archive for commit fed9b33 (one-step install.sh, self-check, and complete Homebrew/app update controls). Unzip it and double-click Install MacGuardian.command: it builds the app on your Mac with Xcode and installs it. This is not a notarized installer.",
    releaseStatus: "stable",
    statusLabel: "Active development",
    releaseDate: "14 October 2026",
    fileSize: "16.3 MB",
    checksum: "386d037db3a1e0e24024462465aeebec52c8e75b2ba9f515283bf1c798f2afa6",
    architectures: ["source archive"],
    downloadUrl:
      "https://github.com/abelxmendoza/MacGuardianWatchdog/archive/fed9b33dc85fb6ec50b3e51ae906f0819a2374e0.zip",
    downloadLabel: "Download for macOS",
    releaseNotesUrl:
      "https://github.com/abelxmendoza/MacGuardianWatchdog/commit/fed9b33dc85fb6ec50b3e51ae906f0819a2374e0",
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
