#!/bin/bash

# ===============================
# Error Tracking System
# Centralized error logging and tracking for Mac Guardian Suite
# ===============================

# Error database file (structured format)
ERROR_DB="${ERROR_DB:-$HOME/.macguardian/errors/error_database.jsonl}"
ERROR_DB_DIR="$(dirname "$ERROR_DB")"
mkdir -p "$ERROR_DB_DIR" 2>/dev/null || true

# Error statistics
ERROR_STATS="${ERROR_STATS:-$HOME/.macguardian/errors/error_stats.txt}"

# Initialize error database if it doesn't exist
init_error_db() {
    mkdir -p "$ERROR_DB_DIR" 2>/dev/null || true
    touch "$ERROR_DB" 2>/dev/null || true
    touch "$ERROR_STATS" 2>/dev/null || true
}

# Track an error with full metadata
# Usage: track_error "error_message" "script_name" "line_number" "error_type" "severity" "fixable" "fix_command"
track_error() {
    local error_msg="${1:-Unknown error}"
    local script_name="${2:-unknown}"
    local line_number="${3:-0}"
    local error_type="${4:-general}"
    local severity="${5:-medium}"  # low, medium, high, critical
    local fixable="${6:-false}"    # true or false
    local fix_command="${7:-}"    # Command to fix the error (if fixable)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
    local error_id=$(echo "$script_name:$line_number:$timestamp" | shasum -a 256 | cut -d' ' -f1 | head -c 16)
    
    # Create structured error entry (JSON-like format for easy parsing)
    local error_entry=$(cat <<EOF
{
  "id": "$error_id",
  "timestamp": "$timestamp",
  "script": "$script_name",
  "line": "$line_number",
  "type": "$error_type",
  "severity": "$severity",
  "message": "$(echo "$error_msg" | sed 's/"/\\"/g')",
  "fixable": "$fixable",
  "fix_command": "$(echo "$fix_command" | sed 's/"/\\"/g')",
  "status": "unresolved",
  "resolved_at": "",
  "resolved_by": ""
}
EOF
)
    
    # Append to error database
    echo "$error_entry" >> "$ERROR_DB" 2>/dev/null || {
        # Fallback: use simple text format
        echo "[$timestamp] [$severity] $script_name:$line_number - $error_type: $error_msg" >> "$ERROR_DB" 2>/dev/null || true
    }
    
    # Update statistics
    update_error_stats "$error_type" "$severity" "$fixable"
    
    # Also log to standard log
    log_message "ERROR" "$script_name:$line_number - $error_msg"
}

# Update error statistics
update_error_stats() {
    local error_type="$1"
    local severity="$2"
    local fixable="$3"
    
    # Simple text-based stats (more compatible than complex parsing)
    local stats_file="$ERROR_STATS"
    local date=$(date '+%Y-%m-%d' 2>/dev/null || echo "unknown")
    
    # Count errors by type
    echo "$date|$error_type|$severity|$fixable" >> "$stats_file" 2>/dev/null || true
}

