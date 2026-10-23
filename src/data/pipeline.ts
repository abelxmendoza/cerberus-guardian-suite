import type { GuardianId } from "./types";

export type CanonicalEventType =
  | "security_audit"
  | "file_integrity"
  | "threat_detection"
  | "process_monitoring"
  | "network_analysis"
  | "network_exposure"
  | "quarantine"
  | "self_check"
  | "change_watch"
  | "ml_anomaly"
  | "alert"
  | "incident"
  | "remediation"
  | "system_health";

export type CanonicalSeverity = "critical" | "high" | "warning" | "medium" | "low" | "info";
export type CanonicalKind = "incident" | "finding" | "information";
export type CanonicalStatus = "detected" | "changed" | "resolved";

export interface NormalizedCerberusEvent {
  eventSpec: "1.0.0";
  platform: GuardianId;
  timestamp: string;
  type: CanonicalEventType;
  kind: CanonicalKind;
  severity: CanonicalSeverity;
  category: string;
  status: CanonicalStatus;
  message: string;
  data: Record<string, unknown>;
  metadata: {
    source: string;
    mitreAttackId?: string;
  };
}

export interface UnifiedReportFinding {
  category: string;
  platform: GuardianId;
  title: string;
  severity: CanonicalSeverity;
  description: string;
  recommendation: string;
}

export interface UnifiedReportThreat {
  type: CanonicalEventType;
  platform: GuardianId;
  severity: CanonicalSeverity;
  description: string;
  timestamp: string;
}

export interface UnifiedSecurityReport {
  reportType: "daily" | "weekly" | "monthly" | "on_demand";
  generatedAt: string;
  period: {
    start: string;
    end: string;
  };
  securityScore: number;
  overallStatus: "excellent" | "good" | "fair" | "poor" | "critical";
  executiveSummary: string;
  findings: UnifiedReportFinding[];
  threats: UnifiedReportThreat[];
  events: NormalizedCerberusEvent[];
}

const TYPE_MAP: Record<string, CanonicalEventType> = {
  process: "process_monitoring",
  process_anomaly: "process_monitoring",
  process_monitoring: "process_monitoring",
  network: "network_analysis",
  network_analysis: "network_analysis",
  exposure: "network_exposure",
  exposed_service: "network_exposure",
  network_exposure: "network_exposure",
  fs: "file_integrity",
  filesystem: "file_integrity",
  integrity: "file_integrity",
  file_integrity: "file_integrity",
  audit: "security_audit",
  security_audit: "security_audit",
  hardening: "security_audit",
  sensor: "threat_detection",
  malware: "threat_detection",
  ids: "threat_detection",
  threat_detection: "threat_detection",
  quarantine: "quarantine",
  selfcheck: "self_check",
  self_check: "self_check",
  defenses: "change_watch",
  tripwire: "change_watch",
  change_watch: "change_watch",
  remediation: "remediation",
  incident: "incident",
  alert: "alert",
};

const SEVERITY_MAP: Record<string, CanonicalSeverity> = {
  critical: "critical",
  high: "high",
  warning: "warning",
  medium: "medium",
  low: "low",
  info: "info",
  informational: "info",
};

const KIND_BY_TYPE: Record<CanonicalEventType, CanonicalKind> = {
  threat_detection: "incident",
  change_watch: "incident",
  quarantine: "incident",
  incident: "incident",
  file_integrity: "incident",
  security_audit: "finding",
  network_exposure: "finding",
  self_check: "finding",
  process_monitoring: "information",
  network_analysis: "finding",
  ml_anomaly: "incident",
  alert: "incident",
  remediation: "information",
  system_health: "information",
};

export function normalizeGuardianEvent(
  raw: Record<string, unknown>,
  defaultPlatform: GuardianId = "linux",
): NormalizedCerberusEvent {
  const rawPlatform = String(raw.platform ?? defaultPlatform).toLowerCase();
  const platform: GuardianId =
    rawPlatform === "windows" || rawPlatform === "linux" || rawPlatform === "macos"
      ? rawPlatform
      : defaultPlatform;

  const rawType = String(
    raw.type ?? raw.event_type ?? raw.category ?? raw.event ?? "system_health",
  ).toLowerCase();
  const type: CanonicalEventType = TYPE_MAP[rawType] ?? "system_health";

  const rawSeverity = String(raw.severity ?? "info").toLowerCase();
  const severity: CanonicalSeverity = SEVERITY_MAP[rawSeverity] ?? "info";

  const timestamp = String(raw.timestamp ?? raw.detectedAt ?? "2026-10-22T19:45:00Z");

  const context =
    raw.context && typeof raw.context === "object" && !Array.isArray(raw.context)
      ? (raw.context as Record<string, unknown>)
      : {};
  const data =
    raw.data && typeof raw.data === "object" && !Array.isArray(raw.data)
      ? { ...(raw.data as Record<string, unknown>) }
      : { ...context };

  for (const key of ["pid", "process", "port", "protocol", "path", "rule", "status"]) {
    if (key in raw && !(key in data)) {
      data[key] = raw[key];
    }
  }

  const message = String(
    raw.message ?? raw.title ?? context.message ?? `${type} event on ${platform}`,
  );
  const kind: CanonicalKind = severity === "info" ? "information" : KIND_BY_TYPE[type];
  const rawStatus = String(raw.status ?? "detected");
  const status: CanonicalStatus =
    rawStatus === "detected" || rawStatus === "changed" || rawStatus === "resolved"
      ? rawStatus
      : "detected";

  const metaObj =
    raw.metadata && typeof raw.metadata === "object" && !Array.isArray(raw.metadata)
      ? (raw.metadata as Record<string, unknown>)
      : {};
  const source = String(raw.source ?? metaObj.source ?? raw.event ?? `${platform}_guardian`);
  const mitre = raw.mitreAttackId ?? raw.mitre ?? data.mitreAttackId;

  return {
    eventSpec: "1.0.0",
    platform,
    timestamp,
    type,
    kind,
    severity,
    category: String(raw.category ?? type),
    status,
    message,
    data,
    metadata: {
      source,
      ...(mitre ? { mitreAttackId: String(mitre) } : {}),
    },
  };
}

