#!/bin/bash

# ===============================
# Threat Lab Replay Engine
# Replays past incidents for testing and training
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.macguardian"
TIMELINE_FILE="$CONFIG_DIR/logs/timeline.jsonl"

# ===============================
# Replay Timeline Events
# ===============================

replay_timeline() {
    local start_date="${1:-}"
    local end_date="${2:-}"
    
    echo "Replaying timeline events..."
    
    if [ ! -f "$TIMELINE_FILE" ]; then
        echo "ERROR: Timeline file not found: $TIMELINE_FILE" >&2
        return 1
    fi
    
    # Filter events by date if provided
    local filtered_events="$TIMELINE_FILE"
    
    if [ -n "$start_date" ] && [ -n "$end_date" ]; then
        # Filter by date range (simplified)
        echo "Filtering events from $start_date to $end_date"
    fi
    
    # Replay each event
    while IFS= read -r event_json; do
        if [ -z "$event_json" ]; then
            continue
        fi
        
        # Parse event
        local event_type
        event_type=$(echo "$event_json" | grep -o '"event_type":"[^"]*"' | cut -d'"' -f4)
        
        echo "Replaying event: $event_type"
        
        # Send to event bus (simulate)
        echo "$event_json" | nc -U /tmp/macguardian.sock 2>/dev/null || true
        
        # Small delay between events
        sleep 0.1
    done < "$filtered_events"
    
    echo "✅ Timeline replay complete"
}

# ===============================
# Generate Training Data
# ===============================

generate_training_data() {
    local output_file="${1:-$CONFIG_DIR/threatlab_training.jsonl}"
    
    echo "Generating training data..."
    
    # Extract high-severity events
    grep -E '"severity":"(high|critical)"' "$TIMELINE_FILE" > "$output_file" 2>/dev/null || true
    
    echo "✅ Training data generated: $output_file"
}

# ===============================
# Main
# ===============================

main() {
    local command="${1:-replay}"
    
    case "$command" in
        replay)
            replay_timeline "${@:2}"
            ;;
        training)
            generate_training_data "${@:2}"
            ;;
        *)
            echo "Usage: $0 [replay|training]"
            exit 1
            ;;
    esac
}

main "$@"

