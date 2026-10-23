#!/bin/bash

# ===============================
# MacGuardian Collector Launcher
# Starts the modular event collection system
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true

# Check Python
if ! command -v python3 &> /dev/null; then
    error "Python 3 is required. Install with: brew install python3"
    exit 1
fi

# Check for required Python packages
python3 -c "import requests" 2>/dev/null || {
    warning "requests module not found. Installing..."
    pip3 install requests --user
}

# Main function
main() {
    echo "${bold}🔄 MacGuardian Event Collector${normal}"
    echo "=========================================="
    echo ""
    
    # Check if modules.conf exists
    CONFIG_FILE="$HOME/.macguardian/modules.conf"
    if [ ! -f "$CONFIG_FILE" ]; then
        warning "Configuration file not found: $CONFIG_FILE"
        echo ""
        echo "Creating example configuration..."
        mkdir -p "$HOME/.macguardian"
        cp "$SCRIPT_DIR/modules.conf.example" "$CONFIG_FILE"
        echo "✅ Created: $CONFIG_FILE"
        echo ""
        echo "${yellow}⚠️  Please edit $CONFIG_FILE before running${normal}"
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            exit 0
        fi
    fi
    
    echo "Starting event collectors..."
    echo ""
    
    # Start the module manager
    python3 "$SCRIPT_DIR/module_manager.py" "$@"
}

main "$@"

