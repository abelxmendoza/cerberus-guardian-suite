# Privacy Policy — LinuxGuardianWatchdog

**Last Updated**: October 2026

LinuxGuardianWatchdog is designed with a local-only, privacy-first architecture as part of **CERBERUS — The Guardian Security Suite**.

## Data Collection & Storage

- **Where Data Lives**: All scan results, file-integrity baselines, incident timelines, and quarantine vaults are stored locally in `~/.linuxguardian/` (created with `0700` user-only permissions and verified by `self_check.py`).
- **What Is Inspected Locally**:
  - File integrity SHA-256 hashes (`integrity.py`, `tripwires.py`)
  - Local processes, listening ports, startup entries, user accounts, and USB devices (`sensors.py`, `exposure_inventory.py`)
  - Security posture and firewall state (`linux_security_audit.sh`, `hardening.py`, `defenses.py`)
- **External Network Activity (Opt-In Only)**:
  - **No Telemetry**: LinuxGuardianWatchdog never sends telemetry or usage statistics.
  - **Threat Intelligence Lists**: `threat_intel.py --update` downloads free public known-bad IP lists only when explicitly run by the user.
  - **Optional AI Explainer**: `ai_investigator.py` is **off by default**. If enabled with local Ollama (`local_ai.py`), all inference stays on your machine. If configured with Claude, `ai_safety.py` redacts usernames, home paths, and secrets before sending incident summaries.
