# Persistence Simulation

## Purpose

Simulates persistence mechanisms to test MacGuardian's persistence detection.

## Usage

```bash
cd threatlab/sample_attacks/persistence_sim
bash simulate.sh
```

## What It Does

1. Creates fake LaunchAgent plist
2. Creates fake LaunchDaemon plist
3. Creates cron job entry
4. Tests detection of unauthorized persistence

## Safety

- Uses test-only plist files
- Requires explicit user confirmation
- Never modifies real system files
- Automatically cleans up after test

## Detection Metrics

- Detection time
- Detection accuracy
- False positive rate

