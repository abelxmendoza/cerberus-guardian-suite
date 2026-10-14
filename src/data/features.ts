import type { Capability } from "./types";

/**
 * Compatibility is limited to modules present in the public repositories
 * on 14 October 2026. "Present" means the repository contains that code.
 * It does not mean the three apps behave the same, or that detection
 * quality has been independently measured.
 */
export const capabilities: Capability[] = [
  {
    id: "integrity",
    title: "System Integrity",
    summary: "Monitor important system changes.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/FileIntegrityMonitor.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/integrity.py and linux_watchdog.sh",
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
    summary: "Evaluate security configurations.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/SecurityAudit.cs and Core/Hardening/",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_security_audit.sh and hardening.py",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_security_audit.sh and hardening_assessment.sh",
      },
    },
  },
  {
    id: "network",
    title: "Network Monitoring",
    summary: "Identify exposed services and ports.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/Network/NetworkMonitor.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_exposure.sh",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_blueteam.sh",
      },
    },
  },
  {
    id: "threat",
    title: "Threat Detection",
    summary: "Surface potentially suspicious activity.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/BlueTeamDetector.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/sensors.py and incidents.py",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_blueteam.sh",
      },
    },
  },
  {
    id: "audit",
    title: "Security Auditing",
    summary: "Inspect relevant system settings.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/SecurityAudit.cs",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_security_audit.sh",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_security_audit.sh",
      },
    },
  },
  {
    id: "remediation",
    title: "Controlled Remediation",
    summary: "Help users address identified issues.",
    support: {
      windows: {
        level: "present",
        evidence: "Core/RemediationEngine.cs defaults dryRun to true",
      },
      linux: {
        level: "present",
        evidence: "LinuxGuardianSuite/linux_hardening.sh requires confirmation before apply",
      },
      macos: {
        level: "present",
        evidence: "MacGuardianSuite/mac_remediation.sh is documented as dry-run by default",
      },
    },
  },
];
