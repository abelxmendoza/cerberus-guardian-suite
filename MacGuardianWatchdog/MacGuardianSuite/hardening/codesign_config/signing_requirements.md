# Code Signing Requirements

## Signing Identity

- **Type**: Developer ID Application
- **Organization**: Omega Technologies
- **Team ID**: [Your Team ID]

## Signing Process

### 1. Sign the Application Bundle

```bash
codesign --force --deep --sign "Developer ID Application: Omega Technologies" \
    --entitlements hardening/codesign_config/plist_entitlements.xml \
    --options runtime \
    MacGuardianSuiteUI.app
```

### 2. Verify Signature

```bash
codesign --verify --verbose MacGuardianSuiteUI.app
spctl --assess --verbose MacGuardianSuiteUI.app
```

### 3. Notarize the Application

```bash
# Create zip for notarization
ditto -c -k --keepParent MacGuardianSuiteUI.app MacGuardianSuiteUI.zip

# Submit for notarization
xcrun notarytool submit MacGuardianSuiteUI.zip \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password" \
    --wait

# Staple the notarization ticket
xcrun stapler staple MacGuardianSuiteUI.app
```

### 4. Verify Notarization

```bash
spctl --assess --type install --verbose MacGuardianSuiteUI.app
xcrun stapler validate MacGuardianSuiteUI.app
```

## Signing Scripts

Shell scripts should be signed if they're distributed:

```bash
codesign --sign "Developer ID Application: Omega Technologies" \
    --force \
    installers/macos_installer.sh
```

## Hardened Runtime Options

- **`--options runtime`**: Enable Hardened Runtime
- **`--entitlements`**: Use entitlements plist
- **`--timestamp`**: Include timestamp (required for notarization)

## Distribution

For distribution outside Mac App Store:
- Use Developer ID Application certificate
- Notarize with Apple
- Staple notarization ticket

For Mac App Store:
- Use Mac App Distribution certificate
- Submit through App Store Connect
- No manual notarization needed

