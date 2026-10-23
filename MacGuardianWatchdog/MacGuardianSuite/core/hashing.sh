#!/bin/bash

# ===============================
# Hashing Module
# Secure file hashing functions
# ===============================

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/validators.sh" 2>/dev/null || true

# ===============================
# Compute File Hash
# ===============================

compute_file_hash() {
    local file_path="$1"
    local algorithm="${2:-sha256}"
    
    # Validate path
    if ! validate_path "$file_path" false; then
        return 1
    fi
    
    if [ ! -f "$file_path" ] || [ ! -r "$file_path" ]; then
        return 1
    fi
    
    # Validate algorithm
    if ! validate_enum "$algorithm" "md5|sha1|sha256|sha512"; then
        algorithm="sha256"
    fi
    
    # Compute hash
    case "$algorithm" in
        md5)
            shasum -a 1 "$file_path" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file_path" 2>/dev/null || return 1
            ;;
        sha1)
            shasum -a 1 "$file_path" 2>/dev/null | cut -d' ' -f1 || return 1
            ;;
        sha256)
            shasum -a 256 "$file_path" 2>/dev/null | cut -d' ' -f1 || return 1
            ;;
        sha512)
            shasum -a 512 "$file_path" 2>/dev/null | cut -d' ' -f1 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# ===============================
# Compute Directory Hash
# ===============================

compute_directory_hash() {
    local dir_path="$1"
    local algorithm="${2:-sha256}"
    
    if ! validate_path "$dir_path" false; then
        return 1
    fi
    
    if [ ! -d "$dir_path" ]; then
        return 1
    fi
    
    # Create temporary file for hashing
    local temp_file
    temp_file=$(safe_tempfile "dir_hash" "tmp")
    
    # Collect all file hashes
    find "$dir_path" -type f -exec shasum -a 256 {} \; 2>/dev/null | sort > "$temp_file"
    
    # Hash the combined hashes
    local combined_hash
    combined_hash=$(shasum -a 256 "$temp_file" 2>/dev/null | cut -d' ' -f1)
    
    # Cleanup
    rm -f "$temp_file"
    
    echo "$combined_hash"
}

# ===============================
# Verify Hash
# ===============================

verify_file_hash() {
    local file_path="$1"
    local expected_hash="$2"
    local algorithm="${3:-sha256}"
    
    local actual_hash
    actual_hash=$(compute_file_hash "$file_path" "$algorithm")
    
    if [ "$actual_hash" = "$expected_hash" ]; then
        return 0
    else
        return 1
    fi
}

# Export functions
export -f compute_file_hash
export -f compute_directory_hash
export -f verify_file_hash

