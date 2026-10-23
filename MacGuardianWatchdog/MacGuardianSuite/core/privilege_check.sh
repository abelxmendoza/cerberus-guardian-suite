#!/bin/bash

# ===============================
# Privilege Boundary Checks
# Determines what operations require sudo
# ===============================

set -euo pipefail

# ===============================
# Check if Running with Sudo
# ===============================

is_sudo() {
    [ "$EUID" -eq 0 ] || [ -n "${SUDO_USER:-}" ]
}

# ===============================
# Check Required Privileges
# ===============================

check_privileges() {
    local operation="$1"
    
    case "$operation" in
        # Non-sudo operations
        watch|monitor|detect|log|view)
            return 0  # Always allowed
            ;;
        
        # Sudo required operations
        audit|remediate|quarantine|system_config)
            if is_sudo; then
                return 0
            else
                echo "ERROR: Operation '$operation' requires sudo privileges" >&2
                return 1
            fi
            ;;
        
        *)
            # Unknown operation - default to requiring sudo for safety
            if is_sudo; then
                return 0
            else
                echo "WARNING: Unknown operation '$operation' - assuming sudo required" >&2
                return 1
            fi
            ;;
    esac
}

# ===============================
# Degrade Gracefully
# ===============================

degrade_gracefully() {
    local operation="$1"
    local message="${2:-Operation requires elevated privileges}"
    
    if ! check_privileges "$operation"; then
        echo "WARNING: $message" >&2
        echo "INFO: Continuing with limited functionality" >&2
        return 1
    fi
    
    return 0
}

# ===============================
# Require Sudo or Exit
# ===============================

require_sudo() {
    local operation="$1"
    
    if ! is_sudo; then
        echo "ERROR: '$operation' requires sudo privileges" >&2
        echo "Please run with: sudo $0" >&2
        exit 1
    fi
}

# Export functions
export -f is_sudo
export -f check_privileges
export -f degrade_gracefully
export -f require_sudo

