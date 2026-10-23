# 🔧 Script Fixes Applied

## Issues Fixed

### 1. ✅ `threat_intel_feeds.sh` - "bold: unbound variable" Error
**Problem**: Script used `${bold}` and `${normal}` variables without sourcing `utils.sh`

**Fix**: Added `source "$SCRIPT_DIR/utils.sh"` at the top of the script

**File**: `MacGuardianSuite/threat_intel_feeds.sh`
```bash
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
```

---

### 2. ✅ `stix_exporter.py` - Missing Arguments Error
**Problem**: Python script requires 2 arguments (input file, output file) but UI ran it without arguments

**Fix**: Created wrapper script `stix_exporter_wrapper.sh` that provides default arguments:
- Input: `$HOME/.macguardian/threat_intel/iocs.json`
- Output: `$HOME/.macguardian/threat_intel/iocs.stix.json`

**Files**: 
- `MacGuardianSuite/stix_exporter_wrapper.sh` (new)
- Updated tool definition in `AppState.swift` to use wrapper

---

### 3. ✅ `advanced_alerting.sh` - Hanging/No Output
**Problem**: Script was running but not showing output or completing

**Fix**: Updated tool definition to explicitly pass `"process"` argument

**File**: `MacGuardianSuiteUI/Sources/MacGuardianSuiteUI/AppState.swift`
```swift
SuiteTool(
    name: "Advanced Alerting",
    description: "Manage custom alert rules and severity-based notifications.",
    relativePath: "MacGuardianSuite/advanced_alerting.sh",
    arguments: ["process"]  // ← Added this
)
```

---

## Testing

All scripts should now work correctly:

1. **Threat Intel Feeds**: ✅ Should run without "unbound variable" error
2. **STIX Exporter**: ✅ Should use default paths and create files if needed
3. **Advanced Alerting**: ✅ Should process rules and show results

---

## Next Steps

If you encounter any other script errors:
1. Check if the script sources `utils.sh` for color variables
2. Check if the script requires arguments and add them to the tool definition
3. Check if the script is interactive and needs non-interactive flags

