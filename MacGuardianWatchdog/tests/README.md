# MacGuardian Test Suite

## Overview

This directory contains test suites for MacGuardian Watchdog components.

## Structure

```
tests/
├── bash/           # Shell script tests
├── python/         # Python module tests
├── ui/             # SwiftUI view tests (future)
└── fixtures/       # Test data and mocks
```

## Running Tests

### Bash Tests

```bash
# Run SSH auditor tests
bash tests/bash/test_ssh_auditor.sh

# Run all bash tests
find tests/bash -name "test_*.sh" -exec bash {} \;
```

### Python Tests

```bash
# Run event bus tests
python3 -m pytest tests/python/test_event_bus.py

# Run all Python tests
python3 -m pytest tests/python/
```

### SwiftUI Tests

```bash
# Run SwiftUI tests (requires Xcode)
xcodebuild test -scheme MacGuardianSuiteUI
```

## Test Coverage

### Current Tests
- ✅ SSH Auditor (bash)
- ✅ Event Bus (python)
- ⏳ User Account Auditor (bash)
- ⏳ Process Watcher (bash)
- ⏳ Network Watcher (bash)
- ⏳ IDS Engine (bash)
- ⏳ SwiftUI Views (ui)

### Planned Tests
- JSON schema validation
- WebSocket connection tests
- Timeline formatter tests
- Network flow builder tests
- Config editor tests

## Writing Tests

### Bash Test Template

```bash
#!/bin/bash

test_function_name() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Test: Description... "
    
    if command_to_test; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}
```

### Python Test Template

```python
import unittest

class TestModule(unittest.TestCase):
    def setUp(self):
        # Setup test fixtures
        pass
    
    def test_feature(self):
        # Test implementation
        self.assertEqual(expected, actual)
```

## Continuous Integration

Tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Bash Tests
  run: bash tests/bash/test_ssh_auditor.sh

- name: Run Python Tests
  run: python3 -m pytest tests/python/
```

## Notes

- Tests should be idempotent (can run multiple times)
- Use fixtures directory for test data
- Clean up test artifacts after tests
- Mock external dependencies when possible

