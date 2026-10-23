#!/bin/bash
# Script to verify app icon setup and troubleshoot issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build"
APP_NAME="MacGuardian Suite"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST="$CONTENTS_DIR/Info.plist"

echo "🔍 Verifying MacGuardian Suite App Icon Setup"
echo "=============================================="
echo ""

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ App bundle not found at: $APP_BUNDLE"
    echo "   Run ./build_app.sh first"
    exit 1
fi

echo "✅ App bundle found: $APP_BUNDLE"
echo ""

# Check icon file (try MacGuardianLogo first, then MacGlogo)
ICON_FILE=""
ICON_NAME=""

if [ -f "$RESOURCES_DIR/MacGuardianLogo.icns" ]; then
    ICON_FILE="$RESOURCES_DIR/MacGuardianLogo.icns"
    ICON_NAME="MacGuardianLogo"
elif [ -f "$RESOURCES_DIR/MacGlogo.icns" ]; then
    ICON_FILE="$RESOURCES_DIR/MacGlogo.icns"
    ICON_NAME="MacGlogo"
fi

if [ -n "$ICON_FILE" ] && [ -f "$ICON_FILE" ]; then
    ICON_SIZE=$(stat -f%z "$ICON_FILE" 2>/dev/null || stat -c%s "$ICON_FILE" 2>/dev/null || echo "0")
    ICON_TYPE=$(file "$ICON_FILE" 2>/dev/null | cut -d: -f2- || echo "unknown")
    
    echo "✅ Icon file found: $ICON_FILE"
    echo "   Size: $(du -h "$ICON_FILE" | cut -f1) ($ICON_SIZE bytes)"
    echo "   Type: $ICON_TYPE"
    
    if echo "$ICON_TYPE" | grep -q "Mac OS X icon\|Apple Icon Image"; then
        echo "   ✅ Icon file format is valid"
    else
        echo "   ⚠️  Warning: Icon file format may be invalid"
    fi
else
    echo "❌ Icon file not found: $ICON_FILE"
fi
echo ""

# Check Info.plist
if [ -f "$INFO_PLIST" ]; then
    echo "✅ Info.plist found"
    
    # Check if plist is valid
    if plutil -lint "$INFO_PLIST" &>/dev/null; then
        echo "   ✅ Info.plist is valid"
        
        # Check icon configuration
        PLIST_ICON=$(plutil -extract CFBundleIconFile raw "$INFO_PLIST" 2>/dev/null || echo "")
        if [ -n "$PLIST_ICON" ]; then
            if [ "$PLIST_ICON" = "$ICON_NAME" ]; then
                echo "   ✅ CFBundleIconFile is set to '$ICON_NAME'"
            else
                echo "   ⚠️  Warning: CFBundleIconFile is '$PLIST_ICON' but icon file is '$ICON_NAME'"
            fi
        else
            echo "   ⚠️  Warning: CFBundleIconFile not set"
        fi
        
        PLIST_ICONS=$(plutil -extract CFBundleIconFiles raw "$INFO_PLIST" 2>/dev/null || echo "")
        if [ -n "$PLIST_ICONS" ]; then
            if echo "$PLIST_ICONS" | grep -q "$ICON_NAME"; then
                echo "   ✅ CFBundleIconFiles includes '$ICON_NAME'"
            else
                echo "   ⚠️  Warning: CFBundleIconFiles doesn't include '$ICON_NAME'"
            fi
        else
            echo "   ⚠️  Warning: CFBundleIconFiles not set"
        fi
    else
        echo "   ❌ Error: Info.plist is invalid"
        plutil -lint "$INFO_PLIST" 2>&1 || true
    fi
else
    echo "❌ Info.plist not found"
fi
echo ""

# Check bundle attributes
if command -v GetFileInfo &> /dev/null; then
    echo "📋 Bundle Attributes:"
    GetFileInfo "$APP_BUNDLE" 2>/dev/null || echo "   (Unable to read attributes)"
    echo ""
fi

# Summary and recommendations
echo "📝 Summary:"
if [ -f "$ICON_FILE" ] && [ -f "$INFO_PLIST" ]; then
    echo "   ✅ Icon setup appears correct"
    echo ""
    echo "💡 If icon still doesn't show in Dock:"
    echo "   1. Quit the app completely (Cmd+Q)"
    echo "   2. Clear icon cache:"
    echo "      sudo rm -rf /Library/Caches/com.apple.iconservices.store"
    echo "      killall Dock"
    echo "   3. Or restart your Mac"
    echo ""
    echo "   4. Try rebuilding the app:"
    echo "      ./build_app.sh"
    echo ""
    echo "   5. If still not working, check icon manually:"
    echo "      open '$ICON_FILE'"
else
    echo "   ⚠️  Issues detected - see above"
    echo ""
    echo "💡 To fix:"
    echo "   1. Ensure MacGuardianLogo.png exists in Resources/images/"
    echo "   2. Run: ./build_app.sh (it will auto-generate icon)"
    echo "   3. Or run: ./set_app_icon.sh to manually set icon"
fi

