#!/bin/bash
# Comprehensive app icon verification and fix script

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$ROOT_DIR/.build/arm64-apple-macosx/release/MacGuardian Suite.app"
RESOURCES="$APP_PATH/Contents/Resources"
INFO="$APP_PATH/Contents/Info.plist"

echo "🔍 Checking structure..."

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App bundle not found at: $APP_PATH"
    echo "   Building app first..."
    cd "$ROOT_DIR"
    swift build -c release
    mkdir -p "$APP_PATH/Contents/MacOS"
    mkdir -p "$APP_PATH/Contents/Resources"
    cp "$ROOT_DIR/.build/arm64-apple-macosx/release/MacGuardianSuiteUI" "$APP_PATH/Contents/MacOS/"
fi

if [ -d "$RESOURCES" ]; then
    echo "📁 Resources directory contents:"
    ls -lh "$RESOURCES" | head -10
else
    echo "❌ Resources directory not found"
    exit 1
fi

echo ""
echo "📄 Info.plist icon configuration:"
if [ -f "$INFO" ]; then
    plutil -p "$INFO" | grep CFBundleIconFile || echo "   ⚠️  No CFBundleIconFile key found"
else
    echo "❌ Info.plist not found"
    exit 1
fi

echo ""
echo "🎨 Checking icon file..."

if [ ! -f "$RESOURCES/AppIcon.icns" ]; then
    echo "❌ AppIcon.icns not found in Resources!"
    echo "   Copying from project Resources..."
    PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
    if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
        cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
        echo "   ✅ Icon copied"
    else
        echo "   ❌ Icon not found at $PROJECT_ROOT/Resources/AppIcon.icns"
        exit 1
    fi
else
    echo "✅ AppIcon.icns found."
    ls -lh "$RESOURCES/AppIcon.icns"
fi

echo ""
echo "🛠️  Updating Info.plist CFBundleIconFile..."
if /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$INFO" 2>/dev/null; then
    echo "   ✅ CFBundleIconFile set to AppIcon"
elif /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$INFO" 2>/dev/null; then
    echo "   ✅ CFBundleIconFile added as AppIcon"
else
    echo "   ⚠️  Could not update Info.plist, trying plutil..."
    plutil -replace CFBundleIconFile -string "AppIcon" "$INFO" 2>/dev/null || echo "   ❌ Failed to update Info.plist"
fi

echo ""
echo "🔨 Rebuilding..."
cd "$ROOT_DIR"
swift build -c release

# Ensure executable is copied
if [ -f "$ROOT_DIR/.build/arm64-apple-macosx/release/MacGuardianSuiteUI" ]; then
    cp "$ROOT_DIR/.build/arm64-apple-macosx/release/MacGuardianSuiteUI" "$APP_PATH/Contents/MacOS/"
    chmod +x "$APP_PATH/Contents/MacOS/MacGuardianSuiteUI"
    echo "   ✅ Executable updated"
fi

# Ensure icon is copied
PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
    echo "   ✅ Icon updated"
fi

echo ""
echo "🧹 Clearing icon caches..."

killall Dock Finder SystemUIServer 2>/dev/null || true

rm -rf ~/Library/Caches/com.apple.iconservices.store 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.iconservices/* 2>/dev/null || true

killall -KILL iconservicesagent 2>/dev/null || true

echo "⚡ Icon cache cleared. macOS will regenerate automatically."

echo ""
echo "🚀 Launching app..."
open "$APP_PATH"

echo ""
echo "✅ Done! The app should now display with the correct icon."
echo "   If the icon doesn't appear immediately, wait a few seconds for macOS to refresh."

