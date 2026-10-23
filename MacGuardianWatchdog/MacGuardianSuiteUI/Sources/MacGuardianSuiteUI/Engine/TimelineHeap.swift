import Foundation
import Combine

/// Min-heap for efficient chronological timeline management
/// O(log n) insert, O(1) peek at earliest event
struct TimelineEvent: Comparable {
    let event: MacGuardianEvent
    let timestamp: Date
    
    init(event: MacGuardianEvent) {
        self.event = event
        self.timestamp = event.date ?? Date.distantPast
    }
    
    static func < (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        return lhs.event.id == rhs.event.id
    }
}

/// Min-heap implementation for timeline events
final class TimelineHeap: ObservableObject {
    private var heap: [TimelineEvent] = []
    private let maxSize: Int
    private let queue = DispatchQueue(label: "com.macguardian.timelineheap", attributes: .concurrent)
    
    @Published var didUpdate = false
    
    init(maxSize: Int = 10000) {
        self.maxSize = maxSize
    }
    
    /// Insert an event into the heap (O(log n))
    func insert(_ event: MacGuardianEvent) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let timelineEvent = TimelineEvent(event: event)
            
            // If heap is full, remove oldest (root) before inserting
            if self.heap.count >= self.maxSize {
                self.removeMin()
            }
            
            self.heap.append(timelineEvent)
            self.heapifyUp(from: self.heap.count - 1)
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Get earliest event without removing (O(1))
    func peek() -> MacGuardianEvent? {
        return queue.sync {
            return heap.first?.event
        }
    }
    
    /// Remove and return earliest event (O(log n))
    func removeMin() -> MacGuardianEvent? {
        return queue.sync(flags: .barrier) {
            guard !heap.isEmpty else { return nil }
            
            let min = heap[0]
            
            if heap.count == 1 {
                heap.removeAll()
            } else {
                heap[0] = heap.removeLast()
                heapifyDown(from: 0)
            }
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
            
            return min.event
        }
    }
    
    /// Get all events in chronological order (O(n log n))
    func getAllChronological() -> [MacGuardianEvent] {
        return queue.sync {
            // Clone heap and extract all events
            var tempHeap = heap
            var result: [MacGuardianEvent] = []
            
            while !tempHeap.isEmpty {
                result.append(tempHeap[0].event)
                
                if tempHeap.count == 1 {
                    tempHeap.removeAll()
                } else {
                    tempHeap[0] = tempHeap.removeLast()
                    heapifyDownInPlace(&tempHeap, from: 0)
                }
            }
            
            return result
        }
    }
    
    /// Get events in reverse chronological order (newest first) - O(n)
    func getAllReverseChronological() -> [MacGuardianEvent] {
        return getAllChronological().reversed()
    }
    
    /// Snapshot of events (reverse chronological, newest first) - alias for getAllReverseChronological
    func snapshot() -> [MacGuardianEvent] {
        return getAllReverseChronological()
    }
    
    /// Get count
    var count: Int {
        return queue.sync { heap.count }
    }
    
    /// Check if empty
    var isEmpty: Bool {
        return queue.sync { heap.isEmpty }
    }
    
    /// Clear all events
    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.heap.removeAll()
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
    
    // MARK: - Private Heap Operations
    
    private func heapifyUp(from index: Int) {
        var index = index
        while index > 0 {
            let parent = (index - 1) / 2
            if heap[index] >= heap[parent] {
                break
            }
            heap.swapAt(index, parent)
            index = parent
        }
    }
    
    private func heapifyDown(from index: Int) {
        var index = index
        while true {
            let left = 2 * index + 1
            let right = 2 * index + 2
            var smallest = index
            
            if left < heap.count && heap[left] < heap[smallest] {
                smallest = left
            }
            
            if right < heap.count && heap[right] < heap[smallest] {
                smallest = right
            }
            
            if smallest == index {
                break
            }
            
            heap.swapAt(index, smallest)
            index = smallest
        }
    }
    
    private func heapifyDownInPlace(_ heap: inout [TimelineEvent], from index: Int) {
        var index = index
        while true {
            let left = 2 * index + 1
            let right = 2 * index + 2
            var smallest = index
            
            if left < heap.count && heap[left] < heap[smallest] {
                smallest = left
            }
            
            if right < heap.count && heap[right] < heap[smallest] {
                smallest = right
            }
            
            if smallest == index {
                break
            }
            
            heap.swapAt(index, smallest)
            index = smallest
        }
    }
}

