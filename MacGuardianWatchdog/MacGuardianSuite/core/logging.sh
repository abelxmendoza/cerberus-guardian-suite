#!/bin/bash

# ===============================
# Unified Logging System
# Structured logging with rotation
# ===============================

set -euo pipefail

LOG_DIR="$HOME/.macguardian/logs"
MAX_LOG_SIZE=5242880  # 5MB
LOG_RETENTION_DAYS=7

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# ===============================
# Log Files
# ===============================

LOG_CORE="$LOG_DIR/core.log"
LOG_WATCHERS="$LOG_DIR/watchers.log"
LOG_AUDITORS="$LOG_DIR/auditors.log"
LOG_DETECTORS="$LOG_DIR/detectors.log"
LOG_PRIVACY="$LOG_DIR/privacy.log"
LOG_NETWORK="$LOG_DIR/network.log"
LOG_TIMELINE="$LOG_DIR/timeline.jsonl"
LOG_INCIDENTS="$LOG_DIR/incidents.jsonl"

# ===============================
# Log Rotation
# ===============================

rotate_log_if_needed() {
    local log_file="$1"
    
    if [ ! -f "$log_file" ]; then
        return 0
    fi
    
    local file_size=$(stat -f%z "$log_file" 2>/dev/null || echo "0")
    
    if [ "$file_size" -gt "$MAX_LOG_SIZE" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local rotated_file="${log_file}.${timestamp}"
        mv "$log_file" "$rotated_file" 2>/dev/null || true
        
        # Compress old log
        gzip "$rotated_file" 2>/dev/null || true
    fi
}

# ===============================
# Clean Old Logs
# ===============================

clean_old_logs() {
    find "$LOG_DIR" -name "*.log.*" -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
    find "$LOG_DIR" -name "*.jsonl.*" -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
    find "$LOG_DIR" -name "*.gz" -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
}

# ===============================
# Structured Logging Functions
# ===============================

log_core() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    rotate_log_if_needed "$LOG_CORE"
    
    echo "[$timestamp] [$level] $message" >> "$LOG_CORE"
}

log_watcher() {
    local watcher_name="$1"
    local level="$2"
    shift 2
    local message="$*"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    rotate_log_if_needed "$LOG_WATCHERS"
    
    echo "[$timestamp] [$watcher_name] [$level] $message" >> "$LOG_WATCHERS"
}

log_auditor() {
    local auditor_name="$1"
    local level="$2"
    shift 2
    local message="$*"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    rotate_log_if_needed "$LOG_AUDITORS"
    
    echo "[$timestamp] [$auditor_name] [$level] $message" >> "$LOG_AUDITORS"
}

log_detector() {
    local detector_name="$1"
    local level="$2"
    shift 2
    local message="$*"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    rotate_log_if_needed "$LOG_DETECTORS"
    
    echo "[$timestamp] [$detector_name] [$level] $message" >> "$LOG_DETECTORS"
}

log_router() {
    local router_name="$1"
    local level="$2"
    shift 2
    local message="$*"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    rotate_log_if_needed "$LOG_CORE"
    
    echo "[$timestamp] [ROUTER] [$router_name] [$level] $message" >> "$LOG_CORE"
}

# ===============================
# JSON Event Logging
# ===============================

log_json_event() {
    local event_json="$1"
    local log_file="${2:-$LOG_TIMELINE}"
    
    rotate_log_if_needed "$log_file"
    
    echo "$event_json" >> "$log_file"
}

log_incident() {
    local incident_json="$1"
    
    rotate_log_if_needed "$LOG_INCIDENTS"
    
    echo "$incident_json" >> "$LOG_INCIDENTS"
}

# ===============================
# Log Levels
# ===============================

log_info() {
    log_core "INFO" "$@"
}

log_warning() {
    log_core "WARNING" "$@"
}

log_error() {
    log_core "ERROR" "$@"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        log_core "DEBUG" "$@"
    fi
}

# Clean old logs on load
clean_old_logs

# Export functions
export -f rotate_log_if_needed
export -f clean_old_logs
export -f log_core
export -f log_watcher
export -f log_auditor
export -f log_detector
export -f log_router
export -f log_json_event
export -f log_incident
export -f log_info
export -f log_warning
export -f log_error
export -f log_debug

