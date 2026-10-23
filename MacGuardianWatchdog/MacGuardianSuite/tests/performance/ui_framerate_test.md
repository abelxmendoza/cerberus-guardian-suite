# UI Framerate Performance Test

## Overview
This document describes manual testing procedures for verifying SwiftUI UI performance and framerate stability under high event load.

## Prerequisites
- MacGuardian Suite UI running
- Event Bus daemon running (`python3 outputs/event_bus.py`)
- Performance monitoring tools:
  - Xcode Instruments (Time Profiler, System Trace)
  - Activity Monitor
  - `top` or `htop`

## Test Procedure

### 1. Baseline Framerate Test
1. Launch MacGuardian Suite UI
2. Open **Real-Time Dashboard** view
3. Use Xcode Instruments → **System Trace** to monitor framerate
4. Record baseline FPS with no events (should be stable 60 FPS)

### 2. Low Event Load Test (100 events/minute)
1. Generate low-volume test events:
   ```bash
   for i in {1..100}; do
     echo '{"event_id":"'$(uuidgen)'","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","module":"test","event_type":"file_change","severity":"low","details":{}}' | nc -U /tmp/macguardian.sock
     sleep 0.6
   done
   ```
2. Monitor framerate in **Real-Time Dashboard**
3. **Expected**: Stable 60 FPS, no stuttering

### 3. Medium Event Load Test (1,000 events/minute)
1. Generate medium-volume test events:
   ```bash
   for i in {1..1000}; do
     echo '{"event_id":"'$(uuidgen)'","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","module":"test","event_type":"process_spawn","severity":"medium","details":{}}' | nc -U /tmp/macguardian.sock
     sleep 0.06
   done
   ```
2. Monitor framerate in **Real-Time Dashboard**
3. **Expected**: Stable 55-60 FPS, minimal stuttering

### 4. High Event Load Test (5,000 events/minute)
1. Run the automated throughput test:
   ```bash
   bash tests/performance/event_throughput_test.sh
   ```
2. Monitor framerate in **Real-Time Dashboard**
3. **Expected**: Stable 50-60 FPS, acceptable stuttering during bursts

### 5. Stress Test (10,000+ events/minute)
1. Generate high-volume burst:
   ```bash
   for i in {1..10000}; do
     echo '{"event_id":"'$(uuidgen)'","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","module":"test","event_type":"network_connection","severity":"high","details":{}}' | nc -U /tmp/macguardian.sock &
   done
   ```
2. Monitor framerate across all dashboards:
   - Real-Time Dashboard
   - SSH Security Dashboard
   - Network Graph View
   - Incident Timeline View
3. **Expected**: Framerate may drop to 30-45 FPS during bursts, but should recover quickly

## Metrics to Record

### Framerate Metrics
- **Baseline FPS**: 60 FPS (no events)
- **Low Load FPS**: ≥58 FPS (100 events/min)
- **Medium Load FPS**: ≥55 FPS (1,000 events/min)
- **High Load FPS**: ≥50 FPS (5,000 events/min)
- **Stress Test FPS**: ≥30 FPS (10,000+ events/min)

### CPU Usage Metrics
- **Idle CPU**: <1% (no events)
- **Low Load CPU**: <5% (100 events/min)
- **Medium Load CPU**: <10% (1,000 events/min)
- **High Load CPU**: <20% (5,000 events/min)

### Memory Usage Metrics
- **Baseline Memory**: <100 MB
- **Low Load Memory**: <150 MB
- **Medium Load Memory**: <200 MB
- **High Load Memory**: <300 MB

### UI Responsiveness Metrics
- **Button Click Latency**: <100ms
- **View Navigation Latency**: <200ms
- **Scroll Smoothness**: No jank, consistent frame times

## Xcode Instruments Setup

### Time Profiler
1. Product → Profile (⌘I)
2. Select **Time Profiler**
3. Record for 60 seconds during event load
4. Look for:
   - Main thread blocking
   - Excessive SwiftUI view updates
   - RingBuffer/EventIndex operations on main thread

### System Trace
1. Product → Profile (⌘I)
2. Select **System Trace**
3. Record for 60 seconds during event load
4. Look for:
   - Frame drops (red bars)
   - Main thread stalls
   - GPU usage spikes

### Allocations
1. Product → Profile (⌘I)
2. Select **Allocations**
3. Record for 60 seconds during event load
4. Look for:
   - Memory leaks
   - Excessive allocations
   - RingBuffer memory growth

## Performance Issues to Watch For

### Common Issues
1. **Main Thread Blocking**
   - Symptom: UI freezes during event bursts
   - Fix: Ensure all RingBuffer/EventIndex operations are async

2. **Excessive View Updates**
   - Symptom: High CPU usage, frame drops
   - Fix: Implement debouncing and diffing in ViewModels

3. **Memory Leaks**
   - Symptom: Memory usage grows continuously
   - Fix: Check for retain cycles in Combine subscriptions

4. **RingBuffer Overflow**
   - Symptom: Events are dropped, UI shows stale data
   - Fix: Increase RingBuffer capacity or implement event pruning

## Success Criteria

✅ **All tests pass if:**
- Baseline FPS: 60 FPS
- Low Load FPS: ≥58 FPS
- Medium Load FPS: ≥55 FPS
- High Load FPS: ≥50 FPS
- CPU usage: <20% under high load
- Memory usage: <300 MB under high load
- No memory leaks detected
- UI remains responsive during event bursts

## Reporting

After running tests, document:
1. Test environment (macOS version, hardware specs)
2. Framerate results for each test
3. CPU/Memory usage graphs
4. Any performance issues encountered
5. Screenshots of Instruments profiles

## Automated Testing (Future)

Future enhancement: Create XCTest performance tests that:
- Measure frame rendering times
- Validate CPU/memory usage thresholds
- Automatically fail if performance degrades below thresholds

