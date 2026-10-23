#!/bin/bash
# Wrapper script for stix_exporter.py with default arguments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOC_FILE="${1:-$HOME/.macguardian/threat_intel/iocs.json}"
OUTPUT_FILE="${2:-$HOME/.macguardian/threat_intel/iocs.stix.json}"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$IOC_FILE")"
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Check if IOC file exists, if not create empty one
if [ ! -f "$IOC_FILE" ]; then
    echo "⚠️  IOC file not found: $IOC_FILE"
    echo "📝 Creating empty IOC file..."
    echo '{"iocs": []}' > "$IOC_FILE"
fi

# Run the exporter
python3 "$SCRIPT_DIR/stix_exporter.py" "$IOC_FILE" "$OUTPUT_FILE"

