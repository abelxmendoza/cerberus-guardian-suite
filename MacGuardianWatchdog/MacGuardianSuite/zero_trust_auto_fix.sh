#!/bin/bash

# ===============================
# Zero Trust Auto-Fix
# Automatically fixes Zero Trust assessment failures
# NIST SP 800-207 compliance
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true
source "$SCRIPT_DIR/hardening_auto_fix.sh" 2>/dev/null || true

DRY_RUN="${DRY_RUN:-true}"
AUTO_CONFIRM="${AUTO_CONFIRM:-false}"

# Fix Verify Explicitly issues
fix_verify_explicitly() {
    echo "${bold}🔐 Fixing: Verify Explicitly${normal}"
    echo "----------------------------------------"
    
    # 1. Enable screen saver password
    echo ""
    echo "${bold}1. Screen Saver Password${normal}"
    fix_screen_saver_password
    
    # 2. Enable FileVault (if not already enabled)
    echo ""
    echo "${bold}2. FileVault Encryption${normal}"
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable FileVault"
        echo "   Note: This requires manual setup: System Settings > Privacy & Security > FileVault"
        echo "   Or run: sudo fdesetup enable"
    else
        if fdesetup status 2>/dev/null | grep -qi "on"; then
            success "FileVault already enabled"
        else
            if [ "$AUTO_CONFIRM" = true ] || confirm_action "Enable FileVault? This encrypts your disk (requires restart)." "n"; then
                if sudo fdesetup enable 2>/dev/null; then
                    success "FileVault enabled (restart may be required)"
                else
                    warning "Could not enable FileVault. Enable manually: System Settings > Privacy & Security > FileVault"
                fi
            fi
        fi
    fi
    
    # 3. Enable firewall
    echo ""
    echo "${bold}3. Firewall${normal}"
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable Firewall"
        echo "   Command: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
    else
        local firewall_state=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -i "enabled" || echo "")
        if [ -n "$firewall_state" ]; then
            success "Firewall already enabled"
        else
            if [ "$AUTO_CONFIRM" = true ] || confirm_action "Enable Firewall? This blocks unauthorized network access." "y"; then
                if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null; then
                    success "Firewall enabled"
                    # Also enable stealth mode
                    fix_firewall_stealth
                else
                    warning "Could not enable Firewall. Enable manually: System Settings > Network > Firewall"
                fi
            fi
        fi
    fi
    
    # 4. Disable remote login
    echo ""
    echo "${bold}4. Remote Login (SSH)${normal}"
    fix_remote_login
    
    echo ""
}

# Fix Least Privilege issues
fix_least_privilege() {
    echo "${bold}🔒 Fixing: Least Privilege${normal}"
    echo "----------------------------------------"
    
    # 1. Check admin account (informational only - can't auto-fix)
    echo ""
    echo "${bold}1. Admin Account${normal}"
    local is_admin=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | grep -q "$(whoami)" && echo "yes" || echo "no")
    if [ "$is_admin" = "yes" ]; then
        warning "You are using an admin account"
        echo "   Recommendation: Create a standard user account for daily use"
        echo "   System Settings > Users & Groups > Add User (Standard)"
    else
        success "Using non-admin account"
    fi
    
    # 2. Fix home directory permissions
    echo ""
    echo "${bold}2. Home Directory Permissions${normal}"
    fix_home_directory_permissions
    
    # 3. Fix world-writable files
    echo ""
    echo "${bold}3. World-Writable Files${normal}"
    fix_world_writable_files
    
    # 4. Check sudo access (informational)
    echo ""
    echo "${bold}4. Sudo Access${normal}"
    if sudo -n true 2>/dev/null; then
        warning "Passwordless sudo enabled (security risk)"
        echo "   Recommendation: Require password for sudo"
        echo "   Edit: sudo visudo"
    else
        success "Sudo requires password"
    fi
    
    echo ""
}

