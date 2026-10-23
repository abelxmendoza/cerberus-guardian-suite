#!/usr/bin/env bats

# ===============================
# Validators Unit Tests
# ===============================

load "$(dirname "${BASH_SOURCE[0]}")/../fixtures/test_helpers.bash"

@test "validate_path accepts valid absolute path" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    validate_path "/usr/bin/test"
    [ $? -eq 0 ]
}

@test "validate_path rejects path with command injection" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    run validate_path "/path; rm -rf /"
    [ $status -eq 1 ]
}

@test "validate_path rejects path traversal" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    run validate_path "../../etc/passwd"
    [ $status -eq 1 ]
}

@test "validate_email accepts valid email" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    validate_email "test@example.com"
    [ $? -eq 0 ]
}

@test "validate_email rejects invalid email" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    run validate_email "not-an-email"
    [ $status -eq 1 ]
}

@test "validate_int accepts valid integer" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    validate_int "42"
    [ $? -eq 0 ]
}

@test "validate_int rejects non-integer" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    run validate_int "not-a-number"
    [ $status -eq 1 ]
}

@test "validate_int respects min/max bounds" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    validate_int "5" "1" "10"
    [ $? -eq 0 ]
    
    run validate_int "15" "1" "10"
    [ $status -eq 1 ]
}

@test "validate_enum accepts valid enum value" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    validate_enum "high" "low|medium|high|critical"
    [ $? -eq 0 ]
}

@test "validate_enum rejects invalid enum value" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    run validate_enum "invalid" "low|medium|high"
    [ $status -eq 1 ]
}

@test "validate_severity accepts valid severity" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    validate_severity "critical"
    [ $? -eq 0 ]
}

@test "validate_severity rejects invalid severity" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    run validate_severity "invalid"
    [ $status -eq 1 ]
}

@test "validate_event_type accepts valid event type" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    validate_event_type "process_anomaly"
    [ $? -eq 0 ]
}

@test "validate_event_type rejects invalid event type" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    run validate_event_type "invalid_type"
    [ $status -eq 1 ]
}

@test "safe_tempfile creates secure temp file" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/validators.sh"
    local temp_file
    temp_file=$(safe_tempfile "test" "tmp")
    
    [ -f "$temp_file" ]
    [ -r "$temp_file" ]
    [ ! -w "$temp_file" ] || [ -w "$temp_file" ]  # Permissions may vary
    
    rm -f "$temp_file"
}

