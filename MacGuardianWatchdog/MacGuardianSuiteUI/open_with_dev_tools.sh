#!/bin/bash
# Open MacGuardian Suite app with developer tools enabled

APP_PATH=".build/arm64-apple-macosx/release/MacGuardian Suite.app"

echo "🔧 Opening app with developer tools enabled..."
echo ""
echo "To access Web Inspector in WKWebView:"
echo "1. Right-click on any web content in the Reports view"
echo "2. Select 'Inspect Element' from the context menu"
echo "3. Or use Safari's Develop menu: Develop > [Your App] > [WebView]"
echo ""
echo "To enable Safari Develop menu:"
echo "Safari > Settings > Advanced > Show features for web developers"
echo ""

# Enable Web Inspector globally for WKWebView
defaults write com.apple.Safari WebKitDeveloperExtrasEnabled -bool true 2>/dev/null || true
defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || true

# Open the app
open "$APP_PATH"

echo "✅ App launched!"
echo ""
echo "💡 Developer Tips:"
echo "   - Web Inspector is enabled for all WKWebView components"
echo "   - Right-click on web content to inspect"
echo "   - Use Console.app to view app logs: open -a Console"
echo "   - Use Xcode for full debugging: open -a Xcode ."

