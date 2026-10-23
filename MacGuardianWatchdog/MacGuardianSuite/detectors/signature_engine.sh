#!/bin/bash

# ===============================
# Signature Engine
# Custom malware signature detection
# Event Spec v1.0.0 compliant
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source core modules
source "$SUITE_DIR/core/validators.sh" 2>/dev/null || true
source "$SUITE_DIR/core/logging.sh" 2>/dev/null || true
source "$SUITE_DIR/core/hashing.sh" 2>/dev/null || true
source "$SUITE_DIR/daemons/event_writer.sh" 2>/dev/null || true

SIGNATURES_DIR="$SUITE_DIR/config/signatures"
SIGNATURE_DB="$SIGNATURES_DIR/signatures.json"
SCAN_TARGET="${1:-$HOME/Documents}"

mkdir -p "$SIGNATURES_DIR"

# Initialize signature database
init_signatures() {
    if [ ! -f "$SIGNATURE_DB" ]; then
        log_detector "signature_engine" "INFO" "Creating signature database..."
        
        cat > "$SIGNATURE_DB" <<EOF
{
  "file_hashes": [],
  "file_patterns": [
    {
      "pattern": ".*\\.exe$",
      "description": "Windows executable",
      "severity": "medium"
    },
    {
      "pattern": ".*\\.bat$",
      "description": "Batch script",
      "severity": "low"
    },
    {
      "pattern": ".*\\.scr$",
      "description": "Screensaver (often malware)",
      "severity": "high"
    }
  ],
  "string_patterns": [
    {
      "pattern": "base64.*decode",
      "description": "Base64 obfuscation",
      "severity": "medium"
    },
    {
      "pattern": "eval.*exec",
      "description": "Code execution",
      "severity": "high"
    }
  ]
}
EOF
        
        log_detector "signature_engine" "INFO" "Signature database created"
    fi
}

# Scan file with signatures
scan_file() {
    local file="$1"
    local matches=0
    
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        return 1
    fi
    
    # Check file hash
    local file_hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1 || echo "")
    if [ -n "$file_hash" ] && [ -f "$SIGNATURE_DB" ]; then
        if grep -q "\"$file_hash\"" "$SIGNATURE_DB" 2>/dev/null; then
            matches=$((matches + 1))
            
            # Emit Event Spec v1.0.0 event
            local escaped_file=$(echo "$file" | sed 's/"/\\"/g')
            local context_json="{\"match_type\": \"hash\", \"file\": \"$escaped_file\", \"hash\": \"$file_hash\", \"signature_source\": \"signature_db\"}"
            write_event "signature_hit" "critical" "signature_engine" "$context_json"
            log_detector "signature_engine" "CRITICAL" "Known malicious hash detected: $file_hash in $file"
        fi
    fi
    
    # Check file patterns
    local filename=$(basename "$file")
    if [ -f "$SIGNATURE_DB" ]; then
        grep -o '"pattern":"[^"]*"' "$SIGNATURE_DB" 2>/dev/null | cut -d'"' -f4 | while IFS= read -r pattern; do
            if echo "$filename" | grep -qiE "$pattern"; then
                matches=$((matches + 1))
                
                # Emit Event Spec v1.0.0 event
                local escaped_file=$(echo "$file" | sed 's/"/\\"/g')
                local escaped_pattern=$(echo "$pattern" | sed 's/"/\\"/g')
                local context_json="{\"match_type\": \"file_pattern\", \"file\": \"$escaped_file\", \"pattern\": \"$escaped_pattern\"}"
                write_event "signature_hit" "medium" "signature_engine" "$context_json"
                log_detector "signature_engine" "WARNING" "Suspicious file pattern detected: $pattern in $file"
            fi
        done
    fi
    
    # Check string patterns in file content (first 1KB)
    if [ -f "$SIGNATURE_DB" ]; then
        local file_content=$(head -c 1024 "$file" 2>/dev/null || echo "")
        grep -o '"pattern":"[^"]*"' "$SIGNATURE_DB" 2>/dev/null | cut -d'"' -f4 | while IFS= read -r pattern; do
            if echo "$file_content" | grep -qiE "$pattern"; then
                matches=$((matches + 1))
                
                # Emit Event Spec v1.0.0 event
                local escaped_file=$(echo "$file" | sed 's/"/\\"/g')
                local escaped_pattern=$(echo "$pattern" | sed 's/"/\\"/g')
                local context_json="{\"match_type\": \"content_pattern\", \"file\": \"$escaped_file\", \"pattern\": \"$escaped_pattern\"}"
                write_event "signature_hit" "high" "signature_engine" "$context_json"
                log_detector "signature_engine" "WARNING" "Suspicious content pattern detected: $pattern in $file"
            fi
        done
    fi
    
    return $matches
}

# Scan directory
scan_directory() {
    local target_dir="$1"
    local total_files=0
    local matches_found=0
    
    if [ ! -d "$target_dir" ]; then
        log_detector "signature_engine" "ERROR" "Directory not found: $target_dir"
        return 1
    fi
    
    init_signatures
    
    find "$target_dir" -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
        total_files=$((total_files + 1))
        if scan_file "$file" > /dev/null 2>&1; then
            matches_found=$((matches_found + 1))
            log_detector "signature_engine" "WARNING" "Suspicious file: $file"
        fi
    done
    
    if [ $matches_found -eq 0 ]; then
        log_detector "signature_engine" "INFO" "Signature scan completed - no matches found"
    else
        log_detector "signature_engine" "WARNING" "Signature scan completed - $matches_found match(es) found"
    fi
    
    return $matches_found
}

# Main execution
if [ "${1:-scan}" = "init" ]; then
    init_signatures
else
    scan_directory "${SCAN_TARGET:-$HOME/Documents}"
fi

