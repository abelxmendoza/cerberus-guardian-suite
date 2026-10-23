#!/bin/bash

# ===============================
# Fleet Mode - Enterprise SIEM Integration
# Forwards events to corporate SIEM systems
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.macguardian"
EVENT_DIR="$CONFIG_DIR/events"
LOG_DIR="$CONFIG_DIR/logs"

# SIEM endpoints (configured via MDM)
SIEM_ENDPOINT="${SIEM_ENDPOINT:-}"
SIEM_API_KEY="${SIEM_API_KEY:-}"
SIEM_TYPE="${SIEM_TYPE:-webhook}"  # webhook, splunk, elastic, datadog

# ===============================
# SIEM Forwarders
# ===============================

forward_to_webhook() {
    local event_json="$1"
    local endpoint="$SIEM_ENDPOINT"
    
    if [ -z "$endpoint" ]; then
        echo "ERROR: SIEM_ENDPOINT not configured" >&2
        return 1
    fi
    
    curl -X POST "$endpoint" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SIEM_API_KEY" \
        -d "$event_json" \
        --silent --show-error > /dev/null 2>&1
}

forward_to_splunk() {
    local event_json="$1"
    local endpoint="$SIEM_ENDPOINT"
    
    # Splunk HEC endpoint format: https://splunk:8088/services/collector
    curl -X POST "$endpoint" \
        -H "Authorization: Splunk $SIEM_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$event_json" \
        --silent --show-error > /dev/null 2>&1
}

forward_to_elastic() {
    local event_json="$1"
    local endpoint="$SIEM_ENDPOINT"
    
    # Elasticsearch endpoint format: https://elastic:9200/_bulk
    curl -X POST "$endpoint" \
        -H "Authorization: ApiKey $SIEM_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$event_json" \
        --silent --show-error > /dev/null 2>&1
}

forward_to_datadog() {
    local event_json="$1"
    local endpoint="$SIEM_ENDPOINT"
    
    # Datadog endpoint format: https://api.datadoghq.com/api/v1/events
    curl -X POST "$endpoint" \
        -H "DD-API-KEY: $SIEM_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$event_json" \
        --silent --show-error > /dev/null 2>&1
}

# ===============================
# Event Forwarding
# ===============================

forward_event() {
    local event_file="$1"
    
    if [ ! -f "$event_file" ]; then
        return 1
    fi
    
    local event_json
    event_json=$(cat "$event_file")
    
    case "$SIEM_TYPE" in
        webhook)
            forward_to_webhook "$event_json"
            ;;
        splunk)
            forward_to_splunk "$event_json"
            ;;
        elastic)
            forward_to_elastic "$event_json"
            ;;
        datadog)
            forward_to_datadog "$event_json"
            ;;
        *)
            echo "ERROR: Unknown SIEM type: $SIEM_TYPE" >&2
            return 1
            ;;
    esac
}

# ===============================
# Monitor and Forward
# ===============================

monitor_events() {
    echo "Starting Fleet Mode SIEM forwarding..."
    echo "SIEM Type: $SIEM_TYPE"
    echo "Endpoint: $SIEM_ENDPOINT"
    
    # Watch for new events
    while true; do
        # Find new events (modified in last minute)
        find "$EVENT_DIR" -name "event_*.json" -type f -mmin -1 | while read -r event_file; do
            forward_event "$event_file"
        done
        
        sleep 5
    done
}

# ===============================
# Main
# ===============================

main() {
    if [ -z "$SIEM_ENDPOINT" ]; then
        echo "ERROR: SIEM_ENDPOINT environment variable not set" >&2
        echo "Configure via MDM or environment variables" >&2
        exit 1
    fi
    
    monitor_events
}

main "$@"

