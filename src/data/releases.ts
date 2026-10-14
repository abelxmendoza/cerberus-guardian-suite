import type { GuardianId, ReleaseRecord } from "./types";

/**
 * Download configuration for CERBERUS.
 * Checked against GitHub on 14 October 2026.
 * None of the three repositories had a published GitHub Release.
 * downloadUrl stays null until a real release asset exists.
 */
export const releases: Record<GuardianId, ReleaseRecord> = {
  windows: {
    version: null,
    versionNote:
      "WindowsGuardianWatchdog.csproj sets Version 1.0.0. That assembly version is not a GitHub Release.",
    releaseStatus: "development",
    statusLabel: "Development Build",
    releaseDate: null,
    fileSize: null,
    checksum: null,
    architectures: ["win-x64"],
    downloadUrl: null,
    releaseNotesUrl: null,
    releasePageUrl: "https://github.com/abelxmendoza/WindowsGuardianWatchdog/releases",
  },
  linux: {
    version: null,
    versionNote: "No version is published in a GitHub Release.",
    releaseStatus: "development",
    statusLabel: "Development Build",
    releaseDate: null,
    fileSize: null,
    checksum: null,
    architectures: [],
    downloadUrl: null,
    releaseNotesUrl: null,
    releasePageUrl: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/releases",
  },
  macos: {
    version: null,
    versionNote: "No version is published in a GitHub Release.",
    releaseStatus: "development",
    statusLabel: "Development Build",
    releaseDate: null,
    fileSize: null,
    checksum: null,
    architectures: [],
    downloadUrl: null,
    releaseNotesUrl: null,
    releasePageUrl: "https://github.com/abelxmendoza/MacGuardianWatchdog/releases",
  },
};

const RELEASE_ASSET =
  /^https:\/\/github\.com\/abelxmendoza\/(?:Windows|Linux|Mac)GuardianWatchdog\/releases\/download\/\S+$/;

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
