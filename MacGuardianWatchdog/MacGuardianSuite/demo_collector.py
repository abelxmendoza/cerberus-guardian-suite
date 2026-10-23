#!/usr/bin/env python3
"""
Demo: Real-time event collection
Shows events being collected and routed
"""

import time
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from event_bus import EventBus
from collectors.fsevents import FSEventsCollector
from collectors.unified_logging import UnifiedLoggingCollector
from outputs.local import LocalOutput


def main():
    print("🔄 MacGuardian Collector - Live Demo")
    print("=" * 60)
    print()
    
    # Initialize event bus
    bus = EventBus()
    
    # Register local output with console logging
    events_count = {"count": 0}
    
    def console_output(events):
        events_count["count"] += len(events)
        for event in events[:3]:  # Show first 3 events
            event_type = event.get("event_type", "unknown")
            source = event.get("source", "unknown")
            timestamp = event.get("timestamp", "")[:19]  # Truncate to seconds
            print(f"  [{timestamp}] {event_type} ({source})")
        if len(events) > 3:
            print(f"  ... and {len(events) - 3} more events")
    
    bus.register_output(console_output)
    
    # Also register local file output
    local_output = LocalOutput({
        "enabled": True,
        "format": "jsonl",
        "path": "~/.macguardian/events"
    })
    bus.register_output(local_output)
    
    bus.start()
    
    # Start collectors
    print("📁 Starting FSEvents collector...")
    fsevents = FSEventsCollector({
        "enabled": True,
        "paths": [str(Path.home() / "Desktop")],
        "exclude": [".git", ".DS_Store", "Library"]
    })
    fsevents.event_bus = bus
    fsevents.start()
    
    print("📋 Starting Unified Logging collector...")
    unified = UnifiedLoggingCollector({
        "enabled": True,
        "predicates": ["subsystem:com.apple.security"]
    })
    unified.event_bus = bus
    unified.start()
    
    print()
    print("✅ Collectors running! Monitoring for 10 seconds...")
    print("   (Try creating/modifying files on your Desktop)")
    print()
    
    # Monitor for 10 seconds
    start_time = time.time()
    last_stats_time = start_time
    
    try:
        while time.time() - start_time < 10:
            time.sleep(1)
            
            # Show stats every 3 seconds
            if time.time() - last_stats_time >= 3:
                stats = bus.get_stats()
                print(f"\n📊 Stats: {stats['events_received']} received, "
                      f"{stats['events_sent']} sent, "
                      f"{stats['queue_size']} in queue")
                last_stats_time = time.time()
    except KeyboardInterrupt:
        print("\n⚠️  Interrupted by user")
    
    # Final stats
    print()
    print("=" * 60)
    final_stats = bus.get_stats()
    print(f"📊 Final Statistics:")
    print(f"   Events received: {final_stats['events_received']}")
    print(f"   Events sent: {final_stats['events_sent']}")
    print(f"   Events dropped: {final_stats['events_dropped']}")
    print(f"   Console events shown: {events_count['count']}")
    print()
    
    # Stop collectors
    print("🛑 Stopping collectors...")
    fsevents.stop()
    unified.stop()
    bus.stop()
    
    print()
    print("✅ Demo complete!")
    print()
    print("💡 Events saved to: ~/.macguardian/events/")
    print("   View with: cat ~/.macguardian/events/events_*.jsonl | head -20")


if __name__ == "__main__":
    main()

