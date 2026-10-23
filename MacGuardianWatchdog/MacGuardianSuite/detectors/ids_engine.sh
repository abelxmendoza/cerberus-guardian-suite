#!/bin/bash

# ===============================
# IDS Engine (Intrusion Detection System)
# Real-time correlation and alerting
# Event Spec v1.0.0 compliant
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source core modules
source "$SUITE_DIR/core/validators.sh" 2>/dev/null || true
source "$SUITE_DIR/core/logging.sh" 2>/dev/null || true
source "$SUITE_DIR/core/system_state.sh" 2>/dev/null || true
source "$SUITE_DIR/daemons/event_writer.sh" 2>/dev/null || true

EVENT_DIR="$HOME/.macguardian/events"
TIMELINE_FILE="$HOME/.macguardian/logs/timeline.jsonl"
INCIDENTS_DIR="$HOME/.macguardian/incidents"
RULES_FILE="$SUITE_DIR/config/rules.yaml"

mkdir -p "$INCIDENTS_DIR" "$(dirname "$TIMELINE_FILE")"

# Correlation window (seconds)
CORRELATION_WINDOW=60

# Load recent events from timeline
load_recent_events() {
    local window_start=$(date -u -v-${CORRELATION_WINDOW}S +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "$CORRELATION_WINDOW seconds ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
    
    if [ ! -f "$TIMELINE_FILE" ]; then
        echo "[]"
        return 0
    fi
    
    # Extract events from last CORRELATION_WINDOW seconds
    local events="["
    local first=true
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local event_timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4 || echo "")
        if [ -n "$event_timestamp" ]; then
            # Compare timestamps (simplified - assumes ISO8601 format)
            if [ "$event_timestamp" \> "$window_start" ] || [ "$event_timestamp" = "$window_start" ]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    events="$events,"
                fi
                events="$events$line"
            fi
        fi
    done < "$TIMELINE_FILE"
    
    events="$events]"
    echo "$events"
}

# Run IDS correlation
run_ids_correlation() {
    local recent_events_json
    recent_events_json=$(load_recent_events)
    
    if [ "$recent_events_json" = "[]" ] || [ -z "$recent_events_json" ]; then
        return 0
    fi
    
    # Count event types (simplified parsing)
    local file_changes=$(echo "$recent_events_json" | grep -o '"event_type":"file_integrity_change"' | wc -l | tr -d ' ')
    local process_events=$(echo "$recent_events_json" | grep -o '"event_type":"process_anomaly"' | wc -l | tr -d ' ')
    local network_events=$(echo "$recent_events_json" | grep -o '"event_type":"network_connection"' | wc -l | tr -d ' ')
    local high_severity=$(echo "$recent_events_json" | grep -o '"severity":"high"' | wc -l | tr -d ' ')
    local critical_severity=$(echo "$recent_events_json" | grep -o '"severity":"critical"' | wc -l | tr -d ' ')
    
    # Rule 1: File change + New process + Network connection = Suspicious
    if [ "$file_changes" -gt 0 ] && [ "$process_events" -gt 0 ] && [ "$network_events" -gt 0 ]; then
        local context_json="{\"rule\": \"multiple_suspicious_activities\", \"file_changes\": $file_changes, \"process_events\": $process_events, \"network_events\": $network_events, \"time_window\": $CORRELATION_WINDOW}"
        write_event "ids_alert" "critical" "ids_engine" "$context_json"
        create_incident "correlation" "critical" "Multiple suspicious activities detected simultaneously" "$context_json"
    fi
    
    # Rule 2: High severity process + Network to suspicious IP = Alert
    if [ "$high_severity" -gt 0 ] && [ "$network_events" -gt 0 ]; then
        local suspicious_ips=$(echo "$recent_events_json" | grep -o '"threat_source"' | wc -l | tr -d ' ')
        if [ "$suspicious_ips" -gt 0 ]; then
            local context_json="{\"rule\": \"high_cpu_malicious_ip\", \"high_severity_processes\": $high_severity, \"suspicious_ips\": $suspicious_ips, \"time_window\": $CORRELATION_WINDOW}"
            write_event "ids_alert" "high" "ids_engine" "$context_json"
            create_incident "correlation" "high" "High severity process connecting to known malicious IP" "$context_json"
        fi
    fi
    
    # Rule 3: Multiple file changes in short time = Potential ransomware
    if [ "$file_changes" -gt 50 ]; then
        local context_json="{\"rule\": \"mass_file_changes\", \"file_changes\": $file_changes, \"time_window\": $CORRELATION_WINDOW}"
        write_event "ransomware_activity" "critical" "ids_engine" "$context_json"
        create_incident "correlation" "critical" "Mass file changes detected - possible ransomware" "$context_json"
    fi
    
    # Rule 4: SSH key change + Failed login
    local ssh_key_changes=$(echo "$recent_events_json" | grep -o '"event_type":"ssh_key_change"' | wc -l | tr -d ' ')
    local ssh_failures=$(echo "$recent_events_json" | grep -o '"event_type":"ssh_login_failure"' | wc -l | tr -d ' ')
    if [ "$ssh_key_changes" -gt 0 ] && [ "$ssh_failures" -gt 0 ]; then
        local context_json="{\"rule\": \"ssh_compromise_indicator\", \"ssh_key_changes\": $ssh_key_changes, \"failed_logins\": $ssh_failures, \"time_window\": $CORRELATION_WINDOW}"
        write_event "ids_alert" "critical" "ids_engine" "$context_json"
        create_incident "correlation" "critical" "SSH key changed and failed login attempts detected" "$context_json"
    fi
    
    # Rule 5: New admin account + Cron modification
    local user_changes=$(echo "$recent_events_json" | grep -o '"event_type":"user_account_change"' | wc -l | tr -d ' ')
    local cron_changes=$(echo "$recent_events_json" | grep -o '"event_type":"cron_modification"' | wc -l | tr -d ' ')
    if [ "$user_changes" -gt 0 ] && [ "$cron_changes" -gt 0 ]; then
        local context_json="{\"rule\": \"admin_cron_modification\", \"user_changes\": $user_changes, \"cron_changes\": $cron_changes, \"time_window\": $CORRELATION_WINDOW}"
        write_event "ids_alert" "high" "ids_engine" "$context_json"
        create_incident "correlation" "high" "User account change and cron modification detected" "$context_json"
    fi
}

# Create incident
create_incident() {
    local incident_type="$1"
    local severity="$2"
    local description="$3"
    local details="$4"
    
    local incident_id
    if command -v uuidgen &> /dev/null; then
        incident_id=$(uuidgen)
    else
        incident_id="$(date +%s)-$(shasum -a 256 <<< "$incident_type$severity$description" | cut -c1-32)"
    fi
    
    local incident_file="$INCIDENTS_DIR/incident_${incident_id}.json"
    
    cat > "$incident_file" <<EOF
{
  "id": "$incident_id",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "$incident_type",
  "severity": "$severity",
  "description": "$description",
  "details": $details,
  "status": "open"
}
EOF
    
    log_detector "ids_engine" "ALERT" "IDS Incident created: $description"
    echo "🚨 IDS Alert: $description"
}

export -f run_ids_correlation
export -f create_incident

