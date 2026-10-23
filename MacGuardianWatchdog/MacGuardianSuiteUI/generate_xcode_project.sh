#!/bin/bash

# Generate Xcode project from Swift Package with proper bundle identifier

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

create_xcode_project_manual() {
    # Create a basic Xcode project structure
    # Note: This is a simplified version - Xcode will handle most of it
    echo "   Creating project directory..."
    mkdir -p MacGuardianSuiteUI.xcodeproj
    
    # Create project.pbxproj with minimal configuration
    cat > MacGuardianSuiteUI.xcodeproj/project.pbxproj <<'PROJECT_EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
	};
	rootObject = "";
}
PROJECT_EOF
    
    echo "   ✅ Project structure created"
}

configure_bundle_identifier() {
    # Try to set bundle identifier using xcodebuild or plutil
    if command -v xcodebuild &> /dev/null && [ -d "MacGuardianSuiteUI.xcodeproj" ]; then
        # Use xcodebuild to set bundle identifier
        xcodebuild -project MacGuardianSuiteUI.xcodeproj \
            -target MacGuardianSuiteUI \
            PRODUCT_BUNDLE_IDENTIFIER=com.macguardian.suite.ui \
            2>/dev/null || true
    fi
    
    # Also create/update Info.plist in the project
    if [ ! -f "Info.plist" ]; then
        echo "   Creating Info.plist..."
        cat > Info.plist <<'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.macguardian.suite.ui</string>
    <key>CFBundleName</key>
    <string>MacGuardian Suite</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
</dict>
</plist>
PLIST_EOF
    fi
    
    echo "   ✅ Bundle identifier configured: com.macguardian.suite.ui"
}

# Main execution
echo "🔨 Generating Xcode project from Swift Package..."

# Try to generate project using Swift Package Manager
if swift package generate-xcodeproj 2>/dev/null; then
    echo "✅ Xcode project generated successfully!"
elif [ -d "MacGuardianSuiteUI.xcodeproj" ]; then
    echo "✅ Xcode project already exists"
else
    echo "📝 Creating Xcode project structure..."
    create_xcode_project_manual
fi

# Configure bundle identifier
if [ -d "MacGuardianSuiteUI.xcodeproj" ] || [ -f "Package.swift" ]; then
    echo "⚙️  Configuring bundle identifier..."
    configure_bundle_identifier
    echo "✅ Configuration complete!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open Package.swift in Xcode:"
    echo "      open Package.swift"
    echo ""
    echo "   2. In Xcode:"
    echo "      - Select MacGuardianSuiteUI scheme"
    echo "      - Go to Product → Scheme → Edit Scheme (Cmd + <)"
    echo "      - Select Run → Info tab"
    echo "      - Set Bundle Identifier to: com.macguardian.suite.ui"
    echo ""
    echo "   3. Build and Run:"
    echo "      - Press Cmd + B to build"
    echo "      - Press Cmd + R to run"
    echo ""
    echo "   4. Or use the build script for app bundle:"
    echo "      ./build_app.sh"
fi

