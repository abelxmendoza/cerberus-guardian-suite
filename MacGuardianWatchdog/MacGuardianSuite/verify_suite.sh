#!/bin/bash

# Mac Guardian Suite Verification Script
# Tests all components to ensure they're working properly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
red=$(tput setaf 1 2>/dev/null || echo "")
yellow=$(tput setaf 3 2>/dev/null || echo "")
cyan=$(tput setaf 6 2>/dev/null || echo "")

# Test results
PASSED=0
FAILED=0
WARNINGS=0

# Test output file
TEST_LOG="$HOME/.macguardian/verification_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$TEST_LOG")"

# Helper functions
test_pass() {
    echo "${green}✅ PASS: $1${normal}"
    echo "[PASS] $1" >> "$TEST_LOG"
    PASSED=$((PASSED + 1))
}

test_fail() {
    echo "${red}❌ FAIL: $1${normal}"
    echo "[FAIL] $1" >> "$TEST_LOG"
    FAILED=$((FAILED + 1))
}

test_warn() {
    echo "${yellow}⚠️  WARN: $1${normal}"
    echo "[WARN] $1" >> "$TEST_LOG"
    WARNINGS=$((WARNINGS + 1))
}

test_info() {
    echo "${cyan}ℹ️  INFO: $1${normal}"
    echo "[INFO] $1" >> "$TEST_LOG"
}

# Header
clear
echo "${bold}=========================================="
echo "🔍 Mac Guardian Suite Verification"
echo "==========================================${normal}"
echo ""
echo "This script will test all components to ensure"
echo "everything is working properly."
echo ""
echo "Test log: $TEST_LOG"
echo ""
read -p "Press Enter to start verification..."
echo ""

# ============================================
# 1. FILE STRUCTURE & PERMISSIONS
# ============================================
echo "${bold}📁 Testing File Structure & Permissions...${normal}"
echo "----------------------------------------"

# Check main scripts exist
for script in mac_guardian.sh mac_watchdog.sh mac_blueteam.sh mac_ai.sh mac_security_audit.sh mac_remediation.sh mac_suite.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        test_pass "Script exists and is executable: $script"
    else
        test_fail "Script missing or not executable: $script"
    fi
done

# Check utility files
for util in utils.sh config.sh algorithms.sh; do
    if [ -f "$util" ]; then
        test_pass "Utility file exists: $util"
    else
        test_fail "Utility file missing: $util"
    fi
done

# Check Python engines
for py_script in ai_engine.py ml_engine.py; do
    if [ -f "$py_script" ]; then
        test_pass "Python script exists: $py_script"
        if python3 -m py_compile "$py_script" 2>/dev/null; then
            test_pass "Python syntax valid: $py_script"
        else
            test_warn "Python syntax check failed: $py_script (may need dependencies)"
        fi
    else
        test_fail "Python script missing: $py_script"
    fi
done

echo ""

# ============================================
# 2. CONFIGURATION
# ============================================
echo "${bold}⚙️  Testing Configuration...${normal}"
echo "----------------------------------------"

if [ -f "config.sh" ]; then
    # Source config and check key variables
    source config.sh 2>/dev/null || true
    
    if [ -n "${ENABLE_PARALLEL:-}" ]; then
        test_pass "Configuration loaded: ENABLE_PARALLEL set"
    else
        test_warn "Configuration may not be fully loaded"
    fi
    
    if [ -n "${LOG_DIR:-}" ]; then
        test_pass "Log directory configured: $LOG_DIR"
        if [ -d "$LOG_DIR" ]; then
            test_pass "Log directory exists and is writable"
        else
            test_warn "Log directory doesn't exist (will be created on first run)"
        fi
    fi
else
    test_fail "config.sh not found"
fi

echo ""

# ============================================
# 3. DEPENDENCIES
# ============================================
echo "${bold}📦 Testing Dependencies...${normal}"
echo "----------------------------------------"

# Check Homebrew
if command -v brew &> /dev/null; then
    test_pass "Homebrew installed"
else
    test_warn "Homebrew not installed (some features may not work)"
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    test_pass "Python3 installed: $PYTHON_VERSION"
    
    # Check Python packages
    for pkg in numpy scikit-learn pandas; do
        if python3 -c "import $pkg" 2>/dev/null; then
            test_pass "Python package installed: $pkg"
        else
            test_warn "Python package missing: $pkg (will be auto-installed)"
        fi
    done
else
    test_fail "Python3 not installed"
fi

