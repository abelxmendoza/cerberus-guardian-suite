# MacGuardian Logo Setup Guide

## Quick Setup

1. **Save your logo image** to:
   ```
   MacGuardianSuiteUI/Resources/images/MacGuardianLogo.png
   ```
   (or `.jpg`/`.jpeg`)
   
   Alternatively, you can save it directly to:
   ```
   MacGuardianSuiteUI/Resources/MacGuardianLogo.png
   ```

2. **Rebuild the app**:
   ```bash
   cd MacGuardianSuiteUI
   ./build_app.sh
   ```

3. **Install the app**:
   ```bash
   cp -r ".build/MacGuardian Suite.app" /Applications/
   ```

## Logo Specifications

- **Name**: Must be exactly `MacGuardianLogo` (case-sensitive)
- **Formats**: PNG (recommended), JPG, JPEG
- **Size**: 512x512 pixels or higher for best quality
- **Background**: Transparent PNG preferred, or match your app theme

## Where the Logo Appears

The logo will automatically appear in:
- ✅ **Welcome Screen** - Large logo (150px) with shadow effect
- ✅ **Dashboard** - Header logo (80px) next to app title
- 🔄 **App Icon** - Can be configured in Info.plist (future enhancement)

## Fallback

If the logo file is not found, the app will display a styled fallback with:
- Shield icon with purple gradient
- "MACGUARDIAN" text
- "WATCHDOG" text

## Current Logo Description

Your logo features:
- 🐺 Cybernetic canine head with purple outline
- 👁️ Red glowing eyes
- Ω Purple Omega symbol on forehead
- 📝 "MACGUARDIAN" and "WATCHDOG" text
- 🎨 Dark purple/black background

## Troubleshooting

**Logo not showing?**
1. Check the file name is exactly `MacGuardianLogo.png` (case-sensitive)
2. Verify the file is in `MacGuardianSuiteUI/Resources/`
3. Rebuild the app after adding the logo
4. Check file permissions (should be readable)

**Logo looks pixelated?**
- Use a higher resolution image (512x512 or larger)
- PNG format preserves quality better than JPG

**Want to change the logo size?**
- Edit `LogoView.swift` and adjust the `size` parameter
- Welcome screen: `LogoView(size: 150)`
- Dashboard: `LogoView(size: 80)`

