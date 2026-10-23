import { describe, expect, it } from "vitest";
import { capabilities } from "../data/features";
import { guardians } from "../data/guardians";
import {
  generateUnifiedReport,
  normalizeGuardianEvent,
  sampleRawGuardianEvents,
} from "../data/pipeline";
import { isPublishableDownload, releases } from "../data/releases";

describe("release configuration", () => {
  it("publishes all three downloads and marks Windows as the least ready", () => {
    expect(releases.windows.releaseStatus).toBe("beta");
    expect(releases.windows.statusLabel).toBe("Least ready");
    expect(isPublishableDownload(releases.windows)).toBe(true);
    expect(isPublishableDownload(releases.linux)).toBe(true);
    expect(isPublishableDownload(releases.macos)).toBe(true);
    expect(releases.windows.downloadLabel).toBe("Download for Windows");
    expect(releases.linux.downloadLabel).toBe("Download for Linux");
    expect(releases.macos.downloadLabel).toBe("Download for macOS");
    expect(releases.linux.statusLabel).toBe("Active development");
    expect(releases.macos.statusLabel).toBe("Active development");
  });

  it("rejects a development build even if a URL is pasted in", () => {
    const forged = {
      ...releases.windows,
      releaseStatus: "development" as const,
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

  it("normalizes raw Windows, Linux, and macOS events into Event Spec v1.0.0 and generates a unified report", () => {
    const normalized = sampleRawGuardianEvents.map((item) =>
      normalizeGuardianEvent(item.raw, item.platform),
    );
    expect(normalized).toHaveLength(3);
    expect(normalized[0].eventSpec).toBe("1.0.0");
    expect(normalized[0].platform).toBe("windows");
    expect(normalized[0].type).toBe("change_watch");
    expect(normalized[0].kind).toBe("incident");
    expect(normalized[1].platform).toBe("linux");
    expect(normalized[1].type).toBe("network_exposure");
    expect(normalized[1].kind).toBe("finding");
    expect(normalized[2].platform).toBe("macos");
    expect(normalized[2].type).toBe("self_check");
    expect(normalized[2].kind).toBe("information");

    const report = generateUnifiedReport(normalized);
    expect(report.securityScore).toBe(82);
    expect(report.overallStatus).toBe("good");
    expect(report.threats).toHaveLength(1);
    expect(report.findings).toHaveLength(1);
  });
});
