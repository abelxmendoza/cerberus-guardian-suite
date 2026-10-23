#!/usr/bin/env python3
"""
Unified Logging Collector - macOS system logs via log stream
Collects security events, system events, and application logs
"""

import subprocess
import json
import threading
from datetime import datetime
from typing import Dict, Optional
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from event_bus import get_event_bus


class UnifiedLoggingCollector:
    """
    Collects events from macOS Unified Logging system.
    Uses `log stream` command for real-time log monitoring.
    """
    
    def __init__(self, config: Optional[Dict] = None):
        self.config = config or {}
        self.enabled = self.config.get("enabled", True)
        self.predicates = self.config.get("predicates", ["subsystem:com.apple.security"])
        self.running = False
        self.process = None
        self.thread = None
        self.event_bus = get_event_bus()
        
    def initialize(self, config: Dict):
        """Initialize with configuration"""
        self.config = config
        self.enabled = config.get("enabled", True)
        self.predicates = config.get("predicates", ["subsystem:com.apple.security"])
        
    def start(self):
        """Start collecting unified logs"""
        if not self.enabled:
            print("⚠️  Unified Logging collector disabled")
            return
        
        if self.running:
            print("⚠️  Unified Logging collector already running")
            return
        
        self.running = True
        
        # Start monitoring thread
        self.thread = threading.Thread(target=self._monitor, daemon=True)
        self.thread.start()
        
        print("✅ Unified Logging collector started")
    
    def stop(self):
        """Stop collecting events"""
        self.running = False
        if self.process:
            self.process.terminate()
        print("✅ Unified Logging collector stopped")
    
    def get_status(self) -> Dict:
        """Get collector status"""
        return {
            "enabled": self.enabled,
            "running": self.running,
            "predicates": self.predicates
        }
    
    def _monitor(self):
        """Monitor unified logs using log stream"""
        # Build log stream command
        cmd = ["log", "stream", "--style", "json", "--predicate"]
        
        # Combine predicates with OR
        predicate = " OR ".join(self.predicates)
        cmd.append(predicate)
        
        try:
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )
            
            for line in self.process.stdout:
                if not self.running:
                    break
                
                line = line.strip()
                if not line:
                    continue
                
                try:
                    # Parse JSON log entry
                    log_entry = json.loads(line)
                    self._emit_event(log_entry)
                except json.JSONDecodeError:
                    continue
                    
        except Exception as e:
            print(f"❌ Unified Logging collector error: {e}")
        finally:
            if self.process:
                self.process.terminate()
    
    def _emit_event(self, log_entry: Dict):
        """Emit a unified log event"""
        # Extract relevant fields
        event_type = log_entry.get("eventType", "log.entry")
        subsystem = log_entry.get("subsystem", "unknown")
        category = log_entry.get("category", "unknown")
        message = log_entry.get("eventMessage", "")
        
        # Determine severity
        severity_map = {
            "Default": "info",
            "Info": "info",
            "Debug": "debug",
            "Error": "error",
            "Fault": "critical"
        }
        severity = severity_map.get(log_entry.get("eventType", "Default"), "info")
        
        event = {
            "timestamp": log_entry.get("timestamp", datetime.utcnow().isoformat() + "Z"),
            "event_type": f"log.{subsystem}.{category}",
            "source": "unified_logging",
            "data": {
                "subsystem": subsystem,
                "category": category,
                "message": message,
                "process": log_entry.get("process", "unknown"),
                "pid": log_entry.get("processID", 0)
            },
            "metadata": {
                "severity": severity,
                "tags": ["log", subsystem, category]
            }
        }
        
        self.event_bus.emit(event)


if __name__ == "__main__":
    # Test the collector
    collector = UnifiedLoggingCollector({
        "enabled": True,
        "predicates": [
            "subsystem:com.apple.security",
            "subsystem:com.apple.network"
        ]
    })
    
    from event_bus import EventBus
    bus = EventBus()
    bus.start()
    
    collector.event_bus = bus
    collector.start()
    
    print("Monitoring unified logs... (Press Ctrl+C to stop)")
    try:
        import time
        time.sleep(10)
    except KeyboardInterrupt:
        pass
    finally:
        collector.stop()
        bus.stop()

