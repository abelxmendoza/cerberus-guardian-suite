#!/bin/bash
# Script to create .icns file from PNG for macOS app icon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGO_PNG="$SCRIPT_DIR/Resources/images/MacGlogo.png"
ICONSET_DIR="$SCRIPT_DIR/Resources/images/MacGlogo.iconset"
ICNS_FILE="$SCRIPT_DIR/Resources/images/MacGlogo.icns"

echo "🎨 Creating app icon from MacGlogo.png..."

# Check if logo exists
if [ ! -f "$LOGO_PNG" ]; then
    echo "❌ Error: Logo file not found at $LOGO_PNG"
    echo "   Please ensure MacGlogo.png exists in Resources/images/"
    exit 1
fi

# Verify PNG is valid
if ! file "$LOGO_PNG" | grep -q "PNG\|image"; then
    echo "❌ Error: $LOGO_PNG is not a valid PNG image"
    exit 1
fi

# Check if sips and iconutil are available
if ! command -v sips &> /dev/null; then
    echo "❌ Error: sips command not found (required for icon generation)"
    exit 1
fi

if ! command -v iconutil &> /dev/null; then
    echo "❌ Error: iconutil command not found (required for icon generation)"
    exit 1
fi

# Create iconset directory
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Required icon sizes for macOS
sizes=(
    "16:16"
    "32:32"
    "64:64"
    "128:128"
    "256:256"
    "512:512"
    "1024:1024"
)

# Generate all required sizes
ERROR_COUNT=0
for size in "${sizes[@]}"; do
    IFS=':' read -r width height <<< "$size"
    
    # Standard size
    if sips -z $width $height "$LOGO_PNG" --out "$ICONSET_DIR/icon_${width}x${width}.png" 2>&1; then
        # Verify it was created
        if [ ! -f "$ICONSET_DIR/icon_${width}x${width}.png" ]; then
            echo "  ⚠️  Warning: Failed to create ${width}x${width} icon"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            continue
        fi
    else
        echo "  ⚠️  Warning: Failed to create ${width}x${width} icon"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    fi
    
    # @2x retina size (double resolution)
    retina_width=$((width * 2))
    retina_height=$((height * 2))
    if sips -z $retina_width $retina_height "$LOGO_PNG" --out "$ICONSET_DIR/icon_${width}x${width}@2x.png" 2>&1; then
        if [ -f "$ICONSET_DIR/icon_${width}x${width}@2x.png" ]; then
    echo "  ✓ Generated ${width}x${width} and ${retina_width}x${retina_height} icons"
        else
            echo "  ⚠️  Warning: Failed to create ${retina_width}x${retina_height} icon"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        echo "  ⚠️  Warning: Failed to create ${retina_width}x${retina_height} icon"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

if [ $ERROR_COUNT -gt 0 ]; then
    echo "  ⚠️  Warning: $ERROR_COUNT icon sizes failed to generate, continuing anyway..."
fi

# Verify iconset directory has required files
REQUIRED_FILES=(
    "icon_16x16.png"
    "icon_16x16@2x.png"
    "icon_32x32.png"
    "icon_32x32@2x.png"
    "icon_128x128.png"
    "icon_128x128@2x.png"
    "icon_256x256.png"
    "icon_256x256@2x.png"
    "icon_512x512.png"
    "icon_512x512@2x.png"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$ICONSET_DIR/$file" ]; then
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo "  ⚠️  Warning: $MISSING_FILES required icon files are missing"
fi

# Create .icns file
if iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE" 2>&1; then
    echo "  ✅ Iconutil completed"
else
    echo "  ❌ Error: iconutil failed"
    rm -rf "$ICONSET_DIR"
    exit 1
fi

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

# Verify .icns file was created and is valid
if [ -f "$ICNS_FILE" ] && [ -s "$ICNS_FILE" ]; then
    ICON_SIZE=$(stat -f%z "$ICNS_FILE" 2>/dev/null || stat -c%s "$ICNS_FILE" 2>/dev/null || echo "0")
    if [ "$ICON_SIZE" -gt 1000 ]; then
        # Verify it's a valid icon file
        if file "$ICNS_FILE" | grep -q "Mac OS X icon\|Apple Icon Image\|Mac OS X icon resource"; then
    echo "✅ App icon created successfully: $ICNS_FILE"
    echo "   File size: $(du -h "$ICNS_FILE" | cut -f1)"
            echo "   File type: $(file "$ICNS_FILE" | cut -d: -f2-)"
        else
            echo "⚠️  Warning: Icon file created but may not be valid"
            echo "   File type: $(file "$ICNS_FILE" | cut -d: -f2-)"
        fi
    else
        echo "❌ Error: Icon file is too small ($ICON_SIZE bytes), generation may have failed"
        rm -f "$ICNS_FILE"
        exit 1
    fi
else
    echo "❌ Error: Failed to create .icns file"
    exit 1
fi

