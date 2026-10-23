# MacGuardian Watchdog - Entitlements Request

## Required Entitlements

### File System Access
- **`com.apple.security.files.user-selected.read-write`**
  - Purpose: Allow user to select directories for monitoring
  - Required for: File Integrity Monitoring (FIM)
  - User consent: Required

### Network Access
- **`com.apple.security.network.client`**
  - Purpose: Connect to threat intelligence feeds
  - Required for: Network monitoring and threat detection
  - User consent: Not required

- **`com.apple.security.network.server`**
  - Purpose: Local WebSocket server for SwiftUI dashboard
  - Required for: Real-time event streaming
  - User consent: Not required (localhost only)

### System Access
- **`com.apple.security.inherit`**
  - Purpose: Inherit parent process permissions
  - Required for: Launchd service execution
  - User consent: Not required

### Notifications
- **`com.apple.developer.usernotifications`**
  - Purpose: Send security alerts to user
  - Required for: Alert system
  - User consent: Required (requested at runtime)

## Optional Entitlements

### Hypervisor (Optional)
- **`com.apple.security.hypervisor`**
  - Purpose: Advanced virtualization monitoring
  - Required for: Future VM detection features
  - User consent: Not required
  - Status: Not currently used

## Privacy Permissions (TCC)

These are requested at runtime, not via entitlements:

1. **Full Disk Access** (kTCCServiceSystemPolicyAllFiles)
   - Required for: File Integrity Monitoring
   - Requested via: System Settings

2. **Screen Recording** (kTCCServiceScreenCapture)
   - Optional: Screenshot analysis
   - Requested via: System Settings

3. **Accessibility** (kTCCServiceAccessibility)
   - Optional: Process monitoring
   - Requested via: System Settings

4. **Input Monitoring** (kTCCServiceListenEvent)
   - Optional: Keyboard/mouse event monitoring
   - Requested via: System Settings

## Hardened Runtime Requirements

- **Hardened Runtime**: Enabled
- **Library Validation**: Enabled
- **Kill on Invalid Code Signature**: Enabled
- **No JIT**: Disabled (not applicable for SwiftUI app)

## Code Signing

- **Signing Identity**: Developer ID Application
- **Notarization**: Required for distribution
- **Timestamp**: Required

## Sandboxing

- **Sandbox Enabled**: Yes (for daemons)
- **Sandbox Profile**: `hardening/sandbox_profile.sb`
- **Exceptions**: None

## App Transport Security

- **ATS Enabled**: Yes
- **Exception Domains**: None
- **Requires Certificate Pinning**: No (local services only)

