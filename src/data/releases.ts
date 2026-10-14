import type { GuardianId, ReleaseRecord } from "./types";

/**
 * Download configuration for CERBERUS.
 * Linux and macOS links are GitHub archives of the commits below.
 * SHA-256 values were computed from those exact files on 14 October 2026.
 * Windows stays unpublished: it is still in development.
 */
export const releases: Record<GuardianId, ReleaseRecord> = {
  windows: {
    version: null,
    versionNote:
      "Least complete Guardian. Still in development. No desktop download is published. The project file version 1.0.0 is not an installer.",
    releaseStatus: "development",
    statusLabel: "In development",
    releaseDate: null,
    fileSize: null,
    checksum: null,
    architectures: ["win-x64"],
    downloadUrl: null,
    downloadLabel: null,
    releaseNotesUrl: null,
    releasePageUrl: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/releases",
  },
  linux: {
    version: "b923c19",
    versionNote:
      "Ready and functional. The button downloads the Linux desktop archive for commit b923c19. Unzip it on your computer and start the app. This is not a .deb.",
    releaseStatus: "stable",
    statusLabel: "Ready",
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
      "Ready and functional. The button downloads the macOS archive for commit e337fad. Unzip it and double-click Install MacGuardian.command: it builds the app on your Mac with Xcode and installs it. This is not a notarized installer.",
    releaseStatus: "stable",
    statusLabel: "Ready",
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
