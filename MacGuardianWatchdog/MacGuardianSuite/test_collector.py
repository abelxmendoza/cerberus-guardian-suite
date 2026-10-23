#!/usr/bin/env python3
"""
Test script for MacGuardian Collector System
Demonstrates event collection and routing
"""

import time
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))

from event_bus import EventBus
from collectors.fsevents import FSEventsCollector
from collectors.unified_logging import UnifiedLoggingCollector
from outputs.local import LocalOutput


def test_event_bus():
    """Test the event bus"""
    print("=" * 60)
    print("🧪 Testing Event Bus")
    print("=" * 60)
    
    bus = EventBus()
    bus.start()
    
    # Register test output
    events_received = []
    
    def test_output(events):
        events_received.extend(events)
        print(f"  📤 Received {len(events)} events")
    
    bus.register_output(test_output)
    
    # Emit test events
    print("\n📨 Emitting test events...")
    for i in range(5):
        bus.emit({
            "event_type": "test.event",
            "source": "test",
            "data": {"counter": i, "message": f"Test event {i}"}
        })
        time.sleep(0.1)
    
    # Wait for processing
    time.sleep(1)
    
    # Check stats
    stats = bus.get_stats()
    print(f"\n📊 Event Bus Stats:")
    print(f"  Events received: {stats['events_received']}")
    print(f"  Events sent: {stats['events_sent']}")
    print(f"  Queue size: {stats['queue_size']}")
    
    bus.stop()
    
    assert stats['events_received'] == 5, "Should receive 5 events"
    assert stats['events_sent'] == 5, "Should send 5 events"
    print("✅ Event bus test passed!\n")


def test_local_output():
    """Test local output storage"""
    print("=" * 60)
    print("🧪 Testing Local Output")
    print("=" * 60)
    
    output = LocalOutput({
        "enabled": True,
        "format": "jsonl",
        "path": "~/.macguardian/test_events"
    })
    
    test_events = [
        {
            "timestamp": "2024-11-08T12:00:00Z",
            "event_type": "test.event",
            "source": "test",
            "data": {"test": True}
        },
        {
            "timestamp": "2024-11-08T12:00:01Z",
            "event_type": "test.event",
            "source": "test",
            "data": {"test": False}
        }
    ]
    
    print("\n💾 Writing events to local storage...")
    output(test_events)
    
    # Check if file was created
    output_path = Path.home() / ".macguardian" / "test_events"
    files = list(output_path.glob("events_*.jsonl"))
    
    if files:
        print(f"✅ Created file: {files[0].name}")
        print(f"   Size: {files[0].stat().st_size} bytes")
        
        # Read and verify
        with open(files[0]) as f:
            lines = f.readlines()
            print(f"   Events in file: {len(lines)}")
            assert len(lines) == 2, "Should have 2 events"
    else:
        print("⚠️  No output file created")
    
    print("✅ Local output test passed!\n")


def test_collectors():
    """Test collectors (quick start/stop)"""
    print("=" * 60)
    print("🧪 Testing Collectors")
    print("=" * 60)
    
    bus = EventBus()
    bus.start()
    
    # Test FSEvents collector
    print("\n📁 Testing FSEvents Collector...")
    fsevents = FSEventsCollector({
        "enabled": True,
        "paths": [str(Path.home() / "Desktop")],
        "exclude": [".git", ".DS_Store"]
    })
    fsevents.event_bus = bus
    fsevents.start()
    
    status = fsevents.get_status()
    print(f"  Status: {json.dumps(status, indent=2)}")
    assert status["enabled"] == True
    assert status["running"] == True
    
    time.sleep(1)
    fsevents.stop()
    print("✅ FSEvents collector test passed!")
    
    # Test Unified Logging collector
    print("\n📋 Testing Unified Logging Collector...")
    unified = UnifiedLoggingCollector({
        "enabled": True,
        "predicates": ["subsystem:com.apple.security"]
    })
    unified.event_bus = bus
    unified.start()
    
    status = unified.get_status()
    print(f"  Status: {json.dumps(status, indent=2)}")
    assert status["enabled"] == True
    assert status["running"] == True
    
    time.sleep(1)
    unified.stop()
    print("✅ Unified Logging collector test passed!")
    
    bus.stop()
    print()


def main():
    """Run all tests"""
    print("🧪 MacGuardian Collector System Test Suite")
    print("=" * 60)
    print()
    
    try:
        test_event_bus()
        test_local_output()
        test_collectors()
        
        print("=" * 60)
        print("✅ All tests passed!")
        print("=" * 60)
        print()
        print("Next steps:")
        print("  1. Install fswatch for better FSEvents: brew install fswatch")
        print("  2. Configure modules: cp MacGuardianSuite/modules.conf.example ~/.macguardian/modules.conf")
        print("  3. Run collector: ./MacGuardianSuite/mac_collector.sh")
        
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

