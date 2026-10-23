#!/usr/bin/env bats

# ===============================
# Hashing Module Unit Tests
# ===============================

load "$(dirname "${BASH_SOURCE[0]}")/../fixtures/test_helpers.bash"

@test "compute_file_hash generates SHA256 hash" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/hashing.sh"
    
    # Create test file
    local test_file="$TEST_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    local hash
    hash=$(compute_file_hash "$test_file" "sha256")
    
    [ -n "$hash" ]
    [ ${#hash} -eq 64 ]  # SHA256 produces 64 hex characters
}

@test "compute_file_hash generates MD5 hash" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/hashing.sh"
    
    local test_file="$TEST_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    local hash
    hash=$(compute_file_hash "$test_file" "md5")
    
    [ -n "$hash" ]
}

@test "verify_file_hash validates correct hash" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/hashing.sh"
    
    local test_file="$TEST_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    local expected_hash
    expected_hash=$(compute_file_hash "$test_file" "sha256")
    
    verify_file_hash "$test_file" "$expected_hash" "sha256"
    [ $? -eq 0 ]
}

@test "verify_file_hash rejects incorrect hash" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/hashing.sh"
    
    local test_file="$TEST_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    local wrong_hash="0000000000000000000000000000000000000000000000000000000000000000"
    
    run verify_file_hash "$test_file" "$wrong_hash" "sha256"
    [ $status -eq 1 ]
}

@test "compute_directory_hash generates hash for directory" {
    source "$PROJECT_ROOT/MacGuardianSuite/core/hashing.sh"
    
    local test_dir="$TEST_DIR/test_dir"
    mkdir -p "$test_dir"
    echo "file1" > "$test_dir/file1.txt"
    echo "file2" > "$test_dir/file2.txt"
    
    local hash
    hash=$(compute_directory_hash "$test_dir" "sha256")
    
    [ -n "$hash" ]
}

