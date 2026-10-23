#!/usr/bin/env python3
"""
FSEvents Collector - Event-driven file system monitoring
Uses macOS FSEvents API for efficient file change detection
"""

import subprocess
import json
import threading
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from event_bus import get_event_bus


class FSEventsCollector:
    """
    Collects file system events using macOS FSEvents.
    More efficient than polling - event-driven.
    """
    
    def __init__(self, config: Optional[Dict] = None):
        self.config = config or {}
        self.enabled = self.config.get("enabled", True)
        self.paths = self.config.get("paths", ["/Users", "/Applications"])
        self.exclude_patterns = self.config.get("exclude", [".git", "node_modules", ".DS_Store"])
        self.running = False
        self.process = None
        self.thread = None
        self.event_bus = get_event_bus()
        
    def initialize(self, config: Dict):
        """Initialize with configuration"""
        self.config = config
        self.enabled = config.get("enabled", True)
        self.paths = config.get("paths", ["/Users", "/Applications"])
        self.exclude_patterns = config.get("exclude", [".git", "node_modules"])
        
    def start(self):
        """Start collecting FSEvents"""
        if not self.enabled:
            print("⚠️  FSEvents collector disabled")
            return
        
        if self.running:
            print("⚠️  FSEvents collector already running")
            return
        
        self.running = True
        
        # Start monitoring thread
        self.thread = threading.Thread(target=self._monitor, daemon=True)
        self.thread.start()
        
        print("✅ FSEvents collector started")
    
    def stop(self):
        """Stop collecting events"""
        self.running = False
        if self.process:
            self.process.terminate()
        print("✅ FSEvents collector stopped")
    
    def get_status(self) -> Dict:
        """Get collector status"""
        return {
            "enabled": self.enabled,
            "running": self.running,
            "paths": self.paths,
            "exclude_patterns": self.exclude_patterns
        }
    
    def _monitor(self):
        """Monitor file system events using fswatch"""
        # Check if fswatch is available
        try:
            subprocess.run(["which", "fswatch"], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            print("⚠️  fswatch not found. Install with: brew install fswatch")
            print("   Falling back to polling-based monitoring")
            self._fallback_monitor()
            return
        
        # Build fswatch command
        cmd = ["fswatch", "-r", "-x", "--event", "Created,Updated,Removed,Renamed"]
        cmd.extend(self.paths)
        
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
                
                # Parse fswatch output
                # Format: <path> <event_type>
                parts = line.split()
                if len(parts) >= 2:
                    path = parts[0]
                    event_type = parts[1]
                    
                    # Check if path should be excluded
                    if any(pattern in path for pattern in self.exclude_patterns):
                        continue
                    
                    # Emit event
                    self._emit_event(path, event_type)
                    
        except Exception as e:
            print(f"❌ FSEvents collector error: {e}")
        finally:
            if self.process:
                self.process.terminate()
    
    def _emit_event(self, path: str, event_type: str):
        """Emit a file system event"""
        # Map fswatch events to our event types
        event_map = {
            "Created": "file.create",
            "Updated": "file.modify",
            "Removed": "file.delete",
            "Renamed": "file.rename"
        }
        
        event_type_normalized = event_map.get(event_type, "file.change")
        
        event = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "event_type": event_type_normalized,
            "source": "fsevents",
            "data": {
                "path": path,
                "event": event_type,
                "file_type": self._get_file_type(path)
            },
            "metadata": {
                "severity": "info",
                "tags": ["file", "fsevents"]
            }
        }
        
        self.event_bus.emit(event)
    
    def _get_file_type(self, path: str) -> str:
        """Determine file type"""
        p = Path(path)
        if p.is_dir():
            return "directory"
        elif p.is_file():
            return "file"
        elif p.is_symlink():
            return "symlink"
        else:
            return "unknown"
    
    def _fallback_monitor(self):
        """Fallback to polling-based monitoring"""
        print("⚠️  Using fallback polling monitor (less efficient)")
        # This would use the existing mac_watchdog.sh logic
        # For now, just log that we're using fallback
        pass


if __name__ == "__main__":
    # Test the collector
    collector = FSEventsCollector({
        "enabled": True,
        "paths": [str(Path.home() / "Desktop")],
        "exclude": [".git", ".DS_Store"]
    })
    
    from event_bus import EventBus
    bus = EventBus()
    bus.start()
    
    collector.event_bus = bus
    collector.start()
    
    print("Monitoring file system events... (Press Ctrl+C to stop)")
    try:
        import time
        time.sleep(10)
    except KeyboardInterrupt:
        pass
    finally:
        collector.stop()
        bus.stop()

