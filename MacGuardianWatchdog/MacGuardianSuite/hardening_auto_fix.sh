#!/bin/bash

# ===============================
# Hardening Auto-Fix
# Automatically fixes hardening assessment failures
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true

DRY_RUN="${DRY_RUN:-true}"
AUTO_CONFIRM="${AUTO_CONFIRM:-false}"

# Fix Remote Login (disable SSH)
fix_remote_login() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would disable Remote Login (SSH)"
        echo "   Command: sudo systemsetup -setremotelogin off"
        return 0
    fi
    
    if [ "$AUTO_CONFIRM" = true ] || confirm_action "Disable Remote Login (SSH)? This will prevent remote access." "n"; then
        if sudo systemsetup -setremotelogin off 2>/dev/null; then
            success "Remote Login disabled"
            return 0
        else
            warning "Could not disable Remote Login. You may need to do this manually: System Settings > General > Sharing > Remote Login"
            return 1
        fi
    fi
    return 0
}

# Fix Screen Saver Password
fix_screen_saver_password() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable Screen Saver Password"
        echo "   Command: defaults write com.apple.screensaver askForPassword -int 1"
        return 0
    fi
    
    if [ "$AUTO_CONFIRM" = true ] || confirm_action "Enable Screen Saver Password? This requires a password when waking from sleep." "y"; then
        if defaults write com.apple.screensaver askForPassword -int 1 2>/dev/null && \
           defaults write com.apple.screensaver askForPasswordDelay -int 0 2>/dev/null; then
            success "Screen Saver Password enabled"
            return 0
        else
            warning "Could not enable Screen Saver Password. You may need to do this manually: System Settings > Lock Screen"
            return 1
        fi
    fi
    return 0
}

# Fix Firewall Stealth Mode
fix_firewall_stealth() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable Firewall Stealth Mode"
        echo "   Command: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on"
        return 0
    fi
    
    if [ "$AUTO_CONFIRM" = true ] || confirm_action "Enable Firewall Stealth Mode? This makes your Mac less visible on networks." "y"; then
        if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on 2>/dev/null; then
            success "Firewall Stealth Mode enabled"
            return 0
        else
            warning "Could not enable Firewall Stealth Mode. You may need to do this manually: System Settings > Network > Firewall > Options"
            return 1
        fi
    fi
    return 0
}

# Fix AirDrop (restrict to contacts)
fix_airdrop_restriction() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would restrict AirDrop to Contacts Only"
        echo "   Note: This must be done manually in Finder > AirDrop"
        return 0
    fi
    
    warning "AirDrop restriction must be set manually:"
    echo "   1. Open Finder"
    echo "   2. Click AirDrop in sidebar"
    echo "   3. Select 'Contacts Only' at bottom"
    return 0
}

# Fix Home Directory Permissions
fix_home_directory_permissions() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would secure home directory permissions"
        echo "   Command: chmod 700 $HOME"
        return 0
    fi
    
    if [ "$AUTO_CONFIRM" = true ] || confirm_action "Secure home directory permissions (chmod 700)? This restricts access to your home folder." "y"; then
        if chmod 700 "$HOME" 2>/dev/null; then
            success "Home directory permissions secured"
            return 0
        else
            warning "Could not secure home directory permissions"
            return 1
        fi
    fi
    return 0
}

# Fix World-Writable Files
fix_world_writable_files() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would fix world-writable files in home directory"
        echo "   Command: find $HOME -type f -perm -002 -exec chmod o-w {} \\;"
        return 0
    fi
    
    local world_writable=$(find "$HOME" -maxdepth 3 -type f -perm -002 -not -path "*/Library/Caches/*" -not -path "*/Library/Logs/*" -not -path "*/.git/*" 2>/dev/null | head -10)
    
    if [ -z "$world_writable" ]; then
        success "No world-writable files found"
        return 0
    fi
    
    if [ "$AUTO_CONFIRM" = true ] || confirm_action "Fix world-writable files? This removes write permissions for others." "y"; then
        if find "$HOME" -maxdepth 3 -type f -perm -002 -not -path "*/Library/Caches/*" -not -path "*/Library/Logs/*" -not -path "*/.git/*" -exec chmod o-w {} \; 2>/dev/null; then
            success "World-writable files fixed"
            return 0
        else
            warning "Could not fix all world-writable files"
            return 1
        fi
    fi
    return 0
}

# Fix Time Machine (enable)
fix_time_machine() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable Time Machine backup"
        echo "   Note: This requires manual setup: System Settings > General > Time Machine"
        return 0
    fi
    
    warning "Time Machine must be enabled manually:"
    echo "   1. System Settings > General > Time Machine"
    echo "   2. Click 'Add Backup Disk' or 'Select Disk'"
    echo "   3. Choose your backup disk"
    return 0
}

# Fix App Store Auto-Update
fix_app_store_auto_update() {
    if [ "$DRY_RUN" = true ]; then
        echo "ℹ️  Would enable App Store auto-updates"
        echo "   Command: defaults write com.apple.commerce AutoUpdate -bool true"
        return 0
    fi
    
    if [ "$AUTO_CONFIRM" = true ] || confirm_action "Enable App Store auto-updates?" "y"; then
        if defaults write com.apple.commerce AutoUpdate -bool true 2>/dev/null; then
            success "App Store auto-updates enabled"
            return 0
        else
            warning "Could not enable App Store auto-updates. You may need to do this manually: App Store > Preferences"
            return 1
        fi
    fi
    return 0
}

# Main function
main() {
    local fix_type="${1:-all}"
    
    if [ "$DRY_RUN" = true ]; then
        echo "${yellow}⚠️  DRY-RUN MODE: No changes will be made${normal}"
        echo "${yellow}   Use --execute to actually perform fixes${normal}"
        echo ""
    fi
    
    case "$fix_type" in
        remote-login)
            fix_remote_login
            ;;
        screen-saver)
            fix_screen_saver_password
            ;;
        firewall-stealth)
            fix_firewall_stealth
            ;;
        airdrop)
            fix_airdrop_restriction
            ;;
        home-permissions)
            fix_home_directory_permissions
            ;;
        world-writable)
            fix_world_writable_files
            ;;
        time-machine)
            fix_time_machine
            ;;
        app-store)
            fix_app_store_auto_update
            ;;
        all)
            echo "${bold}🔧 Fixing Hardening Issues${normal}"
            echo "=========================================="
            echo ""
            fix_remote_login
            echo ""
            fix_screen_saver_password
            echo ""
            fix_firewall_stealth
            echo ""
            fix_airdrop_restriction
            echo ""
            fix_home_directory_permissions
            echo ""
            fix_world_writable_files
            echo ""
            fix_time_machine
            echo ""
            fix_app_store_auto_update
            ;;
        *)
            echo "Usage: $0 [remote-login|screen-saver|firewall-stealth|airdrop|home-permissions|world-writable|time-machine|app-store|all]"
            echo ""
            echo "Options:"
            echo "  --execute    Actually perform fixes (default is dry-run)"
            echo "  --yes        Auto-confirm all fixes"
            ;;
    esac
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

