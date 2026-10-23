#!/bin/bash

# Mac Guardian Suite Launcher
# Wrapper script to launch the Mac Guardian Suite menu

set -euo pipefail  # Exit on error, undefined vars, pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="${SCRIPT_DIR}/MacGuardianSuite"
SUITE_SCRIPT="${SUITE_DIR}/mac_suite.sh"

# Check if suite directory exists
if [ ! -d "$SUITE_DIR" ]; then
    echo "❌ Error: MacGuardianSuite directory not found at: $SUITE_DIR" >&2
    exit 1
fi

# Check if suite script exists
if [ ! -f "$SUITE_SCRIPT" ]; then
    echo "❌ Error: mac_suite.sh not found at: $SUITE_SCRIPT" >&2
    exit 1
fi

# Make sure script is executable
chmod +x "$SUITE_SCRIPT"

# Change to suite directory and run
cd "$SUITE_DIR"
exec ./mac_suite.sh