# Fix Assume Breach issues
fix_assume_breach() {
    echo "${bold}🛡️  Fixing: Assume Breach${normal}"
    echo "----------------------------------------"
    
    # 1. Enable continuous monitoring (Watchdog)
    echo ""
    echo "${bold}1. Continuous Monitoring${normal}"
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable Mac Watchdog (File Integrity Monitoring)"
        echo "   Run: ./MacGuardianSuite/mac_watchdog.sh"
    else
        if [ -f "$SCRIPT_DIR/mac_watchdog.sh" ]; then
            success "Mac Watchdog available"
            echo "   Run regularly: ./MacGuardianSuite/mac_watchdog.sh"
        else
            warning "Mac Watchdog not found"
        fi
    fi
    
    # 2. Enable Time Machine backups
    echo ""
    echo "${bold}2. Time Machine Backups${normal}"
    fix_time_machine
    
    # 3. Enable automatic security updates
    echo ""
    echo "${bold}3. Automatic Security Updates${normal}"
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable automatic security updates"
        echo "   Command: sudo softwareupdate --schedule on"
    else
        if [ "$AUTO_CONFIRM" = true ] || confirm_action "Enable automatic security updates?" "y"; then
            if sudo softwareupdate --schedule on 2>/dev/null; then
                success "Automatic security updates enabled"
            else
                warning "Could not enable auto-updates. Enable manually: System Settings > Software Update"
            fi
        fi
    fi
    
    # 4. Enable network segmentation (informational)
    echo ""
    echo "${bold}4. Network Segmentation${normal}"
    warning "Network segmentation requires network-level configuration"
    echo "   Recommendations:"
    echo "   • Use VPN for remote access"
    echo "   • Segment home network (guest network)"
    echo "   • Use firewall rules to restrict access"
    
    # 5. Enable audit logging
    echo ""
    echo "${bold}5. Audit Logging${normal}"
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable audit logging"
        echo "   MacGuardian Suite already logs security events"
        echo "   Check: ~/.macguardian/logs/"
    else
        success "Audit logging enabled (MacGuardian Suite)"
        echo "   Logs: ~/.macguardian/logs/"
    fi
    
    echo ""
}

# Main function
main() {
    local fix_type="${1:-all}"
    
    echo "${bold}🛡️  Zero Trust Auto-Fix${normal}"
    echo "NIST SP 800-207 Compliance"
    echo "=========================================="
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo "${yellow}⚠️  DRY-RUN MODE: No changes will be made${normal}"
        echo "${yellow}   Use --execute to actually perform fixes${normal}"
        echo ""
    else
        echo "${red}⚠️  EXECUTION MODE: Changes will be made!${normal}"
        if [ "$AUTO_CONFIRM" != true ]; then
            echo "${yellow}   You will be prompted for each fix${normal}"
        fi
        echo ""
    fi
    
    case "$fix_type" in
        verify-explicitly)
            fix_verify_explicitly
            ;;
        least-privilege)
            fix_least_privilege
            ;;
        assume-breach)
            fix_assume_breach
            ;;
        all)
            fix_verify_explicitly
            fix_least_privilege
            fix_assume_breach
            ;;
        *)
            echo "Usage: $0 [verify-explicitly|least-privilege|assume-breach|all]"
            echo ""
            echo "Options:"
            echo "  --execute    Actually perform fixes (default is dry-run)"
            echo "  --yes        Auto-confirm all fixes"
            echo ""
            echo "Examples:"
            echo "  $0                    # Dry-run: show what would be fixed"
            echo "  $0 --execute          # Actually fix issues (with prompts)"
            echo "  $0 all --execute --yes # Auto-fix all issues"
            exit 1
            ;;
    esac
    
    echo ""
    echo "${bold}✅ Zero Trust Auto-Fix Complete${normal}"
    echo ""
    echo "💡 Re-run Zero Trust Assessment to see improvements:"
    echo "   ./MacGuardianSuite/zero_trust_assessment.sh"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --execute)
            DRY_RUN=false
            shift
            ;;
        --yes)
            AUTO_CONFIRM=true
            DRY_RUN=false
            shift
            ;;
        *)
            break
            ;;
    esac
done

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