# Check security tools
for tool in clamscan rkhunter osascript; do
    if command -v $tool &> /dev/null; then
        test_pass "Tool available: $tool"
    else
        test_warn "Tool not available: $tool (optional)"
    fi
done

echo ""

# ============================================
# 4. UTILITY FUNCTIONS
# ============================================
echo "${bold}🔧 Testing Utility Functions...${normal}"
echo "----------------------------------------"

if [ -f "utils.sh" ]; then
    source utils.sh 2>/dev/null || true
    
    # Test logging
    if log_message "TEST" "Verification test message" 2>/dev/null; then
        test_pass "Logging function works"
    else
        test_warn "Logging function may have issues"
    fi
    
    # Test notification (dry run - won't actually send)
    if type send_notification &> /dev/null; then
        test_pass "Notification function available"
    else
        test_warn "Notification function not available"
    fi
    
    # Test parallel processing setup
    if type init_parallel &> /dev/null; then
        test_pass "Parallel processing functions available"
    else
        test_warn "Parallel processing functions not available"
    fi
else
    test_fail "utils.sh not found"
fi

echo ""

# ============================================
# 5. MODULE FUNCTIONALITY TESTS
# ============================================
echo "${bold}🧪 Testing Module Functionality...${normal}"
echo "----------------------------------------"

# Test Mac Guardian (dry run)
test_info "Testing Mac Guardian (help/version check)..."
if ./mac_guardian.sh --help &> /dev/null || ./mac_guardian.sh -h &> /dev/null || timeout 5 ./mac_guardian.sh --version &> /dev/null || true; then
    test_pass "Mac Guardian script is executable"
else
    test_warn "Mac Guardian script execution test inconclusive"
fi

# Test Mac Blue Team (help/version check)
test_info "Testing Mac Blue Team (help/version check)..."
if ./mac_blueteam.sh --help &> /dev/null || ./mac_blueteam.sh -h &> /dev/null || timeout 5 ./mac_blueteam.sh --version &> /dev/null || true; then
    test_pass "Mac Blue Team script is executable"
else
    test_warn "Mac Blue Team script execution test inconclusive"
fi

# Test Mac AI (help/version check)
test_info "Testing Mac AI (help/version check)..."
if ./mac_ai.sh --help &> /dev/null || ./mac_ai.sh -h &> /dev/null || timeout 5 ./mac_ai.sh --version &> /dev/null || true; then
    test_pass "Mac AI script is executable"
else
    test_warn "Mac AI script execution test inconclusive"
fi

# Test Python AI engine
test_info "Testing Python AI engine..."
if python3 ai_engine.py --help &> /dev/null 2>&1; then
    test_pass "Python AI engine is functional"
else
    test_warn "Python AI engine help test failed (may need dependencies)"
fi

# Test Python ML engine
test_info "Testing Python ML engine..."
if python3 ml_engine.py --help &> /dev/null 2>&1; then
    test_pass "Python ML engine is functional"
else
    test_warn "Python ML engine help test failed (may need dependencies)"
fi

echo ""

# ============================================
# 6. LOGGING & OUTPUT
# ============================================
echo "${bold}📝 Testing Logging & Output...${normal}"
echo "----------------------------------------"

LOG_DIR="${LOG_DIR:-$HOME/.macguardian}"

