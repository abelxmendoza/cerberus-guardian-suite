#!/usr/bin/env python3
"""
Splunk Output Module - Send events to Splunk via HEC (HTTP Event Collector)
"""

import requests
import json
import gzip
from typing import List, Dict
from datetime import datetime


class SplunkOutput:
    """
    Output module for Splunk HEC.
    Sends events in batches to Splunk HTTP Event Collector.
    """
    
    def __init__(self, config: Dict):
        self.config = config
        self.enabled = config.get("enabled", False)
        self.url = config.get("url", "")
        self.token = config.get("token", "")
        self.index = config.get("index", "macguardian")
        self.batch_size = config.get("batch_size", 100)
        self.buffer = []
        
        if not self.url or not self.token:
            self.enabled = False
            print("⚠️  Splunk output disabled: URL or token not configured")
    
    def __call__(self, events: List[Dict]):
        """Handle batch of events (called by event bus)"""
        if not self.enabled:
            return
        
        self.buffer.extend(events)
        
        # Send batch when full
        if len(self.buffer) >= self.batch_size:
            self._send_batch()
    
    def _send_batch(self):
        """Send buffered events to Splunk"""
        if not self.buffer:
            return
        
        # Format events for Splunk HEC
        hec_events = []
        for event in self.buffer:
            hec_events.append({
                "time": self._parse_timestamp(event.get("timestamp")),
                "host": event.get("host", "unknown"),
                "source": event.get("source", "macguardian"),
                "sourcetype": f"macguardian:{event.get('event_type', 'unknown')}",
                "index": self.index,
                "event": event
            })
        
        # Send to Splunk HEC
        headers = {
            "Authorization": f"Splunk {self.token}",
            "Content-Type": "application/json"
        }
        
        hec_url = f"{self.url}/services/collector/event"
        
        try:
            response = requests.post(
                hec_url,
                headers=headers,
                json=hec_events,
                timeout=10
            )
            response.raise_for_status()
            print(f"✅ Sent {len(self.buffer)} events to Splunk")
            self.buffer = []
        except requests.exceptions.RequestException as e:
            print(f"❌ Error sending to Splunk: {e}")
            # Keep buffer for retry
    
    def _parse_timestamp(self, timestamp_str: str) -> float:
        """Parse ISO timestamp to Unix epoch"""
        try:
            dt = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
            return dt.timestamp()
        except:
            return datetime.utcnow().timestamp()


if __name__ == "__main__":
    # Test the output
    output = SplunkOutput({
        "enabled": True,
        "url": "https://splunk.example.com:8088",
        "token": "your-hec-token",
        "index": "macguardian"
    })
    
    test_events = [
        {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "event_type": "test.event",
            "source": "test",
            "data": {"test": True}
        }
    ]
    
    output(test_events)