export function generateUnifiedReport(
  events: NormalizedCerberusEvent[],
  generatedAt = "2026-10-22T19:45:30Z",
): UnifiedSecurityReport {
  const penalties: Record<CanonicalSeverity, number> = {
    critical: 20,
    high: 12,
    warning: 6,
    medium: 6,
    low: 2,
    info: 0,
  };
  const totalPenalty = events.reduce((acc, ev) => acc + (penalties[ev.severity] ?? 0), 0);
  const securityScore = Math.max(0, Math.min(100, 100 - totalPenalty));

  const overallStatus: UnifiedSecurityReport["overallStatus"] =
    securityScore >= 90
      ? "excellent"
      : securityScore >= 75
        ? "good"
        : securityScore >= 55
          ? "fair"
          : securityScore >= 35
            ? "poor"
            : "critical";

  const findings: UnifiedReportFinding[] = [];
  const threats: UnifiedReportThreat[] = [];

  for (const ev of events) {
    if (ev.kind === "incident") {
      threats.push({
        type: ev.type,
        platform: ev.platform,
        severity: ev.severity,
        description: ev.message,
        timestamp: ev.timestamp,
      });
    } else if (ev.kind === "finding") {
      findings.push({
        category: ev.category,
        platform: ev.platform,
        title: ev.message,
        severity: ev.severity,
        description: `[${ev.platform.toUpperCase()}] ${ev.message}`,
        recommendation:
          "Review in the platform Guardian and preview remediation in dry-run mode before applying.",
      });
    }
  }

  const timestamps = events.map((e) => e.timestamp).sort();
  const platforms = Array.from(new Set(events.map((e) => e.platform))).sort();

  return {
    reportType: "on_demand",
    generatedAt,
    period: {
      start: timestamps[0] ?? generatedAt,
      end: timestamps[timestamps.length - 1] ?? generatedAt,
    },
    securityScore,
    overallStatus,
    executiveSummary: `Normalized ${events.length} security event(s) across ${platforms.join(", ") || "no platforms"}: ${threats.length} incident(s) and ${findings.length} posture finding(s).`,
    findings,
    threats,
    events,
  };
}

export const sampleRawGuardianEvents: Array<{
  platform: GuardianId;
  label: string;
  raw: Record<string, unknown>;
}> = [
  {
    platform: "windows",
    label: "Windows (ChangeWatch.cs)",
    raw: {
      timestamp: "2026-10-22T19:40:00Z",
      category: "defenses",
      severity: "high",
      message: "Windows Firewall public profile was switched off after being enabled",
      source: "ChangeWatch.cs",
      mitreAttackId: "T1562.004",
      data: { profile: "Public", previousState: "ON", currentState: "OFF" },
    },
  },
  {
    platform: "linux",
    label: "Linux (events.py / exposure_inventory.py)",
    raw: {
      timestamp: "2026-10-22T19:42:15Z",
      category: "network",
      severity: "warning",
      event: "exposed_service",
      status: "detected",
      message: "TCP port 5900 (VNC) is listening on 0.0.0.0 and reachable on the local network",
      process: "vino-server",
      pid: 5517,
      port: 5900,
      protocol: "tcp",
    },
  },
  {
    platform: "macos",
    label: "macOS (event_bus.py / self_check.sh)",
    raw: {
      event_id: "mg-20261022-001",
      timestamp: "2026-10-22T19:45:30Z",
      event_type: "self_check",
      severity: "info",
      source: "self_check.sh",
      context: {
        message:
          "MacGuardian self-check passed: all script SHA-256 fingerprints and permissions verified",
        scriptsVerified: 42,
      },
    },
  },
];
