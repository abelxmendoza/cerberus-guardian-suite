# Images Directory

This directory contains all image assets for the MacGuardian Suite UI application.

## Logo Files

Place your logo image here with one of these names:
- **`MacGlogo.png`** (primary - currently used)
- **`MacGuardianLogo.png`** (fallback - also supported)
- **`.jpg`** or **`.jpeg`** formats are also supported

## Logo Specifications

- **Primary Name**: `MacGlogo` (case-sensitive)
- **Fallback Name**: `MacGuardianLogo` (also supported)
- **Formats**: PNG (recommended), JPG, JPEG
- **Size**: 512x512 pixels or higher for best quality
- **Background**: Transparent PNG preferred, or match your app theme

## Current Logo Description

The MacGuardian Watchdog logo features:
- 🐺 Cybernetic canine head with purple outline
- 👁️ Red glowing eyes
- Ω Purple Omega symbol on forehead
- 🍎 Apple logo in mouth (glowing magenta)
- ⚡ Red energy cracks around jaw
- 📝 "MACGUARDIAN" and "WATCHDOG" text
- 🎨 Dark purple/black background

## Usage

The logo is automatically loaded by the `LogoView` component and appears in:
- Welcome screen (150px)
- Dashboard header (80px)
- Settings header (60px)
- Tool detail view (48px)
- Sidebar (40px)
- Reports/History headers (32-40px)
- Tab navigation bar (24px)

## Build Process

The build script (`build_app.sh`) automatically copies all files from this directory to the app bundle's Resources folder during the build process.

## Other Assets

You can also place other image assets here:
- Icons
- Background images
- UI elements
- Screenshots

All files in this directory will be included in the final app bundle.

