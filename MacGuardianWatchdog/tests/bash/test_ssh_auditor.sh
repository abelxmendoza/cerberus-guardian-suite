#!/bin/bash

# ===============================
# SSH Auditor Test Suite
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUDITOR_SCRIPT="$PROJECT_ROOT/MacGuardianSuite/auditors/ssh_auditor.sh"
TEST_DIR="$SCRIPT_DIR/fixtures/ssh"

# Test colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_baseline_creation() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Test: Baseline creation... "
    
    if bash "$AUDITOR_SCRIPT" baseline > /dev/null 2>&1; then
        if [ -f "$HOME/.macguardian/baselines/ssh_fingerprints.json" ]; then
            echo -e "${GREEN}PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi
    
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

test_audit_execution() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Test: Audit execution... "
    
    if bash "$AUDITOR_SCRIPT" audit > /dev/null 2>&1; then
        # Check if audit output exists
        local audit_files=$(find "$HOME/.macguardian/audits" -name "ssh_audit_*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$audit_files" -gt 0 ]; then
            echo -e "${GREEN}PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi
    
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

test_json_output() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Test: JSON output validity... "
    
    local latest_audit=$(find "$HOME/.macguardian/audits" -name "ssh_audit_*.json" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -n "$latest_audit" ] && [ -f "$latest_audit" ]; then
        # Check if JSON is valid (simple check)
        if grep -q '"timestamp"' "$latest_audit" && grep -q '"audit_type"' "$latest_audit"; then
            echo -e "${GREEN}PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    fi
    
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

# Run tests
echo "=========================================="
echo "SSH Auditor Test Suite"
echo "=========================================="
echo ""

test_baseline_creation
test_audit_execution
test_json_output

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi

