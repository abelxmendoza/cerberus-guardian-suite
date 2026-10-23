# MacGuardian Watchdog - Test Inventory

## Test Coverage Overview

### ✅ Unit Tests (3 files)

**Location**: `tests/unit/`

1. **`test_validators.sh`** (BATS format)
   - Tests input validation functions
   - Validates path, email, int, enum, severity, event_type
   - Tests command injection prevention
   - Tests path traversal prevention

2. **`test_system_state.sh`** (BATS format)
   - Tests SIP/SSV/TCC status checks
   - Tests system state summary generation
   - Tests system compatibility checks

3. **`test_hashing.sh`** (BATS format)
   - Tests file hash computation (MD5, SHA1, SHA256, SHA512)
   - Tests directory hash computation
   - Tests hash verification

**Status**: ✅ Written, requires BATS framework to run

---

### ✅ Integration Tests (2 files)

**Location**: `tests/integration/`

1. **`test_event_pipeline.sh`** (BATS format)
   - Tests Event Spec v1.0.0 compliance
   - Tests event severity validation
   - Tests timestamp ISO8601 format
   - Tests JSON parsing

2. **`test_watcher_output.sh`** (BATS format)
   - Tests fsevents_watcher Event Spec compliance
   - Tests process_watcher Event Spec compliance
   - Tests network_watcher Event Spec compliance
   - Tests UUID v4 format validation
   - Tests ISO8601 timestamp validation

**Status**: ✅ Written, requires BATS framework to run

---

### ✅ Manual/Functional Tests (via run_all_tests.sh)

**Location**: `tests/run_all_tests.sh`

**Current Tests**:
1. **Syntax Validation** (22 scripts)
   - All core modules
   - All daemons
   - All auditors

2. **Validator Tests** (6 tests)
   - validate_path - valid path
   - validate_path - injection attempt
   - validate_email - valid email
   - validate_int - valid integer
   - validate_severity - valid severity
   - validate_event_type - valid event type

3. **Event Writer Tests** (2 tests)
   - Event Spec v1.0.0 compliance
   - Required fields validation

4. **Python Tests** (2 tests)
   - event_bus.py syntax validation
   - event_bus.py import test

**Status**: ✅ Running successfully

---

### ✅ End-to-End Tests (1 file)

**Location**: `tests/e2e/`

1. **`test_full_installation.sh`** (Bash)
   - Tests installation flow
   - Tests event generation
   - Tests event bus functionality
   - Automatic cleanup

**Status**: ✅ Running successfully

**Additional E2E Tests Needed**:
- Complete monitoring cycle test
- Event bus → SwiftUI flow test
- Auditor → Event → Dashboard flow test
- Uninstall flow test

---

### ❌ Performance Tests (0 files)

**Missing Performance Tests**:
- Event processing throughput
- Memory usage under load
- CPU usage during monitoring
- Log rotation performance
- Event bus WebSocket performance

**Status**: ❌ Not yet implemented

---

### ✅ Security Tests (1 file)

**Location**: `tests/security/`

1. **`test_input_injection.sh`** (Bash)
   - Tests command injection prevention
   - Tests path traversal prevention
   - Tests SQL injection prevention
   - Tests XSS prevention

**Status**: ✅ Running successfully (4/4 tests passing)

**Additional Security Tests Needed**:
- Privilege escalation attempts
- Sandbox escape attempts
- Code injection attempts
- Privilege boundary testing

---

## Test Execution

### Running All Tests

```bash
cd MacGuardianSuite/tests
bash run_all_tests.sh
```

### Running Specific Test Types

**Unit Tests** (requires BATS):
```bash
bats tests/unit/test_validators.sh
bats tests/unit/test_system_state.sh
bats tests/unit/test_hashing.sh
```

**Integration Tests** (requires BATS):
```bash
bats tests/integration/test_event_pipeline.sh
bats tests/integration/test_watcher_output.sh
```

**End-to-End Tests**:
```bash
bash tests/e2e/test_full_installation.sh
```

**Security Tests**:
```bash
bash tests/security/test_input_injection.sh
```

**Manual Tests**:
```bash
# Syntax validation
bash -n MacGuardianSuite/core/validators.sh

# Python tests
python3 -m py_compile MacGuardianSuite/outputs/event_bus.py
python3 -c "from event_bus import EventBus"
```

## Test Coverage Summary

| Test Type | Files | Status | Framework |
|-----------|-------|--------|-----------|
| Unit Tests | 3 | ✅ Written | BATS |
| Integration Tests | 2 | ✅ Written | BATS |
| End-to-End Tests | 1 | ✅ Running | Bash |
| Security Tests | 1 | ✅ Running | Bash |
| Manual/Functional | 10+ | ✅ Running | Bash |
| Performance Tests | 0 | ❌ Missing | - |

## Recommendations

1. **Install BATS** to run unit/integration tests:
   ```bash
   brew install bats-core
   ```

2. **Create End-to-End Tests**:
   - Test full installation → monitoring → event generation → dashboard display
   - Test uninstall flow
   - Test configuration changes

3. **Create Performance Tests**:
   - Benchmark event processing
   - Test under load
   - Memory leak detection

4. **Create Security Tests**:
   - Penetration testing
   - Input validation edge cases
   - Privilege boundary testing

5. **Add SwiftUI Tests**:
   - UI component tests
   - Integration with LiveUpdateService
   - Dashboard rendering tests

