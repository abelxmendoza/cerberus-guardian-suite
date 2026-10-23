#!/bin/bash
APP_PATH="MacGuardianSuiteUI/.build/arm64-apple-macosx/release/MacGuardian Suite.app"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
FULL_APP_PATH="$PROJECT_ROOT/$APP_PATH"

if [ ! -d "$FULL_APP_PATH" ]; then
    echo "❌ App bundle not found: $FULL_APP_PATH"
    echo "   Run ./build_app.sh first"
    exit 1
fi

touch "$FULL_APP_PATH"
touch "$FULL_APP_PATH/Contents/Info.plist"
touch "$FULL_APP_PATH/Contents/Resources/AppIcon.icns"

echo "✔ Touched bundle to force macOS refresh"
