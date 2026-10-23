#!/usr/bin/env python3
"""
CERBERUS Unified Telemetry Pipeline:
Detect / Ingest Raw Guardian Events -> Normalize to Event Spec v1.0.0 -> Generate Cross-Platform Report.

Supports raw event formats from:
  - WindowsGuardianWatchdog (ChangeWatch / EventTimeline / SecurityMonitor JSON)
  - LinuxGuardianWatchdog   (LinuxGuardianSuite/events.py JSON records in ~/.linuxguardian/incidents/)
  - MacGuardianWatchdog     (MacGuardianSuite/outputs/event_bus.py & mg_monitor JSON records in ~/.macguardian/events/)
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import sys
from typing import Any

ROOT_DIR = pathlib.Path(__file__).resolve().parent.parent.parent
EVENT_SCHEMA_PATH = ROOT_DIR / "shared" / "schemas" / "event_spec_v1.json"
REPORT_SCHEMA_PATH = ROOT_DIR / "shared" / "schemas" / "report_schema.json"

TYPE_MAP = {
    # Linux / macOS / Windows raw categories -> canonical Event Spec v1.0.0 types
    "process": "process_monitoring",
    "process_anomaly": "process_monitoring",
    "process_monitoring": "process_monitoring",
    "network": "network_analysis",
    "network_analysis": "network_analysis",
    "exposure": "network_exposure",
    "exposed_service": "network_exposure",
    "network_exposure": "network_exposure",
    "fs": "file_integrity",
    "filesystem": "file_integrity",
    "integrity": "file_integrity",
    "file_integrity": "file_integrity",
    "audit": "security_audit",
    "security_audit": "security_audit",
    "hardening": "security_audit",
    "sensor": "threat_detection",
    "malware": "threat_detection",
    "ids": "threat_detection",
    "threat_detection": "threat_detection",
    "quarantine": "quarantine",
    "selfcheck": "self_check",
    "self_check": "self_check",
    "defenses": "change_watch",
    "tripwire": "change_watch",
    "change_watch": "change_watch",
    "remediation": "remediation",
    "incident": "incident",
    "alert": "alert",
}

SEVERITY_MAP = {
    "critical": "critical",
    "high": "high",
    "warning": "warning",
    "medium": "medium",
    "low": "low",
    "info": "info",
    "informational": "info",
}

KIND_BY_TYPE = {
    "threat_detection": "incident",
    "change_watch": "incident",
    "quarantine": "incident",
    "incident": "incident",
    "file_integrity": "incident",
    "security_audit": "finding",
    "network_exposure": "finding",
    "self_check": "finding",
    "process_monitoring": "information",
    "network_analysis": "finding",
    "remediation": "information",
    "system_health": "information",
}


def normalize_event(raw: dict[str, Any], default_platform: str = "linux") -> dict[str, Any]:
    """Normalize a raw event from Windows, Linux, or macOS into Event Spec v1.0.0."""
    platform = str(raw.get("platform") or default_platform).lower()
    if platform not in ("windows", "linux", "macos"):
        platform = default_platform

    raw_type = str(
        raw.get("type")
        or raw.get("event_type")
        or raw.get("category")
        or raw.get("event")
        or "system_health"
    ).lower()
    canonical_type = TYPE_MAP.get(raw_type, "system_health")

    raw_sev = str(raw.get("severity") or "info").lower()
    severity = SEVERITY_MAP.get(raw_sev, "info")

    timestamp = str(
        raw.get("timestamp")
        or raw.get("detectedAt")
        or dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    )

    context = raw.get("context") if isinstance(raw.get("context"), dict) else {}
    data = raw.get("data") if isinstance(raw.get("data"), dict) else dict(context)
    for k in ("pid", "process", "port", "protocol", "path", "rule", "status"):
        if k in raw and k not in data:
            data[k] = raw[k]

    message = str(
        raw.get("message")
        or raw.get("title")
        or context.get("message")
        or f"{canonical_type} event on {platform}"
    )

    kind = "information" if severity == "info" else KIND_BY_TYPE.get(canonical_type, "finding")
    source = str(
        raw.get("source")
        or (raw.get("metadata") or {}).get("source")
        or raw.get("event")
        or f"{platform}_guardian"
    )
    mitre = raw.get("mitreAttackId") or raw.get("mitre") or data.get("mitreAttackId")

    metadata: dict[str, Any] = {"source": source}
    if mitre:
        metadata["mitreAttackId"] = str(mitre)

    return {
        "eventSpec": "1.0.0",
        "platform": platform,
        "timestamp": timestamp,
        "type": canonical_type,
        "kind": kind,
        "severity": severity,
        "category": str(raw.get("category") or canonical_type),
        "status": str(raw.get("status") if raw.get("status") in ("detected", "changed", "resolved") else "detected"),
        "message": message,
        "data": data,
        "metadata": metadata,
    }


def validate_normalized_event(event: dict[str, Any], schema: dict[str, Any]) -> None:
    """Validate required fields and enums against shared/schemas/event_spec_v1.json."""
    for req in schema["required"]:
        if req not in event:
            raise ValueError(f"Missing required field: {req}")
    props = schema["properties"]
    for field in ("eventSpec", "platform", "type", "severity", "kind", "status"):
        if field in event and "enum" in props.get(field, {}):
            allowed = props[field]["enum"]
            if event[field] not in allowed:
                raise ValueError(f"Invalid {field}={event[field]!r}; expected one of {allowed}")


def generate_report(
    normalized_events: list[dict[str, Any]],
    report_type: str = "on_demand",
) -> dict[str, Any]:
    """Generate a cross-platform security report conforming to shared/schemas/report_schema.json."""
    now = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    timestamps = [e["timestamp"] for e in normalized_events] or [now]

    penalties = {"critical": 20, "high": 12, "warning": 6, "medium": 6, "low": 2, "info": 0}
    total_penalty = sum(penalties.get(e["severity"], 0) for e in normalized_events)
    score = max(0, min(100, 100 - total_penalty))

    if score >= 90:
        status = "excellent"
    elif score >= 75:
        status = "good"
    elif score >= 55:
        status = "fair"
    elif score >= 35:
        status = "poor"
    else:
        status = "critical"

    findings = []
    threats = []
    for e in normalized_events:
        if e["kind"] == "incident":
            threats.append(
                {
                    "type": e["type"],
                    "platform": e["platform"],
                    "severity": e["severity"],
                    "description": e["message"],
                    "timestamp": e["timestamp"],
                }
            )
        elif e["kind"] == "finding":
            findings.append(
                {
                    "category": e["category"],
                    "platform": e["platform"],
                    "title": e["message"],
                    "severity": e["severity"],
                    "description": f"[{e['platform'].upper()}] {e['message']}",
                    "recommendation": "Review in the platform Guardian and preview remediation in dry-run mode before applying.",
                }
            )

    platforms_seen = sorted({e["platform"] for e in normalized_events})
    return {
        "reportType": report_type,
        "generatedAt": now,
        "period": {
            "start": min(timestamps),
            "end": max(timestamps),
        },
        "securityScore": score,
        "overallStatus": status,
        "executiveSummary": (
            f"Normalized {len(normalized_events)} security event(s) across "
            f"{', '.join(platforms_seen) or 'no platforms'}: "
            f"{len(threats)} incident(s) and {len(findings)} posture finding(s)."
        ),
        "findings": findings,
        "threats": threats,
        "events": normalized_events,
    }


def sample_raw_events() -> list[tuple[str, dict[str, Any]]]:
    """Representative raw events from Windows, Linux, and macOS Guardians."""
    return [
        (
            "windows",
            {
                "timestamp": "2026-10-22T19:40:00Z",
                "category": "defenses",
                "severity": "high",
                "message": "Windows Firewall public profile was switched off after being enabled",
                "source": "ChangeWatch.cs",
                "mitreAttackId": "T1562.004",
                "data": {"profile": "Public", "previousState": "ON", "currentState": "OFF"},
            },
        ),
        (
            "linux",
            {
                "timestamp": "2026-10-22T19:42:15Z",
                "category": "network",
                "severity": "warning",
                "event": "exposed_service",
                "status": "detected",
                "message": "TCP port 5900 (VNC) is listening on 0.0.0.0 and reachable on the local network",
                "process": "vino-server",
                "pid": 5517,
                "port": 5900,
                "protocol": "tcp",
            },
        ),
        (
            "macos",
            {
                "event_id": "mg-20261022-001",
                "timestamp": "2026-10-22T19:45:30Z",
                "event_type": "self_check",
                "severity": "info",
                "source": "self_check.sh",
                "context": {
                    "message": "MacGuardian self-check passed: all script SHA-256 fingerprints and permissions verified",
                    "scriptsVerified": 42,
                },
            },
        ),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="CERBERUS Unified Event Normalizer & Report Generator")
    parser.add_argument("--demo", action="store_true", help="Run end-to-end normalization and report on sample Windows/Linux/macOS events")
    parser.add_argument("--output", type=pathlib.Path, help="Optional file path to write JSON report")
    args = parser.parse_args()

    schema = json.loads(EVENT_SCHEMA_PATH.read_text())
    normalized: list[dict[str, Any]] = []

    for platform, raw in sample_raw_events():
        ev = normalize_event(raw, default_platform=platform)
        validate_normalized_event(ev, schema)
        normalized.append(ev)

    report = generate_report(normalized, report_type="on_demand")
    output_json = json.dumps(report, indent=2)

    if args.output:
        args.output.write_text(output_json + "\n")
    else:
        print(output_json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
