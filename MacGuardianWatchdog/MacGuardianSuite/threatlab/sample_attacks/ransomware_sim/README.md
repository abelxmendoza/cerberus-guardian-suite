# Ransomware Simulation

## Purpose

Simulates ransomware behavior to test MacGuardian's ransomware detector.

## Usage

```bash
cd threatlab/sample_attacks/ransomware_sim
bash simulate.sh
```

## What It Does

1. Creates temporary test files
2. Renames files with encryption-like patterns (.encrypted, .locked)
3. Measures detector response time
4. Cleans up test files

## Safety

- Only operates in `/tmp/macguardian_test/`
- Requires explicit user confirmation
- Never touches real user files
- Automatically cleans up after test

## Detection Metrics

- Time to detection
- Number of files changed before detection
- False positive rate

