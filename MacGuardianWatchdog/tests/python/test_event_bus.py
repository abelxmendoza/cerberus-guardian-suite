#!/usr/bin/env python3

"""
Event Bus Test Suite
"""

import unittest
import json
import socket
import asyncio
import websockets
from pathlib import Path
import sys

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "MacGuardianSuite" / "outputs"))

from event_bus import EventBus, Event


class TestEventBus(unittest.TestCase):
    """Test Event Bus functionality"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.bus = EventBus()
        self.test_event = {
            "timestamp": "2024-01-15T10:30:45Z",
            "type": "process",
            "severity": "high",
            "source": "process_watcher",
            "message": "Test event",
            "context": {"pid": 12345}
        }
    
    def test_event_normalization(self):
        """Test event normalization"""
        event = self.bus.normalize_event(self.test_event)
        
        self.assertIsInstance(event, Event)
        self.assertEqual(event.type, "process")
        self.assertEqual(event.severity, "high")
        self.assertEqual(event.source, "process_watcher")
        self.assertEqual(event.message, "Test event")
    
    def test_event_to_json(self):
        """Test event JSON serialization"""
        event = self.bus.normalize_event(self.test_event)
        json_str = event.to_json()
        
        self.assertIsInstance(json_str, str)
        parsed = json.loads(json_str)
        self.assertEqual(parsed["type"], "process")
    
    def test_source_inference(self):
        """Test source inference from event type"""
        self.assertEqual(self.bus._infer_source("process"), "process_watcher")
        self.assertEqual(self.bus._infer_source("network"), "network_watcher")
        self.assertEqual(self.bus._infer_source("fs"), "fsevents_watcher")
        self.assertEqual(self.bus._infer_source("unknown"), "unknown")
    
    def test_event_storage(self):
        """Test event storage to disk"""
        event = self.bus.normalize_event(self.test_event)
        self.bus.store_event(event)
        
        # Check if event file was created
        event_dir = Path.home() / ".macguardian" / "events"
        event_files = list(event_dir.glob("event_*.json"))
        self.assertGreater(len(event_files), 0)


class TestEventSchema(unittest.TestCase):
    """Test event schema compliance"""
    
    def test_required_fields(self):
        """Test that all required fields are present"""
        event_data = {
            "timestamp": "2024-01-15T10:30:45Z",
            "type": "process",
            "severity": "high",
            "source": "process_watcher",
            "message": "Test",
            "context": {}
        }
        
        bus = EventBus()
        event = bus.normalize_event(event_data)
        
        self.assertIsNotNone(event.timestamp)
        self.assertIsNotNone(event.type)
        self.assertIsNotNone(event.severity)
        self.assertIsNotNone(event.source)
        self.assertIsNotNone(event.message)
        self.assertIsNotNone(event.context)
    
    def test_severity_values(self):
        """Test valid severity values"""
        valid_severities = ["info", "warning", "critical"]
        
        for severity in valid_severities:
            event_data = {
                "timestamp": "2024-01-15T10:30:45Z",
                "type": "process",
                "severity": severity,
                "source": "process_watcher",
                "message": "Test",
                "context": {}
            }
            
            bus = EventBus()
            event = bus.normalize_event(event_data)
            self.assertEqual(event.severity, severity)


if __name__ == '__main__':
    unittest.main()

