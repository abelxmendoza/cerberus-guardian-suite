#!/bin/bash

# ===============================
# Configuration Loader
# Loads and validates config.yaml
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.macguardian"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
DEFAULT_CONFIG="$SCRIPT_DIR/../config/config.yaml"

# Source validators
source "$SCRIPT_DIR/validators.sh" 2>/dev/null || true

# ===============================
# Load Configuration
# ===============================

load_config() {
    local config_path="${1:-$CONFIG_FILE}"
    
    # Use default config if user config doesn't exist
    if [ ! -f "$config_path" ] && [ -f "$DEFAULT_CONFIG" ]; then
        config_path="$DEFAULT_CONFIG"
    fi
    
    if [ ! -f "$config_path" ]; then
        echo "ERROR: Configuration file not found: $config_path" >&2
        return 1
    fi
    
    # Validate config path
    if ! validate_path "$config_path" false; then
        echo "ERROR: Invalid configuration file path" >&2
        return 1
    fi
    
    # Source config (simple key=value format for bash compatibility)
    # In production, would use yq or python to parse YAML properly
    if [ -f "$config_path" ]; then
        # Simple YAML parsing (basic key: value pairs)
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            
            # Parse key: value pairs
            if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*(.+)$ ]]; then
                local key="${BASH_REMATCH[1]// /}"
                local value="${BASH_REMATCH[2]// /}"
                
                # Export as environment variable
                export "CONFIG_${key^^}"="$value"
            fi
        done < "$config_path"
    fi
    
    return 0
}

# ===============================
# Get Config Value
# ===============================

get_config() {
    local key="$1"
    local default="${2:-}"
    
    local var_name="CONFIG_${key^^}"
    local value="${!var_name:-$default}"
    
    echo "$value"
}

# ===============================
# Validate Configuration
# ===============================

validate_config() {
    local errors=0
    
    # Check required fields
    local required_fields=("scan_intervals" "alerts" "ids")
    
    for field in "${required_fields[@]}"; do
        local value=$(get_config "$field")
        if [ -z "$value" ]; then
            echo "ERROR: Required config field missing: $field" >&2
            errors=$((errors + 1))
        fi
    done
    
    # Validate scan intervals
    local process_interval=$(get_config "process_interval" "5")
    if ! validate_int "$process_interval" 1 3600; then
        echo "ERROR: Invalid process_interval: $process_interval" >&2
        errors=$((errors + 1))
    fi
    
    # Validate severity levels
    local alert_severity=$(get_config "alert_severity" "high")
    if ! validate_severity "$alert_severity"; then
        echo "ERROR: Invalid alert_severity: $alert_severity" >&2
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Auto-load config on source
if [ "${AUTO_LOAD_CONFIG:-true}" = "true" ]; then
    load_config 2>/dev/null || true
fi

# Export functions
export -f load_config
export -f get_config
export -f validate_config

