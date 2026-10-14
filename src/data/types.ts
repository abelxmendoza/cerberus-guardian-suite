export type GuardianId = "windows" | "linux" | "macos";

export type ReleaseStatus = "development" | "beta" | "stable" | "unavailable";

export type SupportLevel = "present" | "not-in-repo";

export interface ReleaseRecord {
  /** Published GitHub Release version. Null when no release exists. */
  version: string | null;
  versionNote: string;
  releaseStatus: ReleaseStatus;
  statusLabel: string;
  releaseDate: string | null;
  fileSize: string | null;
  /** SHA-256 of a published release asset. Never invent this. */
  checksum: string | null;
  architectures: string[];
  /**
   * Direct link to a file on GitHub Releases.
   * Leave null until a real asset exists. Do not use placeholder URLs.
   */
  downloadUrl: string | null;
  downloadLabel: string | null;
  releaseNotesUrl: string | null;
  releasePageUrl: string;
}

export interface DocLink {
  label: string;
  href: string;
}

export interface Guardian {
  id: GuardianId;
  name: string;
  platform: string;
  themeColor: string;
  description: string;
  repositoryUrl: string;
  release: ReleaseRecord;
  supportedVersions: string[];
  verifiedFeatures: string[];
  permissions: string[];
  networkBehavior: string[];
  install: string[];
  uninstall: string[];
  limitations: string[];
  docs: DocLink[];
  ciNote: string;
  ciUrl: string;
  license: string;
}

export interface CapabilitySupport {
  level: SupportLevel;
  evidence: string;
}

export interface Capability {
  id: string;
  title: string;
  summary: string;
  support: Record<GuardianId, CapabilitySupport>;
}
