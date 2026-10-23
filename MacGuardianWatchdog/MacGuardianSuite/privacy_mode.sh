#!/bin/bash

# ===============================
# Privacy Mode Configuration
# Control what the suite monitors and collects
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_DIR:-$HOME/.macguardian}/privacy.conf"

# Default privacy settings (most permissive)
PRIVACY_MODE="${PRIVACY_MODE:-standard}"  # standard, light, minimal, full
MONITOR_NETWORK="${MONITOR_NETWORK:-true}"
MONITOR_PROCESSES="${MONITOR_PROCESSES:-true}"
COLLECT_PERFORMANCE_DATA="${COLLECT_PERFORMANCE_DATA:-true}"
LOG_DETAILED_INFO="${LOG_DETAILED_INFO:-true}"
SHARE_ANONYMOUS_STATS="${SHARE_ANONYMOUS_STATS:-false}"  # Not implemented, but reserved

# Privacy modes
# - minimal: Only essential security checks, no network monitoring, no performance tracking
# - light: Basic security + file monitoring, limited network checks
# - standard: Full security suite (default)
# - full: Everything + detailed logging (for security professionals)

set_privacy_mode() {
    local mode="${1:-standard}"
    
    case "$mode" in
        minimal)
            MONITOR_NETWORK=false
            MONITOR_PROCESSES=true  # Still need for security
            COLLECT_PERFORMANCE_DATA=false
            LOG_DETAILED_INFO=false
            PRIVACY_MODE="minimal"
            ;;
        light)
            MONITOR_NETWORK=true
            MONITOR_PROCESSES=true
            COLLECT_PERFORMANCE_DATA=false
            LOG_DETAILED_INFO=false
            PRIVACY_MODE="light"
            ;;
        standard)
            MONITOR_NETWORK=true
            MONITOR_PROCESSES=true
            COLLECT_PERFORMANCE_DATA=true
            LOG_DETAILED_INFO=true
            PRIVACY_MODE="standard"
            ;;
        full)
            MONITOR_NETWORK=true
            MONITOR_PROCESSES=true
            COLLECT_PERFORMANCE_DATA=true
            LOG_DETAILED_INFO=true
            PRIVACY_MODE="full"
            ;;
        *)
            echo "Invalid privacy mode: $mode"
            echo "Valid modes: minimal, light, standard, full"
            return 1
            ;;
    esac
    
    # Save to config
    cat > "$CONFIG_FILE" <<EOF
# Privacy Mode Configuration
# Generated: $(date)
PRIVACY_MODE="$PRIVACY_MODE"
MONITOR_NETWORK=$MONITOR_NETWORK
MONITOR_PROCESSES=$MONITOR_PROCESSES
COLLECT_PERFORMANCE_DATA=$COLLECT_PERFORMANCE_DATA
LOG_DETAILED_INFO=$LOG_DETAILED_INFO
EOF
    
    echo "✅ Privacy mode set to: $PRIVACY_MODE"
    return 0
}

# Load privacy settings
load_privacy_settings() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
    fi
}

# Show current privacy settings
show_privacy_status() {
    load_privacy_settings
    
    echo "${bold}🔒 Privacy Mode Status${normal}"
    echo "=========================================="
    echo ""
    echo "Current Mode: ${PRIVACY_MODE:-standard}"
    echo ""
    echo "Monitoring Settings:"
    echo "  Network Monitoring: ${MONITOR_NETWORK:-true}"
    echo "  Process Monitoring: ${MONITOR_PROCESSES:-true}"
    echo "  Performance Tracking: ${COLLECT_PERFORMANCE_DATA:-true}"
    echo "  Detailed Logging: ${LOG_DETAILED_INFO:-true}"
    echo ""
    echo "What This Means:"
    case "${PRIVACY_MODE:-standard}" in
        minimal)
            echo "  ✅ Minimal monitoring - Only essential security checks"
            echo "  ✅ No network traffic analysis"
            echo "  ✅ No performance data collection"
            echo "  ✅ Minimal logging"
            ;;
        light)
            echo "  ✅ Light monitoring - Basic security + file checks"
            echo "  ✅ Limited network checks (connection status only)"
            echo "  ✅ No performance tracking"
            echo "  ✅ Basic logging"
            ;;
        standard)
            echo "  ✅ Standard monitoring - Full security suite"
            echo "  ✅ Network connection monitoring (not content)"
            echo "  ✅ Performance tracking for optimization"
            echo "  ✅ Standard logging"
            ;;
        full)
            echo "  ✅ Full monitoring - Everything enabled"
            echo "  ✅ Detailed network analysis"
            echo "  ✅ Complete performance tracking"
            echo "  ✅ Detailed logging"
            ;;
    esac
    echo ""
    echo "Privacy Guarantee:"
    echo "  ✅ All processing happens locally on your Mac"
    echo "  ✅ No data is sent to external servers"
    echo "  ✅ No wiretapping or packet inspection"
    echo "  ✅ Only connection metadata (not content)"
    echo ""
}

# Main function
main() {
    case "${1:-status}" in
        set)
            set_privacy_mode "$2"
            ;;
        status)
            show_privacy_status
            ;;
        minimal)
            set_privacy_mode "minimal"
            ;;
        light)
            set_privacy_mode "light"
            ;;
        standard)
            set_privacy_mode "standard"
            ;;
        full)
            set_privacy_mode "full"
            ;;
        *)
            echo "Usage: $0 [set|status|minimal|light|standard|full]"
            echo ""
            echo "Privacy Modes:"
            echo "  minimal  - Only essential checks, no network monitoring"
            echo "  light    - Basic security, limited network checks"
            echo "  standard - Full suite (default)"
            echo "  full     - Everything enabled"
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

