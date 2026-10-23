#!/bin/bash

# ===============================
# FSEvents Watcher
# Real-time file system change detection
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

# Watch directories (configurable)
WATCH_DIRS=(
    "$HOME/Documents"
    "$HOME/Downloads"
    "$HOME/Desktop"
    "$HOME/.ssh"
)

# Last check timestamp file
LAST_CHECK_FILE="$HOME/.macguardian/.fsevents_last_check"

# Initialize last check time
if [ ! -f "$LAST_CHECK_FILE" ]; then
    echo "$(date +%s)" > "$LAST_CHECK_FILE"
fi

# Check system compatibility
check_system_compatibility 2>/dev/null || true

function detect_fs_changes() {
    local current_time=$(date +%s)
    local last_check=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "$current_time")
    
    # Check each directory for recent changes
    for dir in "${WATCH_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi
        
        # Find files modified since last check
        # Use stat to check modification time
        local recent_files=$(find "$dir" -type f -print0 2>/dev/null | xargs -0 stat -f "%m %N" 2>/dev/null | awk -v last="$last_check" '$1 > last {print $2}' | head -20)
        
        if [ -n "$recent_files" ]; then
            local file_count=$(echo "$recent_files" | wc -l | tr -d ' ')
            
            # Only alert on significant changes (more than 5 files)
            if [ "$file_count" -gt 5 ] 2>/dev/null; then
                # Build JSON array of changed files (first 10)
                local files_array=()
                while IFS= read -r file && [ ${#files_array[@]} -lt 10 ]; do
                    if validate_path "$file" true; then
                        files_array+=("\"$(echo "$file" | sed 's/"/\\"/g')\"")
                    fi
                done <<< "$recent_files"
                
                # Create context JSON (Event Spec v1.0.0)
                local context_json="{\"directory\": \"$dir\", \"file_count\": $file_count, \"files\": [$(IFS=,; echo "${files_array[*]}")], \"change_type\": \"modified\"}"
                
                # Determine severity based on file count
                local severity="medium"
                if [ "$file_count" -gt 50 ]; then
                    severity="high"
                elif [ "$file_count" -gt 100 ]; then
                    severity="critical"
                fi
                
                # Write Event Spec v1.0.0 compliant event
                write_event "file_integrity_change" "$severity" "fsevents_watcher" "$context_json"
                log_watcher "fsevents_watcher" "INFO" "Detected $file_count file changes in $dir"
            fi
            
            # Check for suspicious file types
            local suspicious=$(echo "$recent_files" | grep -E '\.(exe|bat|scr|vbs|ps1|sh)$' 2>/dev/null | head -5)
            if [ -n "$suspicious" ]; then
                local sus_files_array=()
                while IFS= read -r file && [ ${#sus_files_array[@]} -lt 5 ]; do
                    if validate_path "$file" true; then
                        sus_files_array+=("\"$(echo "$file" | sed 's/"/\\"/g')\"")
                    fi
                done <<< "$suspicious"
                
                local context_json="{\"directory\": \"$dir\", \"files\": [$(IFS=,; echo "${sus_files_array[*]}")], \"change_type\": \"created\", \"suspicious_pattern\": \"executable_extension\"}"
                
                write_event "file_integrity_change" "high" "fsevents_watcher" "$context_json"
                log_watcher "fsevents_watcher" "WARNING" "Suspicious file types detected in $dir"
            fi
        fi
    done
    
    # Update last check time
    echo "$current_time" > "$LAST_CHECK_FILE"
}

export -f detect_fs_changes

