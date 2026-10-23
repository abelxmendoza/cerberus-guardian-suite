# Network Beacon Simulation

## Purpose

Simulates C2 beacon patterns to test MacGuardian's network correlation engine.

## Usage

```bash
cd threatlab/sample_attacks/network_beacon_sim
bash simulate.sh
```

## What It Does

1. Simulates periodic network connections
2. Tests DNS query patterns
3. Validates correlation heuristics
4. Measures detection accuracy

## Safety

- Only connects to localhost test servers
- Requires explicit user confirmation
- Never connects to external hosts
- Automatically cleans up after test

## Detection Metrics

- Beacon detection time
- Pattern recognition accuracy
- Correlation effectiveness

