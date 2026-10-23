# Event Spec v1.0.0 Migration Guide

## Overview

This guide helps migrate existing watchers, auditors, and detectors to Event Spec v1.0.0 compliant JSON-only output.

## Migration Checklist

### Before Migration
- [ ] Source core modules (`validators.sh`, `logging.sh`, `system_state.sh`)
- [ ] Source `event_writer.sh`
- [ ] Remove all `echo` statements for output
- [ ] Remove all plaintext logging

### During Migration
- [ ] Replace legacy `write_event()` calls with Event Spec v1.0.0 format
- [ ] Use `write_event(event_type, severity, source_module, context_json)`
- [ ] Validate all paths with `validate_path()`
- [ ] Use proper Event Spec v1.0.0 event types
- [ ] Use proper severity levels: `low`, `medium`, `high`, `critical`

### After Migration
- [ ] Test event output is valid JSON
- [ ] Verify events appear in timeline
- [ ] Check Event Bus receives events
- [ ] Verify SwiftUI dashboards display events

## Event Type Mapping

### Legacy → Event Spec v1.0.0

| Legacy Type | Event Spec v1.0.0 Type |
|-------------|------------------------|
| `filesystem` / `fs` | `file_integrity_change` |
| `process` | `process_anomaly` |
| `network` | `network_connection` |
| `dns` | `dns_request` |
| `ids` / `correlation` | `ids_alert` |
| `ssh` | `ssh_key_change` |
| `cron` | `cron_modification` |
| `privacy` / `tcc_privacy` | `tcc_permission_change` |
| `user_accounts` | `user_account_change` |
| `ransomware` | `ransomware_activity` |
| `signature` | `signature_hit` |

## Severity Mapping

### Legacy → Event Spec v1.0.0

| Legacy | Event Spec v1.0.0 |
|--------|-------------------|
| `info` | `low` |
| `warning` | `medium` |
| `high` | `high` |
| `critical` | `critical` |

## Example Migrations

### Before (Legacy)

```bash
write_event "filesystem" "high" "File changed" '{"file": "/path/to/file"}'
```

### After (Event Spec v1.0.0)

```bash
source "$SUITE_DIR/core/validators.sh"
source "$SCRIPT_DIR/event_writer.sh"

# Validate path
if ! validate_path "/path/to/file" false; then
    log_error "Invalid file path"
    return 1
fi

# Create context JSON
local context_json="{\"file_path\": \"/path/to/file\", \"change_type\": \"modified\"}"

# Write Event Spec v1.0.0 event
write_event "file_integrity_change" "high" "fsevents_watcher" "$context_json"
```

## Context JSON Structure

### File Integrity Change

```json
{
  "file_path": "/path/to/file",
  "change_type": "modified|deleted|created|permission_changed",
  "directory": "/path/to/directory",
  "file_count": 15,
  "old_hash": "sha256...",
  "new_hash": "sha256..."
}
```

### Process Anomaly

```json
{
  "pid": 12345,
  "process_name": "suspicious_app",
  "cpu_percent": 85.5,
  "memory_mb": 512,
  "command": "/path/to/app",
  "user": "username",
  "anomaly_type": "high_cpu|suspicious_pattern|hidden_process"
}
```

### Network Connection

```json
{
  "pid": 12345,
  "process_name": "curl",
  "local_ip": "192.168.1.100",
  "local_port": 54321,
  "remote_ip": "1.2.3.4",
  "remote_port": 80,
  "protocol": "tcp",
  "connection_state": "ESTABLISHED"
}
```

## Testing Migration

After migrating a module:

1. Run the module manually
2. Check `~/.macguardian/events/` for new event files
3. Verify JSON is valid: `python3 -m json.tool event_*.json`
4. Check Event Bus receives events
5. Verify SwiftUI dashboard displays events

## Common Issues

### Issue: Events not appearing in timeline
**Solution**: Ensure `log_json_event()` is called in `event_writer.sh`

### Issue: Invalid JSON
**Solution**: Use `validate_path()` and escape strings properly

### Issue: Event Bus rejects events
**Solution**: Check Event Spec v1.0.0 validation - ensure all required fields present

### Issue: Wrong event type
**Solution**: Use Event Spec v1.0.0 event type enum (see EVENT_SPEC.md)