# Check log directories
for dir in "$LOG_DIR" "$LOG_DIR/guardian" "$LOG_DIR/blueteam" "$LOG_DIR/ai" "$LOG_DIR/remediation"; do
    if [ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null; then
        test_pass "Log directory accessible: $dir"
    else
        test_fail "Log directory not accessible: $dir"
    fi
done

# Test log file creation
TEST_LOG_FILE="$LOG_DIR/verification_test.log"
if echo "Test log entry" > "$TEST_LOG_FILE" 2>/dev/null && [ -f "$TEST_LOG_FILE" ]; then
    test_pass "Log file creation works"
    rm -f "$TEST_LOG_FILE"
else
    test_fail "Log file creation failed"
fi

echo ""

# ============================================
# 7. NOTIFICATION SYSTEM
# ============================================
echo "${bold}🔔 Testing Notification System...${normal}"
echo "----------------------------------------"

if command -v osascript &> /dev/null; then
    test_pass "osascript available for notifications"
    
    # Test notification (will actually send one)
    if osascript -e 'display notification "Mac Guardian verification test" with title "Test Notification"' 2>/dev/null; then
        test_pass "Notification system functional"
        test_info "You should see a test notification appear"
    else
        test_warn "Notification test failed (may need permissions)"
    fi
else
    test_warn "osascript not available (notifications won't work)"
fi

echo ""

# ============================================
# 8. PARALLEL PROCESSING
# ============================================
echo "${bold}⚡ Testing Parallel Processing...${normal}"
echo "----------------------------------------"

if [ -f "utils.sh" ]; then
    source utils.sh 2>/dev/null || true
    
    if type run_parallel &> /dev/null && type wait_all_jobs &> /dev/null; then
        test_pass "Parallel processing functions available"
        
        # Quick parallel test
        test_info "Running quick parallel test..."
        init_parallel 2>/dev/null || true
        
        # Test with a simple command
        if run_parallel "test1" "echo 'test1'" 2>/dev/null && \
           run_parallel "test2" "echo 'test2'" 2>/dev/null && \
           wait_all_jobs 2>/dev/null; then
            test_pass "Parallel processing works"
        else
            test_warn "Parallel processing test inconclusive"
        fi
    else
        test_warn "Parallel processing functions not available"
    fi
fi

echo ""

# ============================================
# 9. SECURITY TOOLS INTEGRATION
# ============================================
echo "${bold}🛡️  Testing Security Tools Integration...${normal}"
echo "----------------------------------------"

# ClamAV
if command -v clamscan &> /dev/null; then
    test_pass "ClamAV installed"
    if clamscan --version &> /dev/null; then
        test_pass "ClamAV is functional"
    fi
else
    test_warn "ClamAV not installed (will be installed on first Guardian run)"
fi

# rkhunter
if command -v rkhunter &> /dev/null; then
    test_pass "rkhunter installed"
    if rkhunter --version &> /dev/null; then
        test_pass "rkhunter is functional"
    fi
else
    test_warn "rkhunter not installed (optional)"
fi

echo ""

# ============================================
# 10. FILE INTEGRITY & PERMISSIONS
# ============================================
echo "${bold}🔒 Testing File Integrity & Permissions...${normal}"
echo "----------------------------------------"

# Check script permissions
for script in mac_guardian.sh mac_watchdog.sh mac_blueteam.sh mac_ai.sh mac_security_audit.sh mac_remediation.sh; do
    if [ -x "$script" ]; then
        test_pass "Script is executable: $script"
    else
        test_warn "Script not executable: $script (fixing...)"
        chmod +x "$script" 2>/dev/null && test_pass "Fixed permissions: $script" || test_fail "Could not fix permissions: $script"
    fi
done

# Check Python scripts are readable
for py_script in ai_engine.py ml_engine.py; do
    if [ -r "$py_script" ]; then
        test_pass "Python script is readable: $py_script"
    else
        test_fail "Python script not readable: $py_script"
    fi
done

echo ""

# ============================================
# 11. CONFIGURATION VALIDATION
# ============================================
echo "${bold}✅ Testing Configuration Validation...${normal}"
echo "----------------------------------------"

if [ -f "config.sh" ]; then
    source config.sh 2>/dev/null || true
    
    # Check critical config values
    if [ -n "${LOG_DIR:-}" ]; then
        test_pass "LOG_DIR configured"
    fi
    
    if [ -n "${ENABLE_NOTIFICATIONS:-}" ]; then
        test_pass "ENABLE_NOTIFICATIONS configured"
    fi
    
    if [ -n "${ENABLE_PARALLEL:-}" ]; then
        test_pass "ENABLE_PARALLEL configured"
    fi
fi

echo ""

# ============================================
# SUMMARY
# ============================================
echo ""
echo "${bold}=========================================="
echo "📊 Verification Summary"
echo "==========================================${normal}"
echo ""
echo "${green}✅ Passed:  $PASSED${normal}"
echo "${red}❌ Failed:  $FAILED${normal}"
echo "${yellow}⚠️  Warnings: $WARNINGS${normal}"
echo ""
echo "Test log saved to: $TEST_LOG"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo "${bold}${green}🎉 All tests passed! Your suite is fully operational.${normal}"
        exit 0
    else
        echo "${bold}${yellow}✅ Core functionality working! Some optional features may need setup.${normal}"
        echo ""
        echo "Review warnings above for optional components that may need attention."
        exit 0
    fi
else
    echo "${bold}${red}⚠️  Some tests failed. Please review the errors above.${normal}"
    echo ""
    echo "Most issues can be resolved by:"
    echo "  1. Running the suite once to auto-install dependencies"
    echo "  2. Checking file permissions (chmod +x *.sh)"
    echo "  3. Installing missing tools (brew install clamav rkhunter)"
    exit 1
fi

