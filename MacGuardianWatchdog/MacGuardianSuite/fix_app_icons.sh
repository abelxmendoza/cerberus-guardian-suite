#!/bin/bash

# ===============================
# 🎨 Fix App Icons v1.0
# Clear macOS icon cache and fix app icons
# ===============================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true

# Color support
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
yellow=$(tput setaf 3 2>/dev/null || echo "")
cyan=$(tput setaf 6 2>/dev/null || echo "")

QUIET=false
VERBOSE=false
DRY_RUN=false
CLEAR_SYSTEM_CACHE=false
CLEAR_USER_CACHE=true
RESTART_DOCK=true
FIX_SPECIFIC_APP=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --system-cache)
            CLEAR_SYSTEM_CACHE=true
            shift
            ;;
        --no-user-cache)
            CLEAR_USER_CACHE=false
            shift
            ;;
        --no-dock-restart)
            RESTART_DOCK=false
            shift
            ;;
        --app)
            FIX_SPECIFIC_APP="$2"
            # Remove surrounding quotes if present
            FIX_SPECIFIC_APP="${FIX_SPECIFIC_APP#\'}"
            FIX_SPECIFIC_APP="${FIX_SPECIFIC_APP%\'}"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --system-cache      Also clear system-wide icon cache (requires sudo)"
            echo "  --no-user-cache     Don't clear user icon cache"
            echo "  --no-dock-restart   Don't restart Dock after clearing cache"
            echo "  --app PATH          Fix icon for specific app bundle"
            echo "  --dry-run           Preview what would be done"
            echo "  -q, --quiet         Suppress output"
            echo "  -v, --verbose       Verbose output"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

info() {
    if [ "$QUIET" != true ]; then
        echo "${cyan}ℹ️  $1${normal}"
    fi
}

success() {
    if [ "$QUIET" != true ]; then
        echo "${green}✅ $1${normal}"
    fi
}

warning() {
    if [ "$QUIET" != true ]; then
        echo "${yellow}⚠️  $1${normal}"
    fi
}

# Clear user icon cache
clear_user_icon_cache() {
    local cache_dirs=(
        "$HOME/Library/Caches/com.apple.iconservices"
        "$HOME/Library/Caches/com.apple.iconservices.store"
    )
    
    local cleared=0
    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "$cache_dir" ] || [ -f "$cache_dir" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would remove: $cache_dir"
            else
                rm -rf "$cache_dir" 2>/dev/null || true
                cleared=$((cleared + 1))
                if [ "$VERBOSE" = true ]; then
                    success "Removed: $cache_dir"
                fi
            fi
        fi
    done
    
    if [ "$DRY_RUN" != true ] && [ $cleared -gt 0 ]; then
        success "Cleared user icon cache ($cleared location(s))"
    fi
    return 0
}

# Clear system icon cache (requires sudo)
clear_system_icon_cache() {
    if [ "$DRY_RUN" = true ]; then
        info "Would clear system icon cache (requires sudo)"
        return 0
    fi
    
    local system_cache="/Library/Caches/com.apple.iconservices.store"
    
    if [ -d "$system_cache" ] || [ -f "$system_cache" ]; then
        if sudo rm -rf "$system_cache" 2>/dev/null; then
            success "Cleared system icon cache"
        else
            warning "Failed to clear system cache (may require password)"
            return 1
        fi
    else
        info "System icon cache not found (may already be cleared)"
    fi
    return 0
}

# Fix icon for specific app
fix_app_icon() {
    local app_path="$1"
    
    if [ ! -d "$app_path" ]; then
        warning "App bundle not found: $app_path"
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        info "Would fix icon for: $app_path"
        return 0
    fi
    
    local icon_file=""
    local info_plist="$app_path/Contents/Info.plist"
    
    # Find icon file
    if [ -f "$info_plist" ]; then
        local icon_name=$(plutil -extract CFBundleIconFile raw "$info_plist" 2>/dev/null || echo "")
        if [ -n "$icon_name" ]; then
            # Remove .icns extension if present
            icon_name="${icon_name%.icns}"
            icon_file="$app_path/Contents/Resources/${icon_name}.icns"
        fi
    fi
    
    # Try common icon names
    if [ ! -f "$icon_file" ]; then
        for possible_icon in "$app_path/Contents/Resources"/*.icns; do
            if [ -f "$possible_icon" ]; then
                icon_file="$possible_icon"
                break
            fi
        done
    fi
    
    if [ -f "$icon_file" ]; then
        # Use AppleScript to set icon (most reliable)
        osascript <<EOF 2>/dev/null || true
tell application "Finder"
    set theApp to POSIX file "$app_path" as alias
    set iconFile to POSIX file "$icon_file" as alias
    set the icon of theApp to iconFile
end tell
EOF
        
        # Update timestamps
        touch "$app_path"
        touch "$info_plist"
        touch "$icon_file"
        
        success "Fixed icon for: $(basename "$app_path")"
        return 0
    else
        warning "No icon file found for: $(basename "$app_path")"
        return 1
    fi
}

# Restart Dock
restart_dock() {
    if [ "$DRY_RUN" = true ]; then
        info "Would restart Dock"
        return 0
    fi
    
    if killall Dock 2>/dev/null; then
        success "Dock restarted"
        sleep 1
    else
        warning "Failed to restart Dock (may not be running)"
    fi
    return 0
}

# Main execution
main() {
    if [ "$QUIET" != true ]; then
        echo "${bold}🎨 Fix App Icons Tool${normal}"
        echo "================================"
        echo ""
        
        if [ "$DRY_RUN" = true ]; then
            warning "DRY RUN MODE - No changes will be made"
            echo ""
        fi
    fi
    
    # Clear user cache
    if [ "$CLEAR_USER_CACHE" = true ]; then
        clear_user_icon_cache
    fi
    
    # Clear system cache
    if [ "$CLEAR_SYSTEM_CACHE" = true ]; then
        clear_system_icon_cache
    fi
    
    # Fix specific app if requested
    if [ -n "$FIX_SPECIFIC_APP" ]; then
        fix_app_icon "$FIX_SPECIFIC_APP"
    fi
    
    # Restart Dock
    if [ "$RESTART_DOCK" = true ]; then
        restart_dock
    fi
    
    if [ "$QUIET" != true ]; then
        echo ""
        if [ "$DRY_RUN" = true ]; then
            info "Dry run complete. Use without --dry-run to actually fix icons."
        else
            success "Icon cache cleared!"
            info "App icons should refresh automatically. If not, restart your Mac."
        fi
    fi
    
    return 0
}

main "$@"

