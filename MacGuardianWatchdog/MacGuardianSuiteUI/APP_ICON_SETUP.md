# App Icon Setup Guide

The MacGlogo.png will be used as the app icon in the Dock, Finder, and Spotlight.

## Quick Setup

1. **Place your logo** at:
   ```
   MacGuardianSuiteUI/Resources/images/MacGlogo.png
   ```

2. **Create the app icon** (automatically done during build, or manually):
   ```bash
   ./create_app_icon.sh
   ```
   This generates `MacGlogo.icns` from your PNG file.

3. **Build the app**:
   ```bash
   ./build_app.sh
   ```
   The build script will:
   - Automatically create the .icns file if it doesn't exist
   - Copy it to the app bundle
   - Configure Info.plist to use it

4. **Install the app**:
   ```bash
   cp -r ".build/MacGuardian Suite.app" /Applications/
   ```

5. **Refresh the Dock** (if needed):
   ```bash
   killall Dock
   ```

## How It Works

The `create_app_icon.sh` script:
- Uses macOS `sips` to resize your PNG to all required icon sizes
- Creates both standard and @2x retina versions
- Uses `iconutil` to package them into a .icns file
- Generates sizes: 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024

## Icon Requirements

- **Format**: PNG (recommended for transparency)
- **Size**: 1024x1024 pixels minimum for best quality
- **Background**: Transparent or solid (transparent preferred)
- **Name**: Must be exactly `MacGlogo.png` (case-sensitive)

## Troubleshooting

**Icon not showing in Dock?**
1. Make sure the .icns file was created: `ls Resources/images/MacGlogo.icns`
2. Rebuild the app: `./build_app.sh`
3. Reinstall to Applications folder
4. Restart Dock: `killall Dock` or log out/in

**Icon looks pixelated?**
- Use a higher resolution source image (1024x1024 or larger)
- Ensure your PNG is high quality before conversion

**Script fails?**
- Make sure `sips` and `iconutil` are available (they come with macOS)
- Check that MacGlogo.png exists in Resources/images/

## Manual Icon Creation

If the script doesn't work, you can manually create the icon:

1. Open your PNG in Preview
2. Export as PNG at 1024x1024
3. Use an app like [IconGenerator](https://apps.apple.com/app/icongenerator/id1294179975) or online tools
4. Save as `MacGlogo.icns` in `Resources/images/`
5. Rebuild the app

## Verification

After building, verify the icon is in the bundle:
```bash
ls -lh ".build/MacGuardian Suite.app/Contents/Resources/MacGlogo.icns"
```

Check Info.plist references it:
```bash
grep -A1 CFBundleIconFile ".build/MacGuardian Suite.app/Contents/Info.plist"
```

