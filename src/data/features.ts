import type { Capability } from "./types";

/**
 * Compatibility across the three unified CERBERUS Guardians on 22 October 2026.
 * "Present" means the repository contains that module in its codebase.
 * It does not mean the three apps behave identically on every OS, or that
 * detection quality has been independently measured.
 */
export const capabilities: Capability[] = [
  {
    id: "integrity",
    title: "System Integrity",
    summary: "Monitor important system and file changes with SHA-256 baselines.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/FileIntegrityMonitor.cs and Core/Sensors/ChangeWatch.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/integrity.py, tripwires.py, and linux_watchdog.sh",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_watchdog.sh",
      },
    },
  },
  {
    id: "posture",
    title: "Security Posture",
    summary: "Evaluate OS security configurations and hardening state.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/SecurityAudit.cs, Core/Compliance/, and Core/Hardening/",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_security_audit.sh, hardening.py, and defenses.py",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_security_audit.sh and hardening_assessment.sh",
      },
    },
  },
  {
    id: "network",
    title: "Network & Exposure Monitoring",
    summary: "Identify active connections, exposed services, and listening ports.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/Network/NetworkMonitor.cs and Core/Network/ExposureInventory.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_exposure.sh and exposure_inventory.py",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_blueteam.sh and network_scanner.sh",
      },
    },
  },
  {
    id: "threat",
    title: "Threat Detection & Timeline",
    summary: "Surface suspicious activity and fold repeated events into an incident timeline.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/BlueTeamDetector.cs, Core/Sensors/ChangeWatch.cs, and Core/Incidents/EventTimeline.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/sensors.py, incidents.py, and timeline.py",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_blueteam.sh and event_timeline.py",
      },
    },
  },
  {
    id: "audit",
    title: "Self-Check & Auditing",
    summary: "Inspect system settings and verify the Guardian's own integrity.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/SecurityAudit.cs and Core/SelfCheck/AppSelfCheck.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_security_audit.sh and self_check.py",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_security_audit.sh and self_check.sh",
      },
    },
  },
  {
    id: "remediation",
    title: "Controlled Remediation & Quarantine",
    summary: "Preview fixes in dry-run mode and reversibly quarantine suspicious files.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/RemediationEngine.cs (dry-run default) and Core/Quarantine/QuarantineVault.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_hardening.sh and quarantine.py",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_remediation.sh and quarantine_manager.sh",
      },
    },
  },
];
