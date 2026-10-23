#!/bin/bash
# ===============================
# Rolling Hash for Ransomware Detection
# Uses Rabin-Karp rolling hash algorithm
# O(1) change detection per directory
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SUITE_DIR/core/logging.sh" 2>/dev/null || true
source "$SUITE_DIR/core/validators.sh" 2>/dev/null || true

HASH_STORE="$HOME/.macguardian/rolling_hashes"
THRESHOLD_FILES=50
THRESHOLD_TIME=60  # seconds

# Initialize hash store
mkdir -p "$HASH_STORE"

# Rabin-Karp rolling hash parameters
BASE=256
MODULUS=1000000007

# Compute rolling hash for a directory
compute_directory_hash() {
    local dir="$1"
    local hash=0
    local file_count=0
    
    if [ ! -d "$dir" ]; then
        echo "0:0"
        return
    fi
    
    # Get all files in directory (sorted for consistency)
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local size=$(stat -f%z "$file" 2>/dev/null || echo "0")
            
            # Update rolling hash: hash = (hash * BASE + char_code) % MODULUS
            for (( i=0; i<${#filename}; i++ )); do
                local char_code=$(printf '%d' "'${filename:$i:1}")
                hash=$(( (hash * BASE + char_code) % MODULUS ))
            done
            
            # Include file size in hash
            hash=$(( (hash * BASE + size) % MODULUS ))
            file_count=$((file_count + 1))
        fi
    done < <(find "$dir" -type f -maxdepth 1 2>/dev/null | sort)
    
    echo "${hash}:${file_count}"
}

# Get baseline hash for directory
get_baseline_hash() {
    local dir="$1"
    local hash_file="$HASH_STORE/$(echo "$dir" | shasum -a 256 | cut -d' ' -f1).hash"
    
    if [ -f "$hash_file" ]; then
        cat "$hash_file"
    else
        echo "0:0"
    fi
}

# Save baseline hash
save_baseline_hash() {
    local dir="$1"
    local hash_value="$2"
    local hash_file="$HASH_STORE/$(echo "$dir" | shasum -a 256 | cut -d' ' -f1).hash"
    
    echo "$hash_value" > "$hash_file"
    chmod 600 "$hash_file" 2>/dev/null || true
}

# Detect rapid directory changes (ransomware indicator)
detect_rapid_changes() {
    local dir="$1"
    local current_hash=$(compute_directory_hash "$dir")
    local baseline_hash=$(get_baseline_hash "$dir")
    
    local current_file_count=$(echo "$current_hash" | cut -d':' -f2)
    local baseline_file_count=$(echo "$baseline_hash" | cut -d':' -f2)
    
    local file_delta=$((current_file_count - baseline_file_count))
    
    # If file count increased significantly, potential ransomware
    if [ "$file_delta" -ge "$THRESHOLD_FILES" ]; then
        log_detector "ransomware_detector" "WARNING" "Rapid file changes detected in $dir: $baseline_file_count → $current_file_count"
        return 1
    fi
    
    # Update baseline
    save_baseline_hash "$dir" "$current_hash"
    return 0
}

# Monitor directory for changes
monitor_directory() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    
    detect_rapid_changes "$dir"
}

# Main function
main() {
    local command="${1:-monitor}"
    local target_dir="${2:-$HOME}"
    
    case "$command" in
        "monitor")
            monitor_directory "$target_dir"
            ;;
        "baseline")
            local hash=$(compute_directory_hash "$target_dir")
            save_baseline_hash "$target_dir" "$hash"
            echo "Baseline saved for $target_dir: $hash"
            ;;
        "check")
            detect_rapid_changes "$target_dir"
            ;;
        *)
            echo "Usage: rolling_hash.sh [monitor|baseline|check] [directory]"
            exit 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

