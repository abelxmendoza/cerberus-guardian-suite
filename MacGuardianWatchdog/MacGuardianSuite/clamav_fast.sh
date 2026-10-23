#!/bin/bash

# ===============================
# Fast ClamAV Scanner
# Optimized for speed with smart exclusions
# ===============================

set -euo pipefail

SCAN_DIR="${1:-$HOME/Documents}"
MAX_SIZE="${2:-100M}"
MAX_FILES="${3:-50000}"

# Create smart exclude patterns
EXCLUDE_FILE=$(mktemp)
cat > "$EXCLUDE_FILE" <<EOF
# Skip media files (rarely contain viruses)
*.mp4
*.mov
*.avi
*.mkv
*.webm
*.flv
*.mp3
*.wav
*.flac
*.aac
*.ogg
*.m4a
*.jpg
*.jpeg
*.png
*.gif
*.bmp
*.tiff
*.svg
*.webp
*.heic
*.raw

# Skip archives (will be scanned if extracted)
*.zip
*.tar
*.gz
*.bz2
*.xz
*.7z
*.rar
*.dmg
*.iso
*.pkg

# Skip development/build files
*.log
*.tmp
*.cache
*.swp
*.bak
*.old
*/.git/*
*/.svn/*
*/node_modules/*
*/venv/*
*/.venv/*
*/__pycache__/*
*.pyc
*.pyo

# Skip system files
*.DS_Store
*/.Trash/*
*/Library/Caches/*
*/Library/Logs/*
*/tmp/*
*/temp/*

# Skip large data files
*.db
*.sqlite
*.sqlite3
*.dump
*.backup
EOF

echo "🚀 Fast ClamAV Scan"
echo "Scanning: $SCAN_DIR"
echo "Max file size: $MAX_SIZE"
echo "Max files: $MAX_FILES"
echo ""

# Run fast scan
clamscan -r \
    -i \
    --max-filesize="$MAX_SIZE" \
    --max-scansize="$((MAX_SIZE * 2))" \
    --max-files="$MAX_FILES" \
    --exclude-from="$EXCLUDE_FILE" \
    --no-summary \
    --bell \
    "$SCAN_DIR" 2>&1 | \
    while IFS= read -r line; do
        # Show progress for large scans
        if echo "$line" | grep -q "FOUND"; then
            echo "⚠️  $line"
        elif echo "$line" | grep -qE "^(Scanning|^---)"; then
            echo "$line"
        fi
    done

SCAN_EXIT=${PIPESTATUS[0]}

# Cleanup
rm -f "$EXCLUDE_FILE"

exit $SCAN_EXIT

