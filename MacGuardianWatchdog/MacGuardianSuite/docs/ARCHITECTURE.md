# MacGuardian Watchdog - System Architecture

## Overview

MacGuardian Watchdog is a production-grade macOS security platform with real-time monitoring, blue-team auditing, intrusion detection, and a SwiftUI dashboard interface.

## Architecture Layers

### 1. Core Layer (`core/`)

**Purpose**: Foundation modules used by all other components

**Modules**:
- `validators.sh` - Input validation and sanitization
- `logging.sh` - Unified logging with rotation
- `hashing.sh` - File integrity hashing
- `privilege_check.sh` - Privilege boundary enforcement
- `system_state.sh` - macOS system awareness (SIP/SSV/TCC)
- `config_loader.sh` - Configuration management
- `config_validator.sh` - Configuration validation

**Characteristics**:
- Pure bash for compatibility
- No external dependencies
- Exported functions for reuse
- Input validation on all user-facing data

### 2. Daemon Layer (`daemons/`)

**Purpose**: Real-time monitoring daemons

**Components**:
- `mg_monitor.sh` - Main monitoring loop controller
- `event_writer.sh` - Event Spec v1.0.0 compliant event writer
- `watchers/` - Individual watcher modules
  - `fsevents_watcher.sh` - File system monitoring
  - `process_watcher.sh` - Process anomaly detection
  - `network_watcher.sh` - Network connection monitoring
  - `cron_watcher.sh` - Cron job monitoring
- `timeline_sync.sh` - Timeline synchronization

**Data Flow**:
```
Watcher → event_writer.sh → Event Spec v1.0.0 JSON → Event Bus → SwiftUI
```

### 3. Auditor Layer (`auditors/`)

**Purpose**: Blue-team security auditing

**Components**:
- `ssh_auditor.sh` - SSH configuration auditing
- `user_account_auditor.sh` - User account auditing
- `cron_auditor.sh` - Cron job auditing
- `network_deep_audit.sh` - Network security auditing
- `log_aggregator.sh` - Log aggregation

**Characteristics**:
- Run on-demand or scheduled
- Output JSON audit results
- Compare against baselines
- Generate security reports

### 4. Detector Layer (`detectors/`)

**Purpose**: Intrusion detection and threat detection

**Components**:
- `ids_engine.sh` - Intrusion Detection System
- `signature_engine.sh` - Signature-based detection
- `ransomware_detector.sh` - Ransomware detection

**Data Flow**:
```
Events → IDS Engine → Correlation Rules → Incidents → Remediation
```

### 5. Privacy Layer (`privacy/`)

**Purpose**: macOS Privacy (TCC) monitoring

**Components**:
- `tcc_auditor.sh` - TCC permission auditing

### 6. Output Layer (`outputs/`)

**Purpose**: Event distribution and notification

**Components**:
- `event_bus.py` - Central event hub (UDS + WebSocket)
- `timeline_formatter.py` - Timeline generation
- `webhook_notifier.sh` - Webhook notifications

**Event Bus Architecture**:
```
Shell Scripts → UDS Socket (/tmp/macguardian.sock) → Event Bus
                                                              ↓
SwiftUI ← WebSocket (ws://localhost:9765) ← Event Bus ← Event Validation
```

### 7. SwiftUI Layer (`MacGuardianSuiteUI/`)

**Purpose**: User interface and visualization

**Components**:
- `Services/LiveUpdateService.swift` - WebSocket client
- `Views/` - Dashboard views
- `Components/` - Reusable UI components
- `UX/` - Theme and styling system

**Data Flow**:
```
Event Bus (WebSocket) → LiveUpdateService → Combine Publishers → SwiftUI Views
```

## Event Flow

### Real-Time Monitoring Flow

```
1. Watcher detects change
   ↓
2. Validates input (validators.sh)
   ↓
3. Creates Event Spec v1.0.0 JSON (event_writer.sh)
   ↓
4. Writes to ~/.macguardian/events/ (JSON file)
   ↓
5. Sends to Event Bus via UDS socket
   ↓
6. Event Bus validates Event Spec v1.0.0
   ↓
7. Event Bus broadcasts via WebSocket
   ↓
8. SwiftUI LiveUpdateService receives event
   ↓
9. SwiftUI views update reactively
```

