#!/usr/bin/env bats

# ===============================
# Event Pipeline Integration Tests
# ===============================

load "$(dirname "${BASH_SOURCE[0]}")/../fixtures/test_helpers.bash"

@test "event conforms to Event Spec v1.0.0" {
    local event
    event=$(create_test_event "process_anomaly" "high")
    
    # Check required fields
    echo "$event" | grep -q '"event_id"'
    echo "$event" | grep -q '"event_type"'
    echo "$event" | grep -q '"severity"'
    echo "$event" | grep -q '"timestamp"'
    echo "$event" | grep -q '"source"'
    echo "$event" | grep -q '"context"'
}

@test "event severity is valid enum" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    
    local severities=("low" "medium" "high" "critical")
    for severity in "${severities[@]}"; do
        local event
        event=$(create_test_event "process_anomaly" "$severity")
        validate_severity "$severity"
        [ $? -eq 0 ]
    done
}

@test "event timestamp is ISO8601 format" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    
    local event
    event=$(create_test_event)
    
    local timestamp
    timestamp=$(echo "$event" | grep -o '"timestamp": "[^"]*"' | cut -d'"' -f4)
    
    validate_timestamp "$timestamp"
    [ $? -eq 0 ]
}

@test "event can be parsed as JSON" {
    local event
    event=$(create_test_event)
    
    # Try to parse as JSON (requires jq or python)
    if command -v python3 &> /dev/null; then
        echo "$event" | python3 -m json.tool > /dev/null
        [ $? -eq 0 ]
    fi
}

