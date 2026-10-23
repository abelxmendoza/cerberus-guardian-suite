#!/bin/bash
# Force macOS to reload icon cache

echo "🔄 Refreshing macOS icon cache..."

echo "▸ Killing Finder..."
killall Finder 2>/dev/null || true

echo "▸ Killing Dock..."
killall Dock 2>/dev/null || true

echo "▸ Killing SystemUIServer..."
killall SystemUIServer 2>/dev/null || true

echo ""
echo "✔ Icon cache refresh initiated"
echo ""
echo "💡 If icon still doesn't show, try the nuclear option:"
echo "   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user"

