#!/bin/bash
APP_PATH="MacGuardianSuiteUI/.build/arm64-apple-macosx/release/MacGuardian Suite.app"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
FULL_APP_PATH="$PROJECT_ROOT/$APP_PATH"

echo "Checking icon:"
if [ -f "$FULL_APP_PATH/Contents/Resources/AppIcon.icns" ]; then
    ls -lh "$FULL_APP_PATH/Contents/Resources/AppIcon.icns"
else
    echo "❌ Icon file not found"
    exit 1
fi

echo ""
echo "Checking plist:"
if [ -f "$FULL_APP_PATH/Contents/Info.plist" ]; then
    plutil -p "$FULL_APP_PATH/Contents/Info.plist" | grep CFBundleIconFile
else
    echo "❌ Info.plist not found"
    exit 1
fi

echo ""
echo "Checking Dock cache..."
defaults read com.apple.dock 2>/dev/null | grep -i macguardian || echo "   (No macguardian entries found in Dock cache)"

echo ""
echo "✔ Verification complete"
echo ""
echo "📍 App location: $FULL_APP_PATH"
