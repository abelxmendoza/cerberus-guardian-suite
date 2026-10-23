#!/bin/bash

# ===============================
# Ransomware Detector
# Detects potential ransomware activity
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

TIMELINE_FILE="$HOME/.macguardian/logs/timeline.jsonl"
INCIDENTS_DIR="$HOME/.macguardian/incidents"
THRESHOLD_FILES=50  # Files changed in short time
THRESHOLD_TIME=60   # Seconds

mkdir -p "$INCIDENTS_DIR" "$(dirname "$TIMELINE_FILE")"

# Detect ransomware patterns
detect_ransomware() {
    if [ ! -f "$TIMELINE_FILE" ]; then
        return 0
    fi
    
    local window_start=$(date -u -v-${THRESHOLD_TIME}S +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "$THRESHOLD_TIME seconds ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
    
    # Count file changes in time window
    local file_changes=0
    local encryption_patterns=0
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local event_timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4 || echo "")
        local event_type=$(echo "$line" | grep -o '"event_type":"[^"]*"' | cut -d'"' -f4 || echo "")
        
        if [ -n "$event_timestamp" ] && [ "$event_timestamp" \> "$window_start" ]; then
            if [ "$event_type" = "file_integrity_change" ]; then
                file_changes=$((file_changes + 1))
                
                # Check for encryption patterns in context
                if echo "$line" | grep -qiE '(encrypt|ransom|\.encrypted|\.locked)'; then
                    encryption_patterns=$((encryption_patterns + 1))
                fi
            fi
        fi
    done < "$TIMELINE_FILE"
    
    if [ "$file_changes" -ge "$THRESHOLD_FILES" ]; then
        log_detector "ransomware_detector" "CRITICAL" "🚨 RANSOMWARE INDICATOR: $file_changes file changes in $THRESHOLD_TIME seconds"
        
        # Emit Event Spec v1.0.0 event
        local context_json="{\"file_changes\": $file_changes, \"time_window\": $THRESHOLD_TIME, \"encryption_patterns\": $encryption_patterns}"
        write_event "ransomware_activity" "critical" "ransomware_detector" "$context_json"
        
        if [ "$encryption_patterns" -gt 0 ]; then
            create_ransomware_incident "$file_changes" "$encryption_patterns"
            return 1
        fi
    fi
    
    return 0
}

# Create ransomware incident
create_ransomware_incident() {
    local file_count="$1"
    local encryption_count="$2"
    
    local incident_id
    if command -v uuidgen &> /dev/null; then
        incident_id=$(uuidgen)
    else
        incident_id="$(date +%s)-$(shasum -a 256 <<< "ransomware$file_count$encryption_count" | cut -c1-32)"
    fi
    local incident_file="$INCIDENTS_DIR/ransomware_${incident_id}.json"
    
    cat > "$incident_file" <<EOF
{
  "id": "$incident_id",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "ransomware",
  "severity": "critical",
  "description": "Potential ransomware activity detected",
  "details": {
    "file_changes": $file_count,
    "encryption_patterns": $encryption_count,
    "time_window": $THRESHOLD_TIME
  },
  "status": "open",
  "recommended_action": "Immediately disconnect from network and investigate"
}
EOF
    
    log_detector "ransomware_detector" "CRITICAL" "RANSOMWARE INCIDENT: $file_count file changes detected"
    echo "🚨🚨🚨 RANSOMWARE ALERT 🚨🚨🚨"
    echo "File changes: $file_count"
    echo "Encryption patterns: $encryption_count"
    echo "Incident file: $incident_file"
}

export -f detect_ransomware
export -f create_ransomware_incident

# Main execution
detect_ransomware

