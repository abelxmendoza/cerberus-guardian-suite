#!/bin/bash

# ===============================
# 🛡️ Quarantine Manager
# Safe file quarantine system with rollback capability
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true

# Quarantine directories
QUARANTINE_BASE="${QUARANTINE_BASE:-$HOME/MacGuardian/quarantine}"
QUARANTINE_DIR="$QUARANTINE_BASE/files"
QUARANTINE_MANIFEST="$QUARANTINE_BASE/manifests"
QUARANTINE_METADATA="$QUARANTINE_BASE/metadata"

mkdir -p "$QUARANTINE_DIR" "$QUARANTINE_MANIFEST" "$QUARANTINE_METADATA"

# Generate checksum (SHA-256)
get_checksum() {
    local file="$1"
    if [ -f "$file" ]; then
        shasum -a 256 "$file" 2>/dev/null | awk '{print $1}' || echo ""
    else
        echo ""
    fi
}

# Quarantine a file (move to quarantine with metadata)
quarantine_file() {
    local source_file="$1"
    local reason="${2:-suspicious}"
    local action_type="${3:-FILE_REMOVE}"
    
    if [ ! -f "$source_file" ]; then
        warning "File does not exist: $source_file"
        return 1
    fi
    
    # Generate unique quarantine name
    local basename_file=$(basename "$source_file")
    local dirname_file=$(dirname "$source_file" | sed 's|^/||' | sed 's|/|_|g')
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local quarantine_name="${timestamp}_${dirname_file}_${basename_file}"
    local quarantine_path="$QUARANTINE_DIR/$quarantine_name"
    
    # Get file metadata before moving
    local checksum=$(get_checksum "$source_file")
    local file_size=$(stat -f%z "$source_file" 2>/dev/null || echo "0")
    local file_perms=$(stat -f%OLp "$source_file" 2>/dev/null || echo "unknown")
    local file_owner=$(stat -f%Su "$source_file" 2>/dev/null || echo "unknown")
    local file_mtime=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$source_file" 2>/dev/null || echo "unknown")
    
    # Create metadata JSON
    local manifest_id="manifest_${timestamp}.json"
    local manifest_path="$QUARANTINE_MANIFEST/$manifest_id"
    
    cat > "$manifest_path" <<EOF
{
  "manifest_id": "$manifest_id",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "action": "$action_type",
  "source_file": "$source_file",
  "quarantine_path": "$quarantine_path",
  "quarantine_name": "$quarantine_name",
  "reason": "$reason",
  "metadata": {
    "checksum_sha256": "$checksum",
    "size_bytes": $file_size,
    "permissions": "$file_perms",
    "owner": "$file_owner",
    "modified_time": "$file_mtime"
  },
  "status": "quarantined"
}
EOF
    
    # Move file to quarantine
    if mv "$source_file" "$quarantine_path" 2>/dev/null; then
        success "Quarantined: $source_file → $quarantine_path"
        echo "$manifest_path"
        return 0
    else
        warning "Failed to quarantine: $source_file"
        rm -f "$manifest_path"
        return 1
    fi
}

# Restore a file from quarantine
restore_file() {
    local manifest_path="$1"
    
    if [ ! -f "$manifest_path" ]; then
        warning "Manifest not found: $manifest_path"
        return 1
    fi
    
    # Parse manifest (simple JSON parsing)
    local source_file=$(grep -o '"source_file": "[^"]*"' "$manifest_path" | cut -d'"' -f4)
    local quarantine_path=$(grep -o '"quarantine_path": "[^"]*"' "$manifest_path" | cut -d'"' -f4)
    local checksum=$(grep -o '"checksum_sha256": "[^"]*"' "$manifest_path" | cut -d'"' -f4)
    
    if [ -z "$source_file" ] || [ -z "$quarantine_path" ]; then
        warning "Invalid manifest: $manifest_path"
        return 1
    fi
    
    if [ ! -f "$quarantine_path" ]; then
        warning "Quarantined file not found: $quarantine_path"
        return 1
    fi
    
    # Verify checksum
    local current_checksum=$(get_checksum "$quarantine_path")
    if [ "$current_checksum" != "$checksum" ]; then
        warning "Checksum mismatch! File may have been modified. Proceed anyway? (y/N)"
        read -r confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            return 1
        fi
    fi
    
    # Create parent directory if needed
    local parent_dir=$(dirname "$source_file")
    mkdir -p "$parent_dir" 2>/dev/null || true
    
    # Restore file
    if mv "$quarantine_path" "$source_file" 2>/dev/null; then
        # Update manifest
        sed -i '' 's/"status": "quarantined"/"status": "restored"/' "$manifest_path" 2>/dev/null || \
        sed -i 's/"status": "quarantined"/"status": "restored"/' "$manifest_path" 2>/dev/null || true
        
        success "Restored: $quarantine_path → $source_file"
        return 0
    else
        warning "Failed to restore: $quarantine_path"
        return 1
    fi
}

