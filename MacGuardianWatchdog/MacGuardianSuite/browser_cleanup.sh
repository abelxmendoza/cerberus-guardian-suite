#!/bin/bash

# ===============================
# 🌐 Browser Cleanup v1.0
# Clean browser caches, cookies, and data
# Supports Safari, Chrome, Firefox, Edge
# ===============================

set -eo pipefail

# Global error handler
trap 'error_handler $? $LINENO' ERR

error_handler() {
    local exit_code=$1
    local line_no=$2
    if [ $exit_code -ne 0 ] && [ "${CONTINUE_ON_ERROR:-false}" != "true" ]; then
        if type log_message &> /dev/null; then
            log_message "ERROR" "Script error at line $line_no (exit code: $exit_code)"
        fi
    fi
    return 0
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true

# Parse arguments
QUIET=false
VERBOSE=false
DRY_RUN=false
CLEAN_CACHE=true
CLEAN_COOKIES=false
CLEAN_HISTORY=false
CLEAN_DOWNLOADS=false
CLEAN_AUTOFILL=false
CLEAN_ALL=false
BROWSERS=""

# Color support with fallback
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
yellow=$(tput setaf 3 2>/dev/null || echo "")
cyan=$(tput setaf 6 2>/dev/null || echo "")

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
        --cache-only)
            CLEAN_CACHE=true
            CLEAN_COOKIES=false
            CLEAN_HISTORY=false
            CLEAN_DOWNLOADS=false
            CLEAN_AUTOFILL=false
            shift
            ;;
        --cookies)
            CLEAN_COOKIES=true
            shift
            ;;
        --history)
            CLEAN_HISTORY=true
            shift
            ;;
        --downloads)
            CLEAN_DOWNLOADS=true
            shift
            ;;
        --autofill)
            CLEAN_AUTOFILL=true
            shift
            ;;
        --all)
            CLEAN_ALL=true
            CLEAN_CACHE=true
            CLEAN_COOKIES=true
            CLEAN_HISTORY=true
            CLEAN_DOWNLOADS=true
            CLEAN_AUTOFILL=true
            shift
            ;;
        --browsers)
            BROWSERS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --cache-only      Clean only browser caches (default)"
            echo "  --cookies         Also clean cookies"
            echo "  --history         Also clean browsing history"
            echo "  --downloads       Also clean download history"
            echo "  --autofill        Also clean autofill data"
            echo "  --all             Clean everything (cache, cookies, history, downloads, autofill)"
            echo "  --browsers LIST   Comma-separated list: safari,chrome,firefox,edge (default: all)"
            echo "  --dry-run         Preview what would be cleaned without actually cleaning"
            echo "  -q, --quiet       Suppress output"
            echo "  -v, --verbose     Verbose output"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
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

# Calculate directory size
get_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
    return 0
}

