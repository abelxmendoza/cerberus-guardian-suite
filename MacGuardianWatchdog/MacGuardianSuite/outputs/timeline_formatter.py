#!/usr/bin/env python3

"""
Timeline Formatter
Aggregates events from all sources into unified timeline
"""

import json
import sys
import os
from datetime import datetime
from typing import List, Dict, Any
from pathlib import Path

def load_events(event_dir: str) -> List[Dict[str, Any]]:
    """Load all events from event directory"""
    events = []
    event_path = Path(event_dir)
    
    if not event_path.exists():
        return events
    
    for event_file in event_path.glob('event_*.json'):
        try:
            with open(event_file, 'r') as f:
                event = json.load(f)
                events.append(event)
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error loading {event_file}: {e}", file=sys.stderr)
            continue
    
    return events

def parse_timestamp(timestamp_str: str) -> datetime:
    """Parse ISO8601 timestamp"""
    try:
        # Try with fractional seconds
        if '.' in timestamp_str or 'T' in timestamp_str:
            return datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        else:
            return datetime.strptime(timestamp_str, '%Y-%m-%dT%H:%M:%SZ')
    except ValueError:
        # Fallback to current time
        return datetime.utcnow()

def format_timeline(events: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Format events into timeline structure"""
    # Sort by timestamp
    sorted_events = sorted(
        events,
        key=lambda e: parse_timestamp(e.get('timestamp', ''))
    )
    
    # Group by type
    by_type = {}
    for event in sorted_events:
        event_type = event.get('type', 'unknown')
        if event_type not in by_type:
            by_type[event_type] = []
        by_type[event_type].append(event)
    
    # Calculate statistics
    severity_counts = {}
    for event in sorted_events:
        severity = event.get('severity', 'unknown')
        severity_counts[severity] = severity_counts.get(severity, 0) + 1
    
    return {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'total_events': len(sorted_events),
        'event_types': {k: len(v) for k, v in by_type.items()},
        'severity_counts': severity_counts,
        'events': sorted_events,
        'timeline': [
            {
                'time': event.get('timestamp', ''),
                'type': event.get('type', 'unknown'),
                'severity': event.get('severity', 'unknown'),
                'message': event.get('message', ''),
                'details': event.get('details', {})
            }
            for event in sorted_events
        ]
    }

def main():
    """Main function"""
    if len(sys.argv) < 3:
        print("Usage: timeline_formatter.py <event_dir> <output_file>", file=sys.stderr)
        sys.exit(1)
    
    event_dir = sys.argv[1]
    output_file = sys.argv[2]
    
    events = load_events(event_dir)
    timeline = format_timeline(events)
    
    # Ensure output directory exists
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, 'w') as f:
        json.dump(timeline, f, indent=2)
    
    print(f"Timeline formatted: {len(events)} events")
    print(f"Output: {output_file}")

if __name__ == '__main__':
    main()

