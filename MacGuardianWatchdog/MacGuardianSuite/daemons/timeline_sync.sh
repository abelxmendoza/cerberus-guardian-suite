#!/bin/zsh

# ===============================
# Timeline Synchronizer
# Aggregates events from all sources into unified timeline
# ===============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

EVENT_DIR="$HOME/.macguardian/events"
TIMELINE_FILE="$HOME/.macguardian/timeline.json"
TIMELINE_PYTHON="$SUITE_DIR/outputs/timeline_formatter.py"

# Sync timeline using Python formatter if available
if [ -f "$TIMELINE_PYTHON" ] && command -v python3 &> /dev/null; then
    python3 "$TIMELINE_PYTHON" "$EVENT_DIR" "$TIMELINE_FILE" 2>/dev/null || true
else
    # Fallback: simple JSON aggregation
    echo "[]" > "$TIMELINE_FILE"
    
    if [ -d "$EVENT_DIR" ]; then
        local temp_timeline=$(mktemp)
        echo "[" > "$temp_timeline"
        local first=true
        
        find "$EVENT_DIR" -name "event_*.json" -type f -exec cat {} \; 2>/dev/null | while IFS= read -r line; do
            if [ -n "$line" ]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> "$temp_timeline"
                fi
                echo "$line" >> "$temp_timeline"
            fi
        done
        
        echo "]" >> "$temp_timeline"
        mv "$temp_timeline" "$TIMELINE_FILE" 2>/dev/null || true
    fi
fi

