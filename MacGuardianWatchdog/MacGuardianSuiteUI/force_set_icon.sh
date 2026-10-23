#!/bin/bash
# Force set app icon using all available methods

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/.build/MacGuardian Suite.app"
ICON_ICNS="$SCRIPT_DIR/Resources/images/MacGuardianLogo.icns"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ App bundle not found: $APP_BUNDLE"
    echo "   Run ./build_app.sh first"
    exit 1
fi

if [ ! -f "$ICON_ICNS" ]; then
    echo "❌ Icon file not found: $ICON_ICNS"
    exit 1
fi

echo "🎨 Force-setting app icon using all methods..."
echo ""

# Ensure icon is in bundle Resources as AppIcon.icns (standard macOS convention)
echo "1️⃣  Copying icon to bundle..."
cp "$ICON_ICNS" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
chmod 644 "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Update Info.plist to ensure icon is referenced
echo "2️⃣  Updating Info.plist..."
plutil -replace CFBundleIconFile -string "AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
plutil -replace CFBundleIconFiles -array "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
plutil -insert CFBundleIconFiles.0 -string "AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true

# Method 1: Use AppleScript (most reliable for Dock)
echo "3️⃣  Setting icon via AppleScript..."
osascript <<EOF 2>/dev/null || true
tell application "Finder"
    set theApp to POSIX file "$APP_BUNDLE" as alias
    set iconFile to POSIX file "$ICON_ICNS" as alias
    set the icon of theApp to iconFile
end tell
EOF

# Method 2: Use sips
echo "4️⃣  Setting icon via sips..."
sips -i "$ICON_ICNS" > /dev/null 2>&1 || true

# Method 3: Use DeRez/Rez to embed icon resource
if command -v DeRez &> /dev/null && command -v Rez &> /dev/null; then
    echo "5️⃣  Embedding icon resource..."
    EXECUTABLE="$APP_BUNDLE/Contents/MacOS/MacGuardianSuiteUI"
    if [ -f "$EXECUTABLE" ]; then
        ICON_RSRC=$(mktemp)
        DeRez -only icns "$ICON_ICNS" > "$ICON_RSRC" 2>/dev/null || true
        if [ -f "$ICON_RSRC" ] && [ -s "$ICON_RSRC" ]; then
            Rez -append "$ICON_RSRC" -o "$EXECUTABLE" 2>/dev/null || true
        fi
        rm -f "$ICON_RSRC" 2>/dev/null || true
    fi
fi

# Method 4: Use fileicon if available (most reliable)
if command -v fileicon &> /dev/null; then
    echo "6️⃣  Setting icon via fileicon..."
    fileicon set "$APP_BUNDLE" "$ICON_ICNS" 2>/dev/null || true
fi

# Update timestamps to force refresh
echo "7️⃣  Updating timestamps..."
touch "$APP_BUNDLE"
touch "$APP_BUNDLE/Contents/Info.plist"
touch "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Set bundle attributes
if command -v SetFile &> /dev/null; then
    echo "8️⃣  Setting bundle attributes..."
    SetFile -a C "$APP_BUNDLE" 2>/dev/null || true
fi

echo ""
echo "✅ Icon force-set using multiple methods"
echo ""
echo "🔄 Clearing icon cache and restarting Dock..."
echo "   (You may be prompted for your password)"

# Clear user icon cache
rm -rf ~/Library/Caches/com.apple.iconservices* 2>/dev/null || true
killall Finder 2>/dev/null || true

# Clear system icon cache (requires sudo)
echo ""
read -p "Clear system icon cache? This requires your password (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
    sudo killall -9 com.apple.iconservices 2>/dev/null || true
fi

# Restart Dock
killall Dock 2>/dev/null || true

echo ""
echo "✅ Done! The icon should now appear."
echo ""
echo "💡 If the icon still doesn't show:"
echo "   1. Quit the app completely (Cmd+Q)"
echo "   2. Restart your Mac"
echo "   3. Open the app again"
echo ""
echo "   To verify the icon file:"
echo "   open '$ICON_ICNS'"

