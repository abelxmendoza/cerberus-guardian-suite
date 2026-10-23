#!/bin/bash

# ===============================
# Zero Trust Architecture Assessment
# NIST SP 800-207 Zero Trust principles
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true

# Zero Trust Principles
# 1. Verify Explicitly
# 2. Use Least Privilege
# 3. Assume Breach

check_verify_explicitly() {
    local score=0
    local max=5
    
    echo "${bold}1. Verify Explicitly${normal}"
    echo "----------------------------------------"
    
    # Check authentication requirements
    if [ -f /Library/Preferences/com.apple.loginwindow.plist ]; then
        local auto_login=$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || echo "")
        if [ -z "$auto_login" ]; then
            success "Auto-login disabled (requires authentication)"
            score=$((score + 1))
        else
            warning "Auto-login enabled (bypasses authentication)"
        fi
    else
        success "Auto-login disabled"
        score=$((score + 1))
    fi
    
    # Check screen saver password
    local screen_saver_pw=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")
    if [ "$screen_saver_pw" = "1" ]; then
        success "Screen saver password required"
        score=$((score + 1))
    else
        warning "Screen saver password not required"
    fi
    
    # Check FileVault (encryption at rest)
    if fdesetup status 2>/dev/null | grep -qi "on"; then
        success "FileVault enabled (data encrypted at rest)"
        score=$((score + 1))
    else
        warning "FileVault disabled"
    fi
    
    # Check firewall (network verification)
    local firewall_status=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "0")
    if [ "$firewall_status" = "2" ] || echo "$firewall_status" | grep -qi "enabled"; then
        success "Firewall enabled (network access control)"
        score=$((score + 1))
    else
        warning "Firewall disabled"
    fi
    
    # Check remote login (SSH)
    if systemsetup -getremotelogin 2>/dev/null | grep -qi "off"; then
        success "Remote login disabled (no unverified access)"
        score=$((score + 1))
    else
        warning "Remote login enabled"
    fi
    
    echo "Score: $score/$max"
    echo ""
    echo "$score"
}

check_least_privilege() {
    local score=0
    local max=5
    
    echo "${bold}2. Use Least Privilege${normal}"
    echo "----------------------------------------"
    
    # Check user account type
    local is_admin=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | grep -q "$(whoami)" && echo "yes" || echo "no")
    if [ "$is_admin" = "no" ]; then
        success "Non-admin account (least privilege)"
        score=$((score + 1))
    else
        warning "Admin account (elevated privileges)"
    fi
    
    # Check home directory permissions
    local home_perms=$(stat -f "%OLp" "$HOME" 2>/dev/null || echo "755")
    if [ "$home_perms" = "700" ]; then
        success "Home directory restricted (700)"
        score=$((score + 1))
    else
        warning "Home directory permissions: $home_perms (should be 700)"
    fi
    
    # Check world-writable files
    local world_writable=$(find "$HOME" -maxdepth 3 -type f -perm -002 -not -path "*/Library/Caches/*" -not -path "*/Library/Logs/*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$world_writable" -eq 0 ]; then
        success "No world-writable files"
        score=$((score + 1))
    else
        warning "$world_writable world-writable file(s) found"
    fi
    
    # Check sudo access
    if sudo -n true 2>/dev/null; then
        warning "Passwordless sudo enabled (reduces least privilege)"
    else
        success "Sudo requires authentication"
        score=$((score + 1))
    fi
    
    # Check application permissions
    local app_perms=$(find /Applications -maxdepth 1 -type d -perm -002 2>/dev/null | wc -l | tr -d ' ')
    if [ "$app_perms" -eq 0 ]; then
        success "Application permissions restricted"
        score=$((score + 1))
    else
        warning "$app_perms application(s) with world-writable permissions"
    fi
    
    echo "Score: $score/$max"
    echo ""
    echo "$score"
}

check_assume_breach() {
    local score=0
    local max=5
    
    echo "${bold}3. Assume Breach${normal}"
    echo "----------------------------------------"
    
    # Check continuous monitoring
    if [ -f "$HOME/.macguardian/blueteam/results_*.txt" ] || [ -f "$HOME/.mac_watchdog_baseline.txt" ]; then
        success "Continuous monitoring enabled (Watchdog/Blue Team)"
        score=$((score + 1))
    else
        warning "No continuous monitoring detected"
    fi
    
    # Check logging
    if [ -d "$HOME/.macguardian/logs" ] && [ -n "$(ls -A $HOME/.macguardian/logs 2>/dev/null)" ]; then
        success "Security logging enabled"
        score=$((score + 1))
    else
        warning "Limited security logging"
    fi
    
    # Check network segmentation (firewall)
    local firewall_status=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "0")
    if [ "$firewall_status" = "2" ] || echo "$firewall_status" | grep -qi "enabled"; then
        success "Network segmentation (firewall enabled)"
        score=$((score + 1))
    else
        warning "No network segmentation"
    fi
    
    # Check encryption (assume data can be accessed)
    if fdesetup status 2>/dev/null | grep -qi "on"; then
        success "Data encrypted (protected if breached)"
        score=$((score + 1))
    else
        warning "Data not encrypted"
    fi
    
    # Check backup (assume data can be lost)
    if tmutil status 2>/dev/null | grep -qi "Running = 1"; then
        success "Backup enabled (data recovery if breached)"
        score=$((score + 1))
    else
        warning "No backup detected"
    fi
    
    echo "Score: $score/$max"
    echo ""
    echo "$score"
}

# Main assessment
main() {
    echo "${bold}🛡️  Zero Trust Architecture Assessment${normal}"
    echo "NIST SP 800-207 Zero Trust Principles"
    echo "=========================================="
    echo ""
    
    local verify_score=$(check_verify_explicitly | tail -1)
    local privilege_score=$(check_least_privilege | tail -1)
    local breach_score=$(check_assume_breach | tail -1)
    
    local total_score=$((verify_score + privilege_score + breach_score))
    local max_score=15
    local percentage=$((total_score * 100 / max_score))
    
    echo ""
    echo "${bold}📊 Zero Trust Assessment Results${normal}"
    echo "=========================================="
    echo ""
    echo "Verify Explicitly: $verify_score/5"
    echo "Least Privilege: $privilege_score/5"
    echo "Assume Breach: $breach_score/5"
    echo ""
    echo "Total Score: $total_score/$max_score ($percentage%)"
    echo ""
    
    if [ $percentage -ge 80 ]; then
        success "🛡️  Zero Trust: EXCELLENT"
        echo "Your system follows Zero Trust principles well."
    elif [ $percentage -ge 60 ]; then
        warning "⚠️  Zero Trust: GOOD"
        echo "Your system has good Zero Trust coverage, but improvements recommended."
    else
        warning "⚠️  Zero Trust: NEEDS IMPROVEMENT"
        echo "Your system needs significant improvements to meet Zero Trust principles."
    fi
    
    echo ""
    echo "💡 Recommendations:"
    echo "  • Enable FileVault for encryption at rest"
    echo "  • Use non-admin account for daily use"
    echo "  • Enable firewall and restrict network access"
    echo "  • Enable continuous monitoring (Watchdog)"
    echo "  • Enable Time Machine backups"
    echo ""
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

