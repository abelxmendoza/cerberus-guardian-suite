import { describe, expect, it } from "vitest";
import { capabilities } from "../data/features";
import { guardians } from "../data/guardians";
import { isPublishableDownload, releases } from "../data/releases";

describe("release configuration", () => {
  it("publishes Linux and macOS downloads and keeps Windows unpublished", () => {
    expect(releases.windows.downloadUrl).toBeNull();
    expect(releases.windows.releaseStatus).toBe("development");
    expect(isPublishableDownload(releases.windows)).toBe(false);
    expect(isPublishableDownload(releases.linux)).toBe(true);
    expect(isPublishableDownload(releases.macos)).toBe(true);
    expect(releases.linux.downloadLabel).toBe("Download for Linux");
    expect(releases.macos.downloadLabel).toBe("Download for macOS");
  });

  it("rejects a development build even if a URL is pasted in", () => {
    const forged = {
      ...releases.windows,
      downloadUrl:
        "https://github.com/abelxmendoza/WindowsGuardianWatchdog/releases/download/v1.0.0/app.zip",
      checksum: "abc",
      version: "1.0.0",
    };
    expect(isPublishableDownload(forged)).toBe(false);
  });

  it("accepts only a stable or beta GitHub release asset with a checksum", () => {
    const ready = {
      ...releases.linux,
      releaseStatus: "stable" as const,
      version: "1.0.0",
      checksum: "deadbeef",
      downloadUrl:
        "https://github.com/abelxmendoza/LinuxGuardianWatchdog/releases/download/v1.0.0/linux.tar.gz",
    };
    expect(isPublishableDownload(ready)).toBe(true);
    expect(
      isPublishableDownload({
        ...ready,
        downloadUrl: "https://example.com/linux.tar.gz",
      }),
    ).toBe(false);
  });

  it("records evidence for every matrix cell", () => {
    for (const capability of capabilities) {
      for (const guardian of guardians) {
        expect(capability.support[guardian.id].evidence.length).toBeGreaterThan(8);
      }
    }
  });
});
