#!/bin/bash

# ===============================
# MDM Sync - Refresh Managed Configuration
# Syncs with corporate MDM every 15 minutes
# ===============================

set -euo pipefail

CONFIG_DIR="$HOME/.macguardian"
MDM_CONFIG="/Library/Managed Preferences/com.macguardian.watchdog/config.yaml"
SYNC_INTERVAL=900  # 15 minutes

# ===============================
# Sync Configuration
# ===============================

sync_config() {
    if [ -f "$MDM_CONFIG" ]; then
        echo "Syncing managed configuration..."
        
        # Copy managed config to user config (read-only)
        cp "$MDM_CONFIG" "$CONFIG_DIR/config.yaml.managed"
        chmod 444 "$CONFIG_DIR/config.yaml.managed"
        
        # Reload configuration
        if [ -f "$CONFIG_DIR/config.yaml.managed" ]; then
            echo "✅ Managed configuration synced"
            return 0
        fi
    else
        echo "⚠️  No managed configuration found"
        return 1
    fi
}

# ===============================
# Main Loop
# ===============================

main() {
    echo "Starting MDM sync service..."
    echo "Sync interval: $SYNC_INTERVAL seconds"
    
    while true; do
        sync_config
        sleep "$SYNC_INTERVAL"
    done
}

main "$@"