# Get all unresolved errors
get_unresolved_errors() {
    if [ ! -f "$ERROR_DB" ]; then
        return 0
    fi
    
    # Try to parse JSON lines, fallback to text parsing
    if command -v python3 &> /dev/null; then
        python3 <<PYEOF 2>/dev/null || grep -v '"status": "resolved"' "$ERROR_DB" 2>/dev/null || true
import json
import sys

try:
    with open("$ERROR_DB", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                error = json.loads(line)
                if error.get("status") != "resolved":
                    print(line)
            except:
                pass
except:
    pass
PYEOF
    else
        # Fallback: simple grep
        grep -v '"status": "resolved"' "$ERROR_DB" 2>/dev/null || true
    fi
}

# Get errors by severity
get_errors_by_severity() {
    local severity="$1"
    
    if [ ! -f "$ERROR_DB" ]; then
        return 0
    fi
    
    if command -v python3 &> /dev/null; then
        python3 <<PYEOF 2>/dev/null || grep "\"severity\": \"$severity\"" "$ERROR_DB" 2>/dev/null || true
import json
import sys

try:
    with open("$ERROR_DB", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                error = json.loads(line)
                if error.get("severity") == "$severity" and error.get("status") != "resolved":
                    print(line)
            except:
                pass
except:
    pass
PYEOF
    else
        grep "\"severity\": \"$severity\"" "$ERROR_DB" 2>/dev/null | grep -v '"status": "resolved"' || true
    fi
}

# Get fixable errors
get_fixable_errors() {
    if [ ! -f "$ERROR_DB" ]; then
        return 0
    fi
    
    if command -v python3 &> /dev/null; then
        python3 <<PYEOF 2>/dev/null || grep '"fixable": "true"' "$ERROR_DB" 2>/dev/null || true
import json
import sys

try:
    with open("$ERROR_DB", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                error = json.loads(line)
                if error.get("fixable") == "true" and error.get("status") != "resolved":
                    print(line)
            except:
                pass
except:
    pass
PYEOF
    else
        grep '"fixable": "true"' "$ERROR_DB" 2>/dev/null | grep -v '"status": "resolved"' || true
    fi
}

# Mark error as resolved
resolve_error() {
    local error_id="$1"
    local resolved_by="${2:-manual}"
    
    if [ ! -f "$ERROR_DB" ]; then
        return 1
    fi
    
    local temp_file=$(mktemp)
    local resolved_at=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
    
    if command -v python3 &> /dev/null; then
        python3 <<PYEOF 2>/dev/null || return 1
import json
import sys

try:
    with open("$ERROR_DB", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                error = json.loads(line)
                if error.get("id") == "$error_id":
                    error["status"] = "resolved"
                    error["resolved_at"] = "$resolved_at"
                    error["resolved_by"] = "$resolved_by"
                print(json.dumps(error))
            except:
                print(line)
except:
    pass
PYEOF
    else
        # Fallback: simple sed replacement
        sed "s/\"id\": \"$error_id\"/\"id\": \"$error_id\", \"status\": \"resolved\", \"resolved_at\": \"$resolved_at\", \"resolved_by\": \"$resolved_by\"/" "$ERROR_DB" > "$temp_file" 2>/dev/null && mv "$temp_file" "$ERROR_DB" 2>/dev/null || return 1
    fi
}

# Auto-fix an error if fix command is available
auto_fix_error() {
    local error_id="$1"
    
    if [ ! -f "$ERROR_DB" ]; then
        return 1
    fi
    
    # Get error details
    local error_data=""
    if command -v python3 &> /dev/null; then
        error_data=$(python3 <<PYEOF 2>/dev/null
import json
import sys

try:
    with open("$ERROR_DB", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                error = json.loads(line)
                if error.get("id") == "$error_id":
                    if error.get("fixable") == "true" and error.get("fix_command"):
                        print(error.get("fix_command", ""))
                        sys.exit(0)
            except:
                pass
except:
    pass
PYEOF
)
    fi
    
    if [ -n "$error_data" ] && [ -n "$error_data" ]; then
        # Execute fix command
        eval "$error_data" && {
            resolve_error "$error_id" "auto-fix"
            return 0
        }
    fi
    
    return 1
}

# Display error summary
show_error_summary() {
    local total_errors=0
    local critical_errors=0
    local high_errors=0
    local fixable_errors=0
    
    if [ ! -f "$ERROR_DB" ]; then
        echo "No errors recorded."
        return 0
    fi
    
    # Count errors
    if command -v python3 &> /dev/null; then
        local counts=$(python3 <<PYEOF 2>/dev/null
import json

total = 0
critical = 0
high = 0
fixable = 0

try:
    with open("$ERROR_DB", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                error = json.loads(line)
                if error.get("status") != "resolved":
                    total += 1
                    if error.get("severity") == "critical":
                        critical += 1
                    elif error.get("severity") == "high":
                        high += 1
                    if error.get("fixable") == "true":
                        fixable += 1
            except:
                pass
except:
    pass

print(f"{total}|{critical}|{high}|{fixable}")
PYEOF
)
        total_errors=$(echo "$counts" | cut -d'|' -f1)
        critical_errors=$(echo "$counts" | cut -d'|' -f2)
        high_errors=$(echo "$counts" | cut -d'|' -f3)
        fixable_errors=$(echo "$counts" | cut -d'|' -f4)
    else
        # Fallback: simple grep counting
        total_errors=$(grep -v '"status": "resolved"' "$ERROR_DB" 2>/dev/null | wc -l | tr -d ' ')
        critical_errors=$(grep '"severity": "critical"' "$ERROR_DB" 2>/dev/null | grep -v '"status": "resolved"' | wc -l | tr -d ' ')
        high_errors=$(grep '"severity": "high"' "$ERROR_DB" 2>/dev/null | grep -v '"status": "resolved"' | wc -l | tr -d ' ')
        fixable_errors=$(grep '"fixable": "true"' "$ERROR_DB" 2>/dev/null | grep -v '"status": "resolved"' | wc -l | tr -d ' ')
    fi
    
    echo "Error Summary:"
    echo "  Total unresolved: $total_errors"
    echo "  Critical: $critical_errors"
    echo "  High: $high_errors"
    echo "  Auto-fixable: $fixable_errors"
}

# Enhanced error logging function that also tracks
track_and_log_error() {
    local error_msg="$1"
    local script_name="${2:-${BASH_SOURCE[1]:-unknown}}"
    local line_number="${3:-${BASH_LINENO[0]:-0}}"
    local error_type="${4:-general}"
    local severity="${5:-medium}"
    local fixable="${6:-false}"
    local fix_command="${7:-}"
    
    # Track in error database
    track_error "$error_msg" "$(basename "$script_name")" "$line_number" "$error_type" "$severity" "$fixable" "$fix_command"
    
    # Also log to standard log
    log_message "ERROR" "$error_msg"
}

# Initialize on load
init_error_db

