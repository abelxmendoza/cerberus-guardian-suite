#!/bin/bash

# ===============================
# Test Helpers
# Common test utilities
# ===============================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

setup() {
    # Setup test environment
    export TEST_DIR=$(mktemp -d)
    export TEST_CONFIG="$TEST_DIR/test_config.yaml"
}

teardown() {
    # Cleanup test environment
    rm -rf "$TEST_DIR"
}

create_test_config() {
    cat > "$TEST_CONFIG" <<EOF
scan_intervals:
  process: 5
  network: 5
alerts:
  email_enabled: true
  webhook_enabled: false
ids:
  ruleset: default
EOF
}

create_test_event() {
    local event_type="${1:-process_anomaly}"
    local severity="${2:-medium}"
    
    cat <<EOF
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_type": "$event_type",
  "severity": "$severity",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "test_module",
  "context": {}
}
EOF
}

