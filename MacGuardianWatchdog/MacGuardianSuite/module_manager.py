#!/usr/bin/env python3
"""
Module Manager - Manages collector and output modules
Loads, initializes, and coordinates all modules
"""

import importlib
import json
from pathlib import Path
from typing import Dict, List
import sys

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

from event_bus import get_event_bus


class ModuleManager:
    """Manages all collector and output modules"""
    
    def __init__(self, config_file: Path = None):
        self.config_file = config_file or Path.home() / ".macguardian" / "modules.conf"
        self.config = self._load_config()
        self.collectors = []
        self.outputs = []
        self.event_bus = get_event_bus()
        
    def _load_config(self) -> Dict:
        """Load module configuration"""
        if not self.config_file.exists():
            return self._default_config()
        
        # Simple INI-like parser
        config = {}
        current_section = None
        
        with open(self.config_file, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                
                if line.startswith("[") and line.endswith("]"):
                    current_section = line[1:-1]
                    config[current_section] = {}
                elif "=" in line and current_section:
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip()
                    
                    # Parse boolean
                    if value.lower() in ("true", "false"):
                        value = value.lower() == "true"
                    # Parse list
                    elif "," in value:
                        value = [v.strip() for v in value.split(",")]
                    
                    config[current_section][key] = value
        
        return config
    
    def _default_config(self) -> Dict:
        """Return default configuration"""
        return {
            "collectors.fsevents": {
                "enabled": True,
                "paths": ["/Users", "/Applications"],
                "exclude": [".git", "node_modules", ".DS_Store"]
            },
            "collectors.unified_logging": {
                "enabled": True,
                "predicates": ["subsystem:com.apple.security"]
            },
            "outputs.local": {
                "enabled": True,
                "format": "jsonl",
                "path": "~/.macguardian/events"
            }
        }
    
    def load_collectors(self):
        """Load and initialize collector modules"""
        from collectors import fsevents, unified_logging
        
        collectors = {
            "fsevents": fsevents.FSEventsCollector,
            "unified_logging": unified_logging.UnifiedLoggingCollector
        }
        
        for name, collector_class in collectors.items():
            section = f"collectors.{name}"
            if section in self.config:
                config = self.config[section]
                if config.get("enabled", False):
                    collector = collector_class(config)
                    collector.initialize(config)
                    self.collectors.append(collector)
                    print(f"✅ Loaded collector: {name}")
    
    def load_outputs(self):
        """Load and initialize output modules"""
        outputs = {}
        
        # Try to load Splunk output (requires requests module)
        try:
            from outputs import splunk
            outputs["splunk"] = splunk.SplunkOutput
        except ImportError as e:
            if "requests" in str(e):
                print(f"⚠️  Splunk output module not available (requests module not installed)")
                print(f"   Install with: pip3 install requests")
            else:
                print(f"⚠️  Could not load Splunk output: {e}")
        
        for name, output_class in outputs.items():
            section = f"outputs.{name}"
            if section in self.config:
                config = self.config[section]
                if config.get("enabled", False):
                    try:
                        output = output_class(config)
                        self.event_bus.register_output(output)
                        self.outputs.append(output)
                        print(f"✅ Loaded output: {name}")
                    except Exception as e:
                        print(f"⚠️  Failed to initialize output {name}: {e}")
        
        # Always load local output
        from outputs.local import LocalOutput
        local_config = self.config.get("outputs.local", {"enabled": True})
        if local_config.get("enabled", True):
            local_output = LocalOutput(local_config)
            self.event_bus.register_output(local_output)
            self.outputs.append(local_output)
            print("✅ Loaded output: local")
    
    def start_all(self):
        """Start all collectors"""
        self.event_bus.start()
        
        for collector in self.collectors:
            collector.start()
    
    def stop_all(self):
        """Stop all collectors"""
        for collector in self.collectors:
            collector.stop()
        
        self.event_bus.stop()
    
    def get_status(self) -> Dict:
        """Get status of all modules"""
        return {
            "collectors": [c.get_status() for c in self.collectors],
            "outputs": [len(self.outputs)],
            "event_bus": self.event_bus.get_stats()
        }


if __name__ == "__main__":
    # Test the module manager
    manager = ModuleManager()
    manager.load_collectors()
    manager.load_outputs()
    manager.start_all()
    
    print("\n📊 Status:")
    print(json.dumps(manager.get_status(), indent=2))
    
    try:
        import time
        time.sleep(5)
    except KeyboardInterrupt:
        pass
    finally:
        manager.stop_all()

