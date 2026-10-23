#!/bin/zsh

# ===============================
# MacGuardian Real-Time Monitor
# Continuous background daemon for real-time security monitoring
# ===============================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration directories
EVENT_DIR="$HOME/.macguardian/events"
LOG_DIR="$HOME/.macguardian/logs"
mkdir -p "$EVENT_DIR" "$LOG_DIR"

LOG="$LOG_DIR/monitor.log"
PID_FILE="$HOME/.macguardian/.monitor.pid"

# Logging function
function log() {
    local level="${2:-INFO}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $1" | tee -a "$LOG"
}

# Trap signals for graceful shutdown
trap 'log "Monitor daemon shutting down..." "INFO"; exit 0' TERM INT

# Check if already running
if [ -f "$PID_FILE" ]; then
    local old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        log "Monitor daemon already running (PID: $old_pid)" "WARNING"
        exit 1
    fi
fi

# Write PID file
echo $$ > "$PID_FILE"

# Source watcher modules
source "$SCRIPT_DIR/event_writer.sh" 2>/dev/null || {
    log "Failed to load event_writer.sh" "ERROR"
    exit 1
}

source "$SCRIPT_DIR/fsevents_watcher.sh" 2>/dev/null || {
    log "Failed to load fsevents_watcher.sh" "ERROR"
    exit 1
}

source "$SCRIPT_DIR/process_watcher.sh" 2>/dev/null || {
    log "Failed to load process_watcher.sh" "ERROR"
    exit 1
}

source "$SCRIPT_DIR/network_watcher.sh" 2>/dev/null || {
    log "Failed to load network_watcher.sh" "ERROR"
    exit 1
}

log "🚀 MacGuardian Monitor starting (PID: $$)" "INFO"
log "Event directory: $EVENT_DIR" "INFO"
log "Log directory: $LOG_DIR" "INFO"

# Write startup event
write_event "system" "info" "MacGuardian Monitor daemon started" "{\"pid\": $$, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

# Main event loop
LOOP_COUNT=0
while true; do
    LOOP_COUNT=$((LOOP_COUNT + 1))
    
    # Run monitoring checks (with error handling)
    set +e  # Don't exit on errors in monitoring functions
    
    # Real-time FSEvents file change detection
    detect_fs_changes 2>&1 | while IFS= read -r line; do
        if [ -n "$line" ]; then
            log "FSEvents: $line" "DEBUG"
        fi
    done
    
    # Real-time suspicious process detection
    detect_suspicious_processes 2>&1 | while IFS= read -r line; do
        if [ -n "$line" ]; then
            log "Process: $line" "DEBUG"
        fi
    done
    
    # Real-time network anomaly detection
    detect_network_anomalies 2>&1 | while IFS= read -r line; do
        if [ -n "$line" ]; then
            log "Network: $line" "DEBUG"
        fi
    done
    
    set -e  # Re-enable exit on error
    
    # Log heartbeat every 100 loops (~5 minutes at 3 second intervals)
    if [ $((LOOP_COUNT % 100)) -eq 0 ]; then
        log "Monitor heartbeat - Loop $LOOP_COUNT" "INFO"
    fi
    
    # Sleep for CPU friendliness (adjust based on system load)
    sleep 3
done

# Cleanup on exit
rm -f "$PID_FILE"
log "Monitor daemon stopped" "INFO"
exit 0