### Audit Flow

```
1. User triggers audit (SwiftUI or CLI)
   ↓
2. Auditor runs (with sudo if needed)
   ↓
3. Compares current state vs baseline
   ↓
4. Generates Event Spec v1.0.0 JSON results
   ↓
5. Writes audit JSON to ~/.macguardian/audits/
   ↓
6. SwiftUI reads and displays results
```

## Security Boundaries

### Privilege Levels

**Non-Sudo (Default)**:
- Watchers (read-only monitoring)
- Event Bus (event distribution)
- SwiftUI frontend
- Log viewing

**Sudo Required**:
- Auditors (system file access)
- Remediation (system modifications)
- Quarantine operations
- System configuration changes

### Input Validation

All user-facing inputs must pass through `validators.sh`:
- Path validation (prevents injection)
- Integer validation (prevents overflow)
- Enum validation (prevents invalid values)
- Email validation (prevents injection)

### System Awareness

All modules check system state before operations:
- SIP status (may limit system file access)
- SSV status (may limit system volume writes)
- TCC permissions (may limit file access)
- Full Disk Access (required for FIM)

## Data Storage

### Event Storage
- **Location**: `~/.macguardian/events/`
- **Format**: JSON files (one event per file)
- **Naming**: `event_{event_id}.json`
- **Permissions**: 600 (owner read/write only)

### Timeline Storage
- **Location**: `~/.macguardian/logs/timeline.jsonl`
- **Format**: JSONL (one event per line)
- **Rotation**: Automatic (5MB max)

### Baseline Storage
- **Location**: `~/.macguardian/baselines/`
- **Format**: JSON files
- **Retention**: Configurable (default 90 days)

### Log Storage
- **Location**: `~/.macguardian/logs/`
- **Files**: `core.log`, `watchers.log`, `auditors.log`, `detectors.log`
- **Rotation**: Automatic (5MB max, 7 days retention)

## Configuration

### Configuration File
- **Location**: `~/.macguardian/config.yaml`
- **Fallback**: `MacGuardianSuite/config/config.yaml`
- **Format**: YAML
- **Validation**: `config_validator.sh`

### Configuration Loading
1. Check user config (`~/.macguardian/config.yaml`)
2. Fallback to default config
3. Validate all values
4. Export as environment variables

## Testing

### Test Structure
```
tests/
├── unit/          # Unit tests for individual modules
├── integration/   # Integration tests for workflows
├── fixtures/      # Test data and mocks
└── helpers/       # Test utilities
```

### Test Execution
- **Bash Tests**: `bats tests/unit/test_validators.sh`
- **Python Tests**: `pytest tests/python/`
- **Swift Tests**: `xcodebuild test`

## Deployment

### Installation
1. Clone repository
2. Run `install_monitor_daemon.sh`
3. Configure `config.yaml`
4. Create baselines
5. Start Event Bus: `python3 outputs/event_bus.py`
6. Launch SwiftUI app

### Monitoring
- Event Bus runs continuously
- Monitor daemon runs as LaunchAgent
- Logs rotate automatically
- Events stored in `~/.macguardian/events/`

## Scalability

### Current Limits
- Event cache: 1000 events (Event Bus)
- Log size: 5MB per file
- Timeline: JSONL (unlimited size)

### Future Enhancements
- Database backend for events
- Distributed monitoring (multiple Macs)
- Cloud sync for baselines
- Centralized dashboard

## Security Considerations

1. **Input Validation**: All inputs validated
2. **Privilege Separation**: Clear sudo boundaries
3. **Secure Storage**: Event files have 600 permissions
4. **System Awareness**: Respects macOS security features
5. **Audit Trail**: All operations logged

## Performance

### Resource Usage
- **CPU**: Low (2-5% during monitoring)
- **Memory**: ~50MB (Event Bus + daemon)
- **Disk**: ~10MB/day (events + logs)

### Optimization
- Event caching in Event Bus
- Log rotation prevents disk fill
- Watchers use efficient polling
- JSONL format for fast parsing

