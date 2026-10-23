#!/bin/bash

# ===============================
# Process Watcher
# Real-time process anomaly detection
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

# Baseline for process count
BASELINE_FILE="$HOME/.macguardian/.process_baseline"
PROCESS_CHECK_INTERVAL=30  # Check every 30 seconds
LAST_PROCESS_CHECK="$HOME/.macguardian/.process_last_check"

function detect_suspicious_processes() {
    local current_time=$(date +%s)
    local last_check=$(cat "$LAST_PROCESS_CHECK" 2>/dev/null || echo "0")
    
    # Only check every PROCESS_CHECK_INTERVAL seconds
    if [ $((current_time - last_check)) -lt $PROCESS_CHECK_INTERVAL ]; then
        return 0
    fi
    
    echo "$current_time" > "$LAST_PROCESS_CHECK"
    
    # Get current process count
    local process_count=$(ps aux | wc -l | tr -d ' ')
    
    # Load baseline
    local baseline_count=$(cat "$BASELINE_FILE" 2>/dev/null || echo "$process_count")
    
    # Update baseline if it doesn't exist or is very old
    if [ ! -f "$BASELINE_FILE" ] || [ -z "$baseline_count" ]; then
        echo "$process_count" > "$BASELINE_FILE"
        return 0
    fi
    
    # Check for significant process count changes (>50% increase)
    local diff=$((process_count - baseline_count))
    local percent_change=0
    if [ "$baseline_count" -gt 0 ]; then
        percent_change=$((diff * 100 / baseline_count))
    fi
    
    if [ ${percent_change#-} -gt 50 ]; then
        local context_json="{\"process_count\": $process_count, \"baseline_count\": $baseline_count, \"change_percent\": $percent_change, \"anomaly_type\": \"process_count_spike\"}"
        write_event "process_anomaly" "medium" "process_watcher" "$context_json"
        log_watcher "process_watcher" "WARNING" "Process count spike detected: $process_count (baseline: $baseline_count)"
    fi
    
    # Check for high CPU processes (using awk for portability)
    ps -eo pid,pcpu,comm,args 2>/dev/null | awk 'NR>1 && $2 > 80 {
        # Skip known system processes
        if ($3 !~ /(kernel_task|WindowServer|mds|mdworker|Spotlight|TimeMachine|biomesyncd)/) {
            print $1 "|" $2 "|" $3 "|" substr($0, index($0,$4))
        }
    }' | while IFS='|' read -r pid cpu comm args; do
        if [ -n "$pid" ] && [ -n "$cpu" ]; then
            # Escape args for JSON
            local escaped_args=$(echo "$args" | sed 's/"/\\"/g' | head -c 200)
            local context_json="{\"pid\": $pid, \"cpu_percent\": $cpu, \"process_name\": \"$comm\", \"command\": \"$escaped_args\", \"anomaly_type\": \"high_cpu\"}"
            write_event "process_anomaly" "high" "process_watcher" "$context_json"
            log_watcher "process_watcher" "WARNING" "High CPU process: $comm (PID: $pid, CPU: $cpu%)"
        fi
    done
    
    # Check for suspicious process patterns
    ps -eo pid,comm,args 2>/dev/null | awk 'NR>1 {
        comm = $2
        args = substr($0, index($0,$3))
        
        # Suspicious patterns (but exclude known safe uses)
        if (comm ~ /(curl|nc|nmap|python3|osascript|sh|bash|zsh)/ && 
            args !~ /(brew|pip|npm|node|MacGuardian|system)/) {
            print $1 "|" comm "|" args
        }
    }' | while IFS='|' read -r pid comm args; do
        if [ -n "$pid" ] && [ -n "$comm" ]; then
            local escaped_args=$(echo "$args" | sed 's/"/\\"/g' | head -c 200)
            local context_json="{\"pid\": $pid, \"process_name\": \"$comm\", \"command\": \"$escaped_args\", \"anomaly_type\": \"suspicious_pattern\"}"
            write_event "process_anomaly" "medium" "process_watcher" "$context_json"
            log_watcher "process_watcher" "INFO" "Suspicious process pattern: $comm (PID: $pid)"
        fi
    done
    
    # Check for processes with suspicious names
    ps -eo pid,comm 2>/dev/null | grep -iE "(miner|crypto|bitcoin|malware|trojan|backdoor|keylogger)" | while read -r pid comm; do
        if [ -n "$pid" ]; then
            local context_json="{\"pid\": $pid, \"process_name\": \"$comm\", \"anomaly_type\": \"suspicious_name\"}"
            write_event "process_anomaly" "critical" "process_watcher" "$context_json"
            log_watcher "process_watcher" "CRITICAL" "Suspicious process name detected: $comm (PID: $pid)"
        fi
    done
}

# Check system compatibility on load
check_system_compatibility 2>/dev/null || true

export -f detect_suspicious_processes

