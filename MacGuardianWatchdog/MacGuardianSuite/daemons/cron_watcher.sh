#!/bin/bash

# ===============================
# Cron Watcher
# Real-time cron job monitoring
# Event Spec v1.0.0 compliant
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source core modules
source "$SUITE_DIR/core/validators.sh" 2>/dev/null || true
source "$SUITE_DIR/core/logging.sh" 2>/dev/null || true
source "$SUITE_DIR/core/system_state.sh" 2>/dev/null || true
source "$SCRIPT_DIR/event_writer.sh" 2>/dev/null || true

# Configuration
CRON_BASELINE="$HOME/.macguardian/baselines/cron_baseline.json"
CRON_CHECK_INTERVAL=300  # Check every 5 minutes
LAST_CRON_CHECK="$HOME/.macguardian/.cron_last_check"

# Suspicious patterns
SUSPICIOUS_PATTERNS=(
    "wget.*http"
    "curl.*http"
    "python.*-c"
    "bash.*-c"
    "sh.*-c"
    "base64.*decode"
    "eval.*\\$"
)

# ===============================
# Get Current Cron Jobs
# ===============================

get_current_cron_jobs() {
    local jobs=()
    
    # System crontab (requires sudo)
    if [ "$EUID" -eq 0 ] && [ -f "/etc/crontab" ]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^[^#]*[0-9] ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
                jobs+=("system:$line")
            fi
        done < /etc/crontab
    fi
    
    # User crontabs
    for user in $(cut -d: -f1 /etc/passwd 2>/dev/null | head -20); do
        local user_cron=$(crontab -u "$user" -l 2>/dev/null || echo "")
        if [ -n "$user_cron" ]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ^[^#]*[0-9] ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
                    jobs+=("user:$user:$line")
                fi
            done <<< "$user_cron"
        fi
    done
    
    # Current user crontab
    local my_cron=$(crontab -l 2>/dev/null || echo "")
    if [ -n "$my_cron" ]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^[^#]*[0-9] ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
                jobs+=("user:$(whoami):$line")
            fi
        done <<< "$my_cron"
    fi
    
    # LaunchAgents and LaunchDaemons (cron-like)
    find "$HOME/Library/LaunchAgents" -name "*.plist" -type f 2>/dev/null | while read -r plist; do
        local label=$(defaults read "$plist" Label 2>/dev/null || echo "")
        local program=$(defaults read "$plist" ProgramArguments 2>/dev/null | head -1 || echo "")
        if [ -n "$label" ] && [ -n "$program" ]; then
            jobs+=("launchagent:$label:$program")
        fi
    done
    
    printf '%s\n' "${jobs[@]}"
}

# ===============================
# Create Baseline
# ===============================

create_cron_baseline() {
    mkdir -p "$(dirname "$CRON_BASELINE")"
    
    local jobs
    jobs=$(get_current_cron_jobs)
    
    local job_array="["
    local first=true
    while IFS= read -r job; do
        if [ -n "$job" ]; then
            if [ "$first" = true ]; then
                first=false
            else
                job_array="$job_array,"
            fi
            local escaped_job=$(echo "$job" | sed 's/"/\\"/g')
            job_array="$job_array\"$escaped_job\""
        fi
    done <<< "$jobs"
    job_array="$job_array]"
    
    echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"jobs\": $job_array}" > "$CRON_BASELINE"
    log_watcher "cron_watcher" "INFO" "Cron baseline created with $(echo "$jobs" | wc -l | tr -d ' ') jobs"
}

# ===============================
# Detect Cron Changes
# ===============================

detect_cron_changes() {
    local current_time=$(date +%s)
    local last_check=$(cat "$LAST_CRON_CHECK" 2>/dev/null || echo "0")
    
    # Only check every CRON_CHECK_INTERVAL seconds
    if [ $((current_time - last_check)) -lt $CRON_CHECK_INTERVAL ]; then
        return 0
    fi
    
    echo "$current_time" > "$LAST_CRON_CHECK"
    
    # Create baseline if it doesn't exist
    if [ ! -f "$CRON_BASELINE" ]; then
        create_cron_baseline
        return 0
    fi
    
    # Get current jobs
    local current_jobs
    current_jobs=$(get_current_cron_jobs)
    
    # Load baseline
    local baseline_jobs
    baseline_jobs=$(grep -o '"[^"]*"' "$CRON_BASELINE" 2>/dev/null | sed 's/"//g' || echo "")
    
    # Compare jobs
    while IFS= read -r current_job; do
        if [ -z "$current_job" ]; then
            continue
        fi
        
        # Check if job is new
        local found=false
        while IFS= read -r baseline_job; do
            if [ "$current_job" = "$baseline_job" ]; then
                found=true
                break
            fi
        done <<< "$baseline_jobs"
        
        if [ "$found" = false ]; then
            # New cron job detected
            local severity="medium"
            local suspicious=false
            
            # Check for suspicious patterns
            for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
                if echo "$current_job" | grep -qiE "$pattern"; then
                    suspicious=true
                    severity="high"
                    break
                fi
            done
            
            # Determine change type
            local change_type="added"
            local job_type=$(echo "$current_job" | cut -d: -f1)
            local job_content=$(echo "$current_job" | cut -d: -f2-)
            
            # Create context JSON
            local context_json="{\"change_type\": \"$change_type\", \"job_type\": \"$job_type\", \"job\": \"$job_content\", \"suspicious_pattern\": $suspicious"
            
            if [ "$job_type" = "user" ]; then
                local username=$(echo "$current_job" | cut -d: -f2)
                context_json="$context_json, \"username\": \"$username\""
            fi
            
            context_json="$context_json}"
            
            write_event "cron_modification" "$severity" "cron_watcher" "$context_json"
            log_watcher "cron_watcher" "WARNING" "New cron job detected: $job_content"
        fi
    done <<< "$current_jobs"
    
    # Check for removed jobs
    while IFS= read -r baseline_job; do
        if [ -z "$baseline_job" ]; then
            continue
        fi
        
        local found=false
        while IFS= read -r current_job; do
            if [ "$baseline_job" = "$current_job" ]; then
                found=true
                break
            fi
        done <<< "$current_jobs"
        
        if [ "$found" = false ]; then
            # Cron job removed
            local job_type=$(echo "$baseline_job" | cut -d: -f1)
            local job_content=$(echo "$baseline_job" | cut -d: -f2-)
            
            local context_json="{\"change_type\": \"removed\", \"job_type\": \"$job_type\", \"job\": \"$job_content\"}"
            
            if [ "$job_type" = "user" ]; then
                local username=$(echo "$baseline_job" | cut -d: -f2)
                context_json="$context_json, \"username\": \"$username\""
            fi
            
            context_json="$context_json}"
            
            write_event "cron_modification" "medium" "cron_watcher" "$context_json"
            log_watcher "cron_watcher" "INFO" "Cron job removed: $job_content"
        fi
    done <<< "$baseline_jobs"
    
    # Update baseline
    create_cron_baseline
}

# Check system compatibility on load
check_system_compatibility 2>/dev/null || true

# Export function
export -f detect_cron_changes

