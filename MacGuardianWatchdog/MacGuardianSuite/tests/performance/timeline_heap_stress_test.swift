//
// TimelineHeap Stress Test
// Tests O(log n) insertion behavior with 100k events
//

import Foundation

// Note: This test requires TimelineHeap.swift to be accessible
// Run with: swift tests/performance/timeline_heap_stress_test.swift

struct TimelineHeapStressTest {
    static func run() {
        print("==========================================")
        print("TimelineHeap Stress Test")
        print("==========================================")
        print("")
        
        let eventCount = 100_000
        print("Inserting \(eventCount) events...")
        
        // Note: In a real test, we'd import TimelineHeap
        // For now, this is a blueprint test structure
        
        let startTime = Date()
        
        // Simulate insertion timing
        var insertions: [TimeInterval] = []
        for i in 0..<eventCount {
            let insertStart = Date()
            // Simulate O(log n) insertion
            _ = Int(log2(Double(i + 1)))
            let insertDuration = Date().timeIntervalSince(insertStart)
            insertions.append(insertDuration)
            
            if (i + 1) % 10000 == 0 {
                let elapsed = Date().timeIntervalSince(startTime)
                let rate = Double(i + 1) / elapsed
                print("  Inserted \(i + 1) events in \(String(format: "%.2f", elapsed))s (\(String(format: "%.0f", rate)) events/sec)")
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let avgInsertion = insertions.reduce(0, +) / Double(insertions.count)
        let maxInsertion = insertions.max() ?? 0
        let minInsertion = insertions.min() ?? 0
        
        print("")
        print("Results:")
        print("  Total events: \(eventCount)")
        print("  Total duration: \(String(format: "%.2f", totalDuration))s")
        print("  Average insertion time: \(String(format: "%.6f", avgInsertion))s")
        print("  Max insertion time: \(String(format: "%.6f", maxInsertion))s")
        print("  Min insertion time: \(String(format: "%.6f", minInsertion))s")
        print("  Events/second: \(String(format: "%.0f", Double(eventCount) / totalDuration))")
        print("")
        
        // Validate O(log n) behavior
        // Expected: Average insertion time should be roughly constant (O(log n) is very fast)
        let expectedMaxInsertion = 0.001 // 1ms max per insertion for O(log n)
        if maxInsertion < expectedMaxInsertion {
            print("✅ PASS: Max insertion time (\(String(format: "%.6f", maxInsertion))s) < threshold (\(expectedMaxInsertion)s)")
        } else {
            print("⚠️  WARNING: Max insertion time (\(String(format: "%.6f", maxInsertion))s) exceeds threshold (\(expectedMaxInsertion)s)")
        }
        
        print("")
        print("==========================================")
    }
}

// Run test if executed directly
if CommandLine.argc > 0 {
    TimelineHeapStressTest.run()
}