# List quarantined files
list_quarantined() {
    local manifest_files=$(ls -t "$QUARANTINE_MANIFEST"/*.json 2>/dev/null | head -50 || true)
    
    if [ -z "$manifest_files" ]; then
        info "No quarantined files found"
        return 0
    fi
    
    echo "${bold}📋 Quarantined Files:${normal}"
    echo "=========================================="
    
    for manifest in $manifest_files; do
        local source_file=$(grep -o '"source_file": "[^"]*"' "$manifest" | cut -d'"' -f4)
        local timestamp=$(grep -o '"timestamp": "[^"]*"' "$manifest" | cut -d'"' -f4)
        local reason=$(grep -o '"reason": "[^"]*"' "$manifest" | cut -d'"' -f4)
        local status=$(grep -o '"status": "[^"]*"' "$manifest" | cut -d'"' -f4)
        
        echo ""
        echo "  File: $source_file"
        echo "  Quarantined: $timestamp"
        echo "  Reason: $reason"
        echo "  Status: $status"
        echo "  Manifest: $manifest"
    done
}

# Create rollback manifest (summary of all changes)
create_rollback_manifest() {
    local session_id="${1:-$(date +%Y%m%d_%H%M%S)}"
    local rollback_file="$QUARANTINE_MANIFEST/rollback_${session_id}.json"
    
    local all_manifests=$(ls -t "$QUARANTINE_MANIFEST"/manifest_*.json 2>/dev/null | head -100 || true)
    
    if [ -z "$all_manifests" ]; then
        info "No changes to rollback"
        return 0
    fi
    
    echo "{" > "$rollback_file"
    echo "  \"rollback_id\": \"rollback_${session_id}\"," >> "$rollback_file"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," >> "$rollback_file"
    echo "  \"total_files\": $(echo "$all_manifests" | wc -l | tr -d ' ')," >> "$rollback_file"
    echo "  \"manifests\": [" >> "$rollback_file"
    
    local first=true
    for manifest in $all_manifests; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$rollback_file"
        fi
        echo "    \"$manifest\"" >> "$rollback_file"
    done
    
    echo "  ]" >> "$rollback_file"
    echo "}" >> "$rollback_file"
    
    success "Rollback manifest created: $rollback_file"
    echo "$rollback_file"
}

# Main function
main() {
    local command="${1:-list}"
    
    case "$command" in
        quarantine)
            if [ $# -lt 2 ]; then
                echo "Usage: $0 quarantine <file> [reason] [action_type]"
                exit 1
            fi
            quarantine_file "$2" "${3:-suspicious}" "${4:-FILE_REMOVE}"
            ;;
        restore)
            if [ $# -lt 2 ]; then
                echo "Usage: $0 restore <manifest_path>"
                exit 1
            fi
            restore_file "$2"
            ;;
        list)
            list_quarantined
            ;;
        rollback)
            create_rollback_manifest "${2:-}"
            ;;
        *)
            echo "Usage: $0 {quarantine|restore|list|rollback}"
            echo ""
            echo "Commands:"
            echo "  quarantine <file> [reason] [action]  - Quarantine a file"
            echo "  restore <manifest>                  - Restore a file from quarantine"
            echo "  list                                 - List all quarantined files"
            echo "  rollback [session_id]                - Create rollback manifest"
            exit 1
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

