#!/bin/bash

# ===============================
# Configuration Validator
# Validates config.yaml structure and values
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/validators.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config_loader.sh" 2>/dev/null || true

CONFIG_FILE="${1:-$HOME/.macguardian/config.yaml}"

# ===============================
# Validate Configuration File
# ===============================

validate_config_file() {
    local config_file="$1"
    local errors=0
    
    if [ ! -f "$config_file" ]; then
        echo "ERROR: Configuration file not found: $config_file" >&2
        return 1
    fi
    
    # Validate file path
    if ! validate_path "$config_file" false; then
        echo "ERROR: Invalid configuration file path" >&2
        return 1
    fi
    
    # Load config
    if ! load_config "$config_file"; then
        echo "ERROR: Failed to load configuration" >&2
        return 1
    fi
    
    # Validate configuration values
    if ! validate_config; then
        errors=$?
    fi
    
    if [ $errors -eq 0 ]; then
        echo "✅ Configuration file is valid"
        return 0
    else
        echo "❌ Configuration validation failed with $errors error(s)" >&2
        return 1
    fi
}

# Main execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    validate_config_file "$CONFIG_FILE"
    exit $?
fi