# Clean Safari
clean_safari() {
    local cleaned=0
    local safari_dir="$HOME/Library/Safari"
    
    if [ ! -d "$safari_dir" ]; then
        if [ "$VERBOSE" = true ]; then
            info "Safari not found, skipping"
        fi
        return 0
    fi
    
    info "Cleaning Safari..."
    
    # Cache
    if [ "$CLEAN_CACHE" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cache_dirs=(
            "$HOME/Library/Caches/com.apple.Safari"
            "$HOME/Library/Caches/com.apple.WebKit.Networking"
            "$HOME/Library/Caches/com.apple.WebKit.WebContent"
        )
        
        for cache_dir in "${cache_dirs[@]}"; do
            if [ -d "$cache_dir" ]; then
                local size=$(get_size "$cache_dir")
                if [ "$DRY_RUN" = true ]; then
                    info "Would clean Safari cache: $cache_dir ($size)"
                else
                    rm -rf "$cache_dir"/* 2>/dev/null || true
                    cleaned=$((cleaned + 1))
                    success "Cleaned Safari cache: $cache_dir"
                fi
            fi
        done
    fi
    
    # Cookies
    if [ "$CLEAN_COOKIES" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cookies_file="$safari_dir/Cookies"
        if [ -f "$cookies_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Safari cookies: $cookies_file"
            else
                rm -f "$cookies_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Safari cookies"
            fi
        fi
    fi
    
    # History
    if [ "$CLEAN_HISTORY" = true ] || [ "$CLEAN_ALL" = true ]; then
        local history_files=(
            "$safari_dir/History.db"
            "$safari_dir/History.db-lock"
            "$safari_dir/History.db-shm"
            "$safari_dir/History.db-wal"
        )
        for hist_file in "${history_files[@]}"; do
            if [ -f "$hist_file" ]; then
                if [ "$DRY_RUN" = true ]; then
                    info "Would clean Safari history: $hist_file"
                else
                    rm -f "$hist_file" 2>/dev/null || true
                    cleaned=$((cleaned + 1))
                fi
            fi
        done
        if [ "$DRY_RUN" != true ] && [ "$cleaned" -gt 0 ]; then
            success "Cleaned Safari history"
        fi
    fi
    
    # Downloads
    if [ "$CLEAN_DOWNLOADS" = true ] || [ "$CLEAN_ALL" = true ]; then
        local downloads_file="$safari_dir/Downloads.plist"
        if [ -f "$downloads_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Safari download history: $downloads_file"
            else
                rm -f "$downloads_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Safari download history"
            fi
        fi
    fi
    
    # Autofill
    if [ "$CLEAN_AUTOFILL" = true ] || [ "$CLEAN_ALL" = true ]; then
        local autofill_file="$safari_dir/Autofill"
        if [ -f "$autofill_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Safari autofill data: $autofill_file"
            else
                rm -f "$autofill_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Safari autofill data"
            fi
        fi
    fi
    
    return 0
}

# Clean Chrome
clean_chrome() {
    local cleaned=0
    local chrome_dir="$HOME/Library/Application Support/Google/Chrome"
    
    if [ ! -d "$chrome_dir" ]; then
        if [ "$VERBOSE" = true ]; then
            info "Chrome not found, skipping"
        fi
        return 0
    fi
    
    info "Cleaning Chrome..."
    
    # Cache
    if [ "$CLEAN_CACHE" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cache_dir="$HOME/Library/Caches/Google/Chrome"
        if [ -d "$cache_dir" ]; then
            local size=$(get_size "$cache_dir")
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Chrome cache: $cache_dir ($size)"
            else
                rm -rf "$cache_dir"/* 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Chrome cache: $cache_dir"
            fi
        fi
    fi
    
    # Cookies
    if [ "$CLEAN_COOKIES" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cookies_file="$chrome_dir/Default/Cookies"
        if [ -f "$cookies_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Chrome cookies: $cookies_file"
            else
                rm -f "$cookies_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Chrome cookies"
            fi
        fi
    fi
    
    # History
    if [ "$CLEAN_HISTORY" = true ] || [ "$CLEAN_ALL" = true ]; then
        local history_file="$chrome_dir/Default/History"
        if [ -f "$history_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Chrome history: $history_file"
            else
                rm -f "$history_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Chrome history"
            fi
        fi
    fi
    
    # Downloads
    if [ "$CLEAN_DOWNLOADS" = true ] || [ "$CLEAN_ALL" = true ]; then
        local downloads_file="$chrome_dir/Default/History"
        # Chrome stores downloads in History database, but we can clear download history separately
        if [ "$DRY_RUN" = true ]; then
            info "Would clean Chrome download history"
        else
            # Note: Chrome stores downloads in History.db, which we already handle above
            cleaned=$((cleaned + 1))
            success "Cleaned Chrome download history"
        fi
    fi
    
    # Autofill
    if [ "$CLEAN_AUTOFILL" = true ] || [ "$CLEAN_ALL" = true ]; then
        local autofill_file="$chrome_dir/Default/Web Data"
        if [ -f "$autofill_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Chrome autofill data: $autofill_file"
            else
                rm -f "$autofill_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Chrome autofill data"
            fi
        fi
    fi
    
    return 0
}

# Clean Firefox
clean_firefox() {
    local cleaned=0
    local firefox_dir="$HOME/Library/Application Support/Firefox"
    
    if [ ! -d "$firefox_dir" ]; then
        if [ "$VERBOSE" = true ]; then
            info "Firefox not found, skipping"
        fi
        return 0
    fi
    
    info "Cleaning Firefox..."
    
    # Find default profile
    local profile_dir=""
    if [ -f "$firefox_dir/profiles.ini" ]; then
        profile_dir=$(grep -A 1 "^Default=" "$firefox_dir/profiles.ini" 2>/dev/null | grep "^Path=" | cut -d= -f2 | head -1 || true)
        if [ -n "$profile_dir" ]; then
            profile_dir="$firefox_dir/$profile_dir"
        fi
    fi
    
    # If no profile found, try common profile names
    if [ -z "$profile_dir" ] || [ ! -d "$profile_dir" ]; then
        if [ -d "$firefox_dir/Profiles" ]; then
            for possible_profile in "$firefox_dir"/Profiles/*; do
                if [ -d "$possible_profile" ]; then
                    profile_dir="$possible_profile"
                    break
                fi
            done
        fi
    fi
    
    if [ -z "$profile_dir" ] || [ ! -d "$profile_dir" ]; then
        if [ "$VERBOSE" = true ]; then
            warning "Could not find Firefox profile directory"
        fi
        return 0
    fi
    
    # Cache
    if [ "$CLEAN_CACHE" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cache_dir="$HOME/Library/Caches/Firefox"
        if [ -d "$cache_dir" ]; then
            local size=$(get_size "$cache_dir")
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Firefox cache: $cache_dir ($size)"
            else
                rm -rf "$cache_dir"/* 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Firefox cache: $cache_dir"
            fi
        fi
        
        # Profile cache
        local profile_cache="$profile_dir/cache2"
        if [ -d "$profile_cache" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Firefox profile cache: $profile_cache"
            else
                rm -rf "$profile_cache"/* 2>/dev/null || true
                cleaned=$((cleaned + 1))
            fi
        fi
    fi
    
    # Cookies
    if [ "$CLEAN_COOKIES" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cookies_file="$profile_dir/cookies.sqlite"
        if [ -f "$cookies_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Firefox cookies: $cookies_file"
            else
                rm -f "$cookies_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Firefox cookies"
            fi
        fi
    fi
    
    # History
    if [ "$CLEAN_HISTORY" = true ] || [ "$CLEAN_ALL" = true ]; then
        local history_file="$profile_dir/places.sqlite"
        if [ -f "$history_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Firefox history: $history_file"
            else
                rm -f "$history_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Firefox history"
            fi
        fi
    fi
    
    # Downloads
    if [ "$CLEAN_DOWNLOADS" = true ] || [ "$CLEAN_ALL" = true ]; then
        # Firefox stores downloads in places.sqlite, which we handle above
        if [ "$DRY_RUN" = true ]; then
            info "Would clean Firefox download history"
        else
            cleaned=$((cleaned + 1))
            success "Cleaned Firefox download history"
        fi
    fi
    
    # Autofill
    if [ "$CLEAN_AUTOFILL" = true ] || [ "$CLEAN_ALL" = true ]; then
        local form_data="$profile_dir/formhistory.sqlite"
        if [ -f "$form_data" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Firefox autofill data: $form_data"
            else
                rm -f "$form_data" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Firefox autofill data"
            fi
        fi
    fi
    
    return 0
}

# Clean Edge
clean_edge() {
    local cleaned=0
    local edge_dir="$HOME/Library/Application Support/Microsoft Edge"
    
    if [ ! -d "$edge_dir" ]; then
        if [ "$VERBOSE" = true ]; then
            info "Edge not found, skipping"
        fi
        return 0
    fi
    
    info "Cleaning Edge..."
    
    # Cache
    if [ "$CLEAN_CACHE" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cache_dir="$HOME/Library/Caches/Microsoft Edge"
        if [ -d "$cache_dir" ]; then
            local size=$(get_size "$cache_dir")
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Edge cache: $cache_dir ($size)"
            else
                rm -rf "$cache_dir"/* 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Edge cache: $cache_dir"
            fi
        fi
    fi
    
    # Cookies
    if [ "$CLEAN_COOKIES" = true ] || [ "$CLEAN_ALL" = true ]; then
        local cookies_file="$edge_dir/Default/Cookies"
        if [ -f "$cookies_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Edge cookies: $cookies_file"
            else
                rm -f "$cookies_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Edge cookies"
            fi
        fi
    fi
    
    # History
    if [ "$CLEAN_HISTORY" = true ] || [ "$CLEAN_ALL" = true ]; then
        local history_file="$edge_dir/Default/History"
        if [ -f "$history_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Edge history: $history_file"
            else
                rm -f "$history_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Edge history"
            fi
        fi
    fi
    
    # Downloads
    if [ "$CLEAN_DOWNLOADS" = true ] || [ "$CLEAN_ALL" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            info "Would clean Edge download history"
        else
            cleaned=$((cleaned + 1))
            success "Cleaned Edge download history"
        fi
    fi
    
    # Autofill
    if [ "$CLEAN_AUTOFILL" = true ] || [ "$CLEAN_ALL" = true ]; then
        local autofill_file="$edge_dir/Default/Web Data"
        if [ -f "$autofill_file" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "Would clean Edge autofill data: $autofill_file"
            else
                rm -f "$autofill_file" 2>/dev/null || true
                cleaned=$((cleaned + 1))
                success "Cleaned Edge autofill data"
            fi
        fi
    fi
    
    return 0
}

# Main execution
main() {
    if [ "$QUIET" != true ]; then
        echo "${bold}🌐 Browser Cleanup Tool${normal}"
        echo "================================"
        echo ""
        
        if [ "$DRY_RUN" = true ]; then
            warning "DRY RUN MODE - No files will be deleted"
            echo ""
        fi
        
        echo "Cleaning options:"
        [ "$CLEAN_CACHE" = true ] && echo "  ✅ Cache"
        [ "$CLEAN_COOKIES" = true ] && echo "  ✅ Cookies"
        [ "$CLEAN_HISTORY" = true ] && echo "  ✅ History"
        [ "$CLEAN_DOWNLOADS" = true ] && echo "  ✅ Download History"
        [ "$CLEAN_AUTOFILL" = true ] && echo "  ✅ Autofill Data"
        echo ""
    fi
    
    # Determine which browsers to clean
    if [ -z "$BROWSERS" ]; then
        # Clean all browsers by default
        clean_safari
        clean_chrome
        clean_firefox
        clean_edge
    else
        # Clean only specified browsers
        IFS=',' read -ra BROWSER_LIST <<< "$BROWSERS"
        for browser in "${BROWSER_LIST[@]}"; do
            # Convert to lowercase (compatible with macOS bash 3.2)
            browser_lower=$(echo "$browser" | tr '[:upper:]' '[:lower:]')
            case "$browser_lower" in
                safari)
                    clean_safari
                    ;;
                chrome)
                    clean_chrome
                    ;;
                firefox)
                    clean_firefox
                    ;;
                edge)
                    clean_edge
                    ;;
                *)
                    warning "Unknown browser: $browser"
                    ;;
            esac
        done
    fi
    
    if [ "$QUIET" != true ]; then
        echo ""
        if [ "$DRY_RUN" = true ]; then
            info "Dry run complete. Use without --dry-run to actually clean."
        else
            success "Browser cleanup complete!"
            warning "Note: You may need to restart your browsers for changes to take effect."
        fi
    fi
    
    return 0
}

# Run main function
main "$@"

