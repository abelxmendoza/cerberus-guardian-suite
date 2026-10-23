#!/usr/bin/env bats

# ===============================
# System State Unit Tests
# ===============================

load "$(dirname "${BASH_SOURCE[0]}")/../fixtures/test_helpers.bash"

@test "check_sip_status returns status" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/system_state.sh"
    run get_sip_status_text
    [ $status -eq 0 ]
    [[ "$output" =~ ^(enabled|disabled)$ ]]
}

@test "check_ssv_status returns status" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/system_state.sh"
    run get_ssv_status_text
    [ $status -eq 0 ]
    [[ "$output" =~ ^(enabled|disabled)$ ]]
}

@test "get_system_state_summary outputs JSON" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/system_state.sh"
    run get_system_state_summary
    [ $status -eq 0 ]
    echo "$output" | grep -q '"sip"'
    echo "$output" | grep -q '"ssv"'
    echo "$output" | grep -q '"full_disk_access"'
}

@test "check_system_compatibility runs without errors" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/system_state.sh"
    run check_system_compatibility
    # May return 0 or 1 depending on system state
    [ $status -ge 0 ] && [ $status -le 1 ]
}

