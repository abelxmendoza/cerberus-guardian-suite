#!/bin/bash

# ===============================
# Alert Router Pipeline
# Routes events to email, notifications, webhooks, SwiftUI
# Event Spec v1.0.0 compliant
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source core modules
source "$SUITE_DIR/core/validators.sh" 2>/dev/null || true
source "$SUITE_DIR/core/logging.sh" 2>/dev/null || true
source "$SUITE_DIR/core/config_loader.sh" 2>/dev/null || true

TIMELINE_FILE="$HOME/.macguardian/logs/timeline.jsonl"
ALERT_POLICIES="$SUITE_DIR/config/alert_policies.yaml"
ALERT_COOLDOWN_FILE="$HOME/.macguardian/.alert_cooldown"
EMAIL_SCRIPT="$SUITE_DIR/send_email.py"
WEBHOOK_SCRIPT="$SUITE_DIR/outputs/webhook_notifier.sh"

# Alert cooldown (seconds) - prevent spam
ALERT_COOLDOWN=300  # 5 minutes

# Load alert policies
load_alert_policies() {
    if [ ! -f "$ALERT_POLICIES" ]; then
        # Default policies
        echo "{}"
        return 0
    fi
    
    # Simple YAML parsing (basic)
    cat "$ALERT_POLICIES" 2>/dev/null || echo "{}"
}

# Check if alert is in cooldown
check_cooldown() {
    local alert_key="$1"
    
    if [ ! -f "$ALERT_COOLDOWN_FILE" ]; then
        return 0  # Not in cooldown
    fi
    
    local last_alert=$(grep "^$alert_key:" "$ALERT_COOLDOWN_FILE" 2>/dev/null | cut -d: -f2 || echo "0")
    local current_time=$(date +%s)
    
    if [ $((current_time - last_alert)) -lt $ALERT_COOLDOWN ]; then
        return 1  # In cooldown
    fi
    
    return 0  # Not in cooldown
}

# Update cooldown
update_cooldown() {
    local alert_key="$1"
    local current_time=$(date +%s)
    
    mkdir -p "$(dirname "$ALERT_COOLDOWN_FILE")"
    
    if [ -f "$ALERT_COOLDOWN_FILE" ]; then
        grep -v "^$alert_key:" "$ALERT_COOLDOWN_FILE" > "${ALERT_COOLDOWN_FILE}.tmp" 2>/dev/null || true
        mv "${ALERT_COOLDOWN_FILE}.tmp" "$ALERT_COOLDOWN_FILE" 2>/dev/null || true
    fi
    
    echo "$alert_key:$current_time" >> "$ALERT_COOLDOWN_FILE"
}

# Send macOS notification
send_notification() {
    local title="$1"
    local message="$2"
    local severity="${3:-info}"
    
    local sound="default"
    case "$severity" in
        critical|high)
            sound="Basso"
            ;;
        medium)
            sound="Ping"
            ;;
        *)
            sound="default"
            ;;
    esac
    
    osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\"" 2>/dev/null || true
}

# Send email alert
send_email_alert() {
    local subject="$1"
    local body="$2"
    local severity="${3:-medium}"
    
    if [ ! -f "$EMAIL_SCRIPT" ]; then
        return 1
    fi
    
    # Load email config
    local email_config=$(load_config_value "alerts.email.enabled" "false" 2>/dev/null || echo "false")
    local email_address=$(load_config_value "alerts.email.address" "" 2>/dev/null || echo "")
    
    if [ "$email_config" != "true" ] || [ -z "$email_address" ]; then
        return 1
    fi
    
    python3 "$EMAIL_SCRIPT" --to "$email_address" --subject "$subject" --body "$body" 2>/dev/null || true
}

# Send webhook alert
send_webhook_alert() {
    local event_json="$1"
    
    if [ ! -f "$WEBHOOK_SCRIPT" ]; then
        return 1
    fi
    
    # Load webhook config
    local webhook_enabled=$(load_config_value "alerts.webhook.enabled" "false" 2>/dev/null || echo "false")
    local webhook_url=$(load_config_value "alerts.webhook.url" "" 2>/dev/null || echo "")
    
    if [ "$webhook_enabled" != "true" ] || [ -z "$webhook_url" ]; then
        return 1
    fi
    
    bash "$WEBHOOK_SCRIPT" "$webhook_url" "$event_json" 2>/dev/null || true
}

# Route event based on policies
route_event() {
    local event_json="$1"
    
    # Parse event
    local event_type=$(echo "$event_json" | grep -o '"event_type":"[^"]*"' | cut -d'"' -f4 || echo "")
    local severity=$(echo "$event_json" | grep -o '"severity":"[^"]*"' | cut -d'"' -f4 || echo "")
    local source=$(echo "$event_json" | grep -o '"source":"[^"]*"' | cut -d'"' -f4 || echo "")
    local event_id=$(echo "$event_json" | grep -o '"event_id":"[^"]*"' | cut -d'"' -f4 || echo "")
    
    if [ -z "$event_type" ] || [ -z "$severity" ]; then
        return 1
    fi
    
    # Create alert key for cooldown
    local alert_key="${event_type}_${severity}"
    
    # Check cooldown
    if ! check_cooldown "$alert_key"; then
        log_router "alert_router" "DEBUG" "Alert in cooldown: $alert_key"
        return 0
    fi
    
    # Extract message from context
    local message=$(echo "$event_json" | grep -o '"message":"[^"]*"' | cut -d'"' -f4 || echo "Security event detected")
    if [ -z "$message" ]; then
        message="Security event: $event_type ($severity)"
    fi
    
    # Route based on severity
    case "$severity" in
        critical)
            # Always send notifications and email for critical
            send_notification "🚨 MacGuardian Alert" "$message" "critical"
            send_email_alert "MacGuardian Critical Alert: $event_type" "$message" "critical"
            send_webhook_alert "$event_json"
            update_cooldown "$alert_key"
            ;;
        high)
            # Send notifications and email for high
            send_notification "⚠️ MacGuardian Alert" "$message" "high"
            send_email_alert "MacGuardian High Alert: $event_type" "$message" "high"
            send_webhook_alert "$event_json"
            update_cooldown "$alert_key"
            ;;
        medium)
            # Send notifications only for medium
            send_notification "MacGuardian Alert" "$message" "medium"
            send_webhook_alert "$event_json"
            update_cooldown "$alert_key"
            ;;
        low)
            # Log only for low severity
            log_router "alert_router" "INFO" "Low severity event: $event_type"
            ;;
    esac
    
    return 0
}

# Process timeline for new events
process_timeline() {
    local last_processed="$HOME/.macguardian/.alert_router_last_processed"
    local last_line=$(cat "$last_processed" 2>/dev/null || echo "0")
    local current_line=0
    
    if [ ! -f "$TIMELINE_FILE" ]; then
        return 0
    fi
    
    while IFS= read -r line; do
        current_line=$((current_line + 1))
        
        if [ $current_line -le $last_line ]; then
            continue
        fi
        
        if [ -z "$line" ]; then
            continue
        fi
        
        # Route event
        route_event "$line"
    done < "$TIMELINE_FILE"
    
    # Update last processed line
    echo "$current_line" > "$last_processed"
}

# Main loop (for daemon mode)
main_loop() {
    while true; do
        process_timeline
        sleep 10  # Check every 10 seconds
    done
}

# Export functions
export -f route_event
export -f send_notification
export -f send_email_alert
export -f send_webhook_alert
export -f process_timeline

# Main execution
if [ "${1:-process}" = "daemon" ]; then
    main_loop
else
    process_timeline
fi

