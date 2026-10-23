#!/bin/bash

# ===============================
# Debug Helper & Enhanced Error Messages
# Enterprise-level debugging and diagnostics
# ===============================

# Enhanced error context
debug_error() {
    local error_msg="$1"
    local context="${2:-}"
    local suggestion="${3:-}"
    
    echo "${red}❌ ERROR: $error_msg${normal}" >&2
    
    if [ -n "$context" ]; then
        echo "${yellow}   Context: $context${normal}" >&2
    fi
    
    if [ -n "$suggestion" ]; then
        echo "${cyan}   💡 Suggestion: $suggestion${normal}" >&2
    fi
    
    # Debug information
    if [ "${DEBUG:-false}" = "true" ] || [ "${VERBOSE:-false}" = "true" ]; then
        echo "${blue}   Debug Info:${normal}" >&2
        echo "      Script: ${BASH_SOURCE[1]:-unknown}:${BASH_LINENO[0]:-0}" >&2
        echo "      Function: ${FUNCNAME[1]:-main}" >&2
        echo "      PID: $$" >&2
        echo "      User: $(whoami)" >&2
        echo "      Working Dir: $(pwd)" >&2
        if [ -n "${SCRIPT_DIR:-}" ]; then
            echo "      Script Dir: $SCRIPT_DIR" >&2
        fi
    fi
}

# System diagnostics
system_diagnostics() {
    echo "${bold}🔍 System Diagnostics${normal}"
    echo "----------------------------------------"
    
    echo "${cyan}System Information:${normal}"
    echo "  macOS Version: $(sw_vers -productVersion 2>/dev/null || echo "unknown")"
    echo "  Build: $(sw_vers -buildVersion 2>/dev/null || echo "unknown")"
    echo "  Hardware: $(sysctl -n hw.model 2>/dev/null || echo "unknown")"
    echo "  CPU Cores: $(sysctl -n hw.ncpu 2>/dev/null || echo "unknown")"
    echo "  Memory: $(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.2f GB", $1/1024/1024/1024}' || echo "unknown")"
    echo ""
    
    echo "${cyan}Security Status:${normal}"
    echo "  SIP: $(csrutil status 2>/dev/null | grep -q "enabled" && echo "✅ Enabled" || echo "❌ Disabled")"
    echo "  Gatekeeper: $(spctl --status 2>/dev/null | grep -q "enabled" && echo "✅ Enabled" || echo "❌ Disabled")"
    echo "  FileVault: $(fdesetup status 2>/dev/null | grep -q "On" && echo "✅ Enabled" || echo "❌ Disabled")"
    echo "  Firewall: $(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled" && echo "✅ Enabled" || echo "❌ Disabled")"
    echo ""
    
    echo "${cyan}Tool Availability:${normal}"
    for tool in brew python3 clamscan rkhunter osascript; do
        if command -v $tool &> /dev/null; then
            echo "  ✅ $tool: $(which $tool)"
        else
            echo "  ❌ $tool: Not found"
        fi
    done
    echo ""
    
    echo "${cyan}Permissions:${normal}"
    echo "  Script Directory: $(ls -ld "$SCRIPT_DIR" 2>/dev/null | awk '{print $1, $3, $4}')"
    echo "  Log Directory: $(ls -ld "$HOME/.macguardian" 2>/dev/null | awk '{print $1, $3, $4}' || echo "Not accessible")"
    echo ""
    
    echo "${cyan}Environment:${normal}"
    echo "  PATH: $PATH"
    echo "  SHELL: $SHELL"
    echo "  USER: $(whoami)"
    echo "  HOME: $HOME"
    echo ""
}

# Enhanced command execution with full debugging
debug_execute() {
    local description="$1"
    shift
    local cmd="$*"
    local start_time=$(date +%s)
    
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "${blue}🔧 Executing: $description${normal}"
        echo "${blue}   Command: $cmd${normal}"
        echo "${blue}   Started: $(date)${normal}"
    fi
    
    set +e
    eval "$cmd" 2>&1 | tee /tmp/macguardian_debug_$$.log
    local exit_code=$?
    set -e
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $exit_code -ne 0 ]; then
        debug_error "Command failed: $description" \
            "Exit code: $exit_code, Duration: ${duration}s" \
            "Check /tmp/macguardian_debug_$$.log for details"
        
        if [ "${DEBUG:-false}" = "true" ]; then
            echo "${yellow}   Last 10 lines of output:${normal}"
            tail -10 /tmp/macguardian_debug_$$.log 2>/dev/null || true
        fi
        
        return $exit_code
    else
        if [ "${DEBUG:-false}" = "true" ]; then
            echo "${green}   ✅ Completed in ${duration}s${normal}"
        fi
    fi
    
    rm -f /tmp/macguardian_debug_$$.log 2>/dev/null || true
    return 0
}

# Check prerequisites with detailed messages
check_prerequisites() {
    local missing=0
    
    echo "${bold}🔍 Checking Prerequisites...${normal}"
    echo "----------------------------------------"
    
    # Check Homebrew
    if ! command -v brew &> /dev/null; then
        debug_error "Homebrew not found" \
            "Homebrew is required for package management" \
            "Install from: https://brew.sh"
        missing=$((missing + 1))
    else
        echo "${green}✅ Homebrew: $(brew --version | head -1)${normal}"
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        debug_error "Python3 not found" \
            "Python3 is required for AI/ML features" \
            "Install with: brew install python3"
        missing=$((missing + 1))
    else
        echo "${green}✅ Python3: $(python3 --version)${normal}"
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        echo "${yellow}⚠️  Sudo access: May be required for some operations${normal}"
    else
        echo "${green}✅ Sudo access: Available${normal}"
    fi
    
    # Check disk space
    local available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    echo "${cyan}💾 Available disk space: $available_space${normal}"
    
    if [ $missing -gt 0 ]; then
        echo ""
        echo "${red}❌ $missing prerequisite(s) missing. Please install them first.${normal}"
        return 1
    fi
    
    echo ""
    echo "${green}✅ All prerequisites met!${normal}"
    return 0
}

# Enhanced logging with stack trace
log_with_stack() {
    local level="$1"
    shift
    local message="$*"
    
    log_message "$level" "$message"
    
    if [ "${DEBUG:-false}" = "true" ]; then
        echo "${blue}   Stack trace:${normal}" >&2
        local depth=${#FUNCNAME[@]}
        for ((i=1; i<depth; i++)); do
            echo "      ${FUNCNAME[$i]}() at ${BASH_SOURCE[$i+1]:-unknown}:${BASH_LINENO[$i]}" >&2
        done
    fi
}

