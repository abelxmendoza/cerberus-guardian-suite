# Xcode Setup Guide for MacGuardian Suite

## Quick Setup

### Option 1: Open Package.swift Directly (Recommended)

1. **Open Package.swift in Xcode:**
   ```bash
   cd MacGuardianSuiteUI
   open Package.swift
   ```

2. **Configure Bundle Identifier:**
   - In Xcode, select the **MacGuardianSuiteUI** scheme (top toolbar)
   - Go to **Product → Scheme → Edit Scheme...** (or press `Cmd + <`)
   - Select **Run** in the left sidebar
   - Go to the **Info** tab
   - Set **Bundle Identifier** to: `com.macguardian.suite.ui`
   - Click **Close**

3. **Build and Run:**
   - Press `Cmd + B` to build
   - Press `Cmd + R` to run

### Option 2: Use Build Script (For App Bundle)

The `build_app.sh` script creates a proper `.app` bundle with Info.plist:

```bash
cd MacGuardianSuiteUI
./build_app.sh
```

This creates: `.build/MacGuardian Suite.app`

### Option 3: Generate Xcode Project

Run the generation script:

```bash
cd MacGuardianSuiteUI
./generate_xcode_project.sh
open MacGuardianSuiteUI.xcodeproj
```

## Fixing Bundle Identifier Errors

If you see errors about missing bundle identifier:

1. **In Xcode Build Settings:**
   - Select **MacGuardianSuiteUI** target
   - Search for "Product Bundle Identifier"
   - Set to: `com.macguardian.suite.ui`

2. **Or add to Scheme:**
   - Edit Scheme → Run → Info
   - Set Bundle Identifier: `com.macguardian.suite.ui`

## Common Issues

### "Cannot index window tabs due to missing main bundle identifier"

**Solution:** Set the bundle identifier as described above.

### "Unable to obtain a task name port right"

**Solution:** This is a macOS permission issue. It usually resolves after:
- Setting the bundle identifier
- Restarting Xcode
- Rebuilding the project

### Swift Package Not Loading

**Solution:**
```bash
cd MacGuardianSuiteUI
swift package resolve
swift package update
```

## Build Configurations

### Debug Build
- Press `Cmd + B` in Xcode
- Or: `swift build`

### Release Build (App Bundle)
```bash
./build_app.sh
```

### Run from Terminal
```bash
swift run MacGuardianSuiteUI
```

## Xcode Tips

- **View Package Structure:** File → Open → Select `Package.swift`
- **Build Output:** View → Navigators → Show Report Navigator (`Cmd + 9`)
- **Debug:** Set breakpoints and press `Cmd + R`
- **Clean Build:** Product → Clean Build Folder (`Cmd + Shift + K`)

## Bundle Identifier

**Default:** `com.macguardian.suite.ui`

This is set in:
- `Info.plist` (for app bundle)
- Xcode scheme settings (for development)
- Build settings (for production)

