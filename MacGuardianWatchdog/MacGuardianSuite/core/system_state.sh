#!/bin/bash

# ===============================
# macOS System State Awareness
# Checks SIP, SSV, TCC, and Full Disk Access status
# ===============================

set -euo pipefail

# Status codes
SIP_ENABLED=1
SIP_DISABLED=0
SSV_ENABLED=1
SSV_DISABLED=0
TCC_GRANTED=1
TCC_DENIED=0
FDA_GRANTED=1
FDA_DENIED=0

# ===============================
# SIP (System Integrity Protection) Status
# ===============================

check_sip_status() {
    # Check SIP status using csrutil
    if command -v csrutil &> /dev/null; then
        local sip_status=$(csrutil status 2>/dev/null | grep -i "enabled" || echo "")
        if [ -n "$sip_status" ]; then
            return $SIP_ENABLED
        fi
    fi
    
    # Fallback: check NVRAM
    local sip_value=$(nvram csr-active-config 2>/dev/null | awk '{print $2}' || echo "")
    if [ -n "$sip_value" ] && [ "$sip_value" != "0x0" ]; then
        return $SIP_ENABLED
    fi
    
    return $SIP_DISABLED
}

get_sip_status_text() {
    if check_sip_status; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

# ===============================
# SSV (Signed System Volume) Status
# ===============================

check_ssv_status() {
    # Check if running on macOS 11+ (Big Sur+)
    local os_version=$(sw_vers -productVersion 2>/dev/null || echo "0.0.0")
    local major_version=$(echo "$os_version" | cut -d. -f1)
    
    if [ "$major_version" -lt 11 ]; then
        return $SSV_DISABLED
    fi
    
    # Check if system volume is sealed
    if [ -d "/System/Volumes/Data" ]; then
        # On Big Sur+, check if system volume is sealed
        local sealed=$(diskutil info / 2>/dev/null | grep -i "Sealed" || echo "")
        if echo "$sealed" | grep -qi "yes\|true"; then
            return $SSV_ENABLED
        fi
    fi
    
    return $SSV_DISABLED
}

get_ssv_status_text() {
    if check_ssv_status; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

# ===============================
# TCC (Transparency, Consent, and Control) Permissions
# ===============================

check_tcc_permissions() {
    local app_bundle_id="${1:-com.macguardian.suite.ui}"
    
    if command -v tccutil &> /dev/null; then
        # Check if TCC database exists and is accessible
        local tcc_db="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
        if [ -f "$tcc_db" ] && [ -r "$tcc_db" ]; then
            return $TCC_GRANTED
        fi
    fi
    
    return $TCC_DENIED
}

# ===============================
# Full Disk Access Status
# ===============================

check_full_disk_access() {
    local app_bundle_id="${1:-com.macguardian.suite.ui}"
    
    if command -v sqlite3 &> /dev/null; then
        local tcc_db="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
        
        if [ -f "$tcc_db" ] && [ -r "$tcc_db" ]; then
            # Check for Full Disk Access permission
            local fda_count=$(sqlite3 "$tcc_db" "SELECT COUNT(*) FROM access WHERE service='kTCCServiceSystemPolicyAllFiles' AND client='$app_bundle_id' AND allowed=1;" 2>/dev/null || echo "0")
            
            if [ "$fda_count" -gt 0 ]; then
                return $FDA_GRANTED
            fi
        fi
    fi
    
    # Fallback: try to access a system directory
    if [ -r "/Library" ] 2>/dev/null; then
        return $FDA_GRANTED
    fi
    
    return $FDA_DENIED
}

get_fda_status_text() {
    if check_full_disk_access; then
        echo "granted"
    else
        echo "denied"
    fi
}

# ===============================
# System State Summary
# ===============================

get_system_state_summary() {
    local sip_status=$(get_sip_status_text)
    local ssv_status=$(get_ssv_status_text)
    local fda_status=$(get_fda_status_text)
    
    cat <<EOF
{
  "sip": "$sip_status",
  "ssv": "$ssv_status",
  "full_disk_access": "$fda_status",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# ===============================
# Degrade Gracefully Based on System State
# ===============================

check_system_compatibility() {
    local warnings=()
    
    if check_sip_status; then
        warnings+=("SIP is enabled - some system file monitoring may be limited")
    fi
    
    if check_ssv_status; then
        warnings+=("SSV is enabled - system volume modifications are restricted")
    fi
    
    if ! check_full_disk_access; then
        warnings+=("Full Disk Access not granted - file integrity monitoring may be limited")
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        for warning in "${warnings[@]}"; do
            echo "WARNING: $warning" >&2
        done
        return 1
    fi
    
    return 0
}

# Export functions
export -f check_sip_status
export -f get_sip_status_text
export -f check_ssv_status
export -f get_ssv_status_text
export -f check_tcc_permissions
export -f check_full_disk_access
export -f get_fda_status_text
export -f get_system_state_summary
export -f check_system_compatibility

