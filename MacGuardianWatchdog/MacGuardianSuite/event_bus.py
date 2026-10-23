#!/usr/bin/env python3
"""
Event Bus - Central event routing and buffering system
Part of MacGuardian's modular architecture
"""

import json
import queue
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Callable
import gzip
import os

class EventBus:
    """
    Central event bus for MacGuardian.
    Routes events from collectors to output modules.
    """
    
    def __init__(self, config_dir: Optional[Path] = None):
        self.config_dir = config_dir or Path.home() / ".macguardian"
        self.buffer_dir = self.config_dir / "event_buffer"
        self.buffer_dir.mkdir(parents=True, exist_ok=True)
        
        # In-memory queue
        self.event_queue = queue.Queue(maxsize=10000)
        
        # Output handlers
        self.output_handlers: List[Callable] = []
        
        # Statistics
        self.stats = {
            "events_received": 0,
            "events_sent": 0,
            "events_dropped": 0,
            "buffer_size": 0
        }
        
        # Threading
        self.running = False
        self.worker_thread = None
        self.buffer_thread = None
        
    def start(self):
        """Start the event bus"""
        self.running = True
        
        # Start worker thread
        self.worker_thread = threading.Thread(target=self._worker, daemon=True)
        self.worker_thread.start()
        
        # Start buffer flush thread
        self.buffer_thread = threading.Thread(target=self._buffer_flusher, daemon=True)
        self.buffer_thread.start()
        
        print("✅ Event bus started")
    
    def stop(self):
        """Stop the event bus"""
        self.running = False
        
        # Flush remaining events
        self._flush_buffer()
        
        if self.worker_thread:
            self.worker_thread.join(timeout=5)
        if self.buffer_thread:
            self.buffer_thread.join(timeout=5)
        
        print("✅ Event bus stopped")
    
    def register_output(self, handler: Callable):
        """Register an output handler"""
        self.output_handlers.append(handler)
        handler_name = getattr(handler, '__name__', handler.__class__.__name__)
        print(f"✅ Registered output handler: {handler_name}")
    
    def emit(self, event: Dict):
        """
        Emit an event to the bus.
        
        Args:
            event: Event dictionary with required fields:
                - timestamp: ISO format timestamp
                - event_type: Type of event (e.g., "process.exec")
                - source: Source collector name
                - data: Event-specific data
        """
        # Normalize event
        normalized = self._normalize_event(event)
        
        # Try to add to queue (non-blocking)
        try:
            self.event_queue.put_nowait(normalized)
            self.stats["events_received"] += 1
        except queue.Full:
            # Queue full, write to disk buffer
            self._write_to_buffer(normalized)
            self.stats["events_dropped"] += 1
    
    def _normalize_event(self, event: Dict) -> Dict:
        """Normalize event to common schema"""
        normalized = {
            "timestamp": event.get("timestamp", datetime.utcnow().isoformat() + "Z"),
            "event_type": event.get("event_type", "unknown"),
            "source": event.get("source", "unknown"),
            "host": event.get("host", os.uname().nodename),
            "user": event.get("user", os.getenv("USER", "unknown")),
            "data": event.get("data", {}),
            "metadata": event.get("metadata", {})
        }
        
        # Add correlation ID if not present
        if "correlation_id" not in normalized["metadata"]:
            normalized["metadata"]["correlation_id"] = self._generate_correlation_id()
        
        return normalized
    
    def _generate_correlation_id(self) -> str:
        """Generate a unique correlation ID"""
        import uuid
        return str(uuid.uuid4())[:8]
    
    def _worker(self):
        """Worker thread that processes events"""
        batch = []
        batch_size = 100
        last_flush = time.time()
        flush_interval = 1.0  # Flush every second
        
        while self.running:
            try:
                # Get event from queue (with timeout)
                event = self.event_queue.get(timeout=0.1)
                batch.append(event)
                
                # Flush if batch is full or timeout reached
                if len(batch) >= batch_size or (time.time() - last_flush) >= flush_interval:
                    self._process_batch(batch)
                    batch = []
                    last_flush = time.time()
                    
            except queue.Empty:
                # No events, check for buffered events
                if batch:
                    self._process_batch(batch)
                    batch = []
                    last_flush = time.time()
                continue
    
    def _process_batch(self, batch: List[Dict]):
        """Process a batch of events"""
        if not batch:
            return
        
        # Send to all output handlers
        for handler in self.output_handlers:
            try:
                handler(batch)
                self.stats["events_sent"] += len(batch)
            except Exception as e:
                print(f"⚠️  Error in output handler {handler.__name__}: {e}")
        
        self.stats["buffer_size"] = self.event_queue.qsize()
    
    def _write_to_buffer(self, event: Dict):
        """Write event to disk buffer"""
        buffer_file = self.buffer_dir / f"buffer_{int(time.time())}.jsonl.gz"
        
        with gzip.open(buffer_file, "at") as f:
            f.write(json.dumps(event) + "\n")
    
    def _buffer_flusher(self):
        """Periodically flush buffered events from disk"""
        while self.running:
            time.sleep(10)  # Check every 10 seconds
            self._flush_buffer()
    
    def _flush_buffer(self):
        """Flush events from disk buffer"""
        buffer_files = sorted(self.buffer_dir.glob("buffer_*.jsonl.gz"))
        
        for buffer_file in buffer_files[:10]:  # Process up to 10 files at a time
            try:
                events = []
                with gzip.open(buffer_file, "rt") as f:
                    for line in f:
                        if line.strip():
                            events.append(json.loads(line))
                
                if events:
                    self._process_batch(events)
                    buffer_file.unlink()  # Delete after processing
                    
            except Exception as e:
                print(f"⚠️  Error flushing buffer {buffer_file}: {e}")
    
    def get_stats(self) -> Dict:
        """Get event bus statistics"""
        return {
            **self.stats,
            "queue_size": self.event_queue.qsize(),
            "buffer_files": len(list(self.buffer_dir.glob("buffer_*.jsonl.gz")))
        }


# Global event bus instance
_event_bus: Optional[EventBus] = None

def get_event_bus() -> EventBus:
    """Get or create the global event bus instance"""
    global _event_bus
    if _event_bus is None:
        _event_bus = EventBus()
    return _event_bus


if __name__ == "__main__":
    # Test the event bus
    bus = EventBus()
    bus.start()
    
    # Register a test output
    def test_output(events):
        print(f"📤 Output: {len(events)} events")
        for event in events[:3]:  # Print first 3
            print(f"  - {event['event_type']} from {event['source']}")
    
    bus.register_output(test_output)
    
    # Emit some test events
    for i in range(5):
        bus.emit({
            "event_type": "test.event",
            "source": "test_collector",
            "data": {"counter": i}
        })
        time.sleep(0.1)
    
    time.sleep(1)
    print(f"\n📊 Stats: {bus.get_stats()}")
    bus.stop()

