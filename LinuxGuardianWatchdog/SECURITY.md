# Security Policy — LinuxGuardianWatchdog

LinuxGuardianWatchdog is the native Linux desktop Guardian in **CERBERUS — The Guardian Security Suite**.

## Reporting a Vulnerability

Please report security problems privately:

- On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**.
- If that option is not available, open an issue titled `"Security contact request"` **without technical details**, and a private channel will be arranged.

## Verifying Your Download

Compare the SHA-256 hash of the downloaded archive against the checksum published on the CERBERUS download page:

```bash
shasum -a 256 ~/Downloads/LinuxGuardianWatchdog-*.zip
```

## Privilege & Execution Model

- **Unprivileged Monitoring**: Routine sensors (`sensors.py`, `integrity.py`, `exposure_inventory.py`, `tripwires.py`, `defenses.py`, `setuid_watch.py`) run as the logged-in user and store data in `~/.linuxguardian/` (`0700` permissions).
- **Controlled Root Actions via Polkit**: The few actions that modify system state (`linux_updates.sh`, `linux_hardening.sh`, `linux_ros_firewall.sh`, `freshclam`, rootkit scan) go through a fixed script and a single `pkexec` password prompt after showing a preview and asking for confirmation.
- **Reversible Quarantine**: `LinuxGuardianSuite/quarantine.py` re-verifies findings, moves files into a restricted quarantine vault with restore metadata, and only deletes permanently on explicit request.
- **AI Safety Guardrails**: The optional AI investigator (`ai_investigator.py`, `ai_safety.py`) is off by default, redacts sensitive paths/secrets before any query, and only permits a strict allow-list of read-only diagnostic commands.
- **Self-Check**: `LinuxGuardianSuite/self_check.py` checks file hashes against git, verifies directory permissions, and runs a dead-man's switch heartbeat for live monitoring.
