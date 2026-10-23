import Foundation
import Combine

/// High-performance ring buffer using Swift Actors for thread-safe, lock-free operations
/// Fixed capacity, O(1) push and read operations
actor RingBufferActor<T> {
    private let capacity: Int
    private var buffer: [T?]
    private var writeIndex: Int = 0
    private var count: Int = 0
    
    init(capacity: Int = 1000) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    /// Push an item to the ring buffer (O(1))
    /// Automatically overwrites oldest item when full
    func push(_ item: T) {
        buffer[writeIndex] = item
        writeIndex = (writeIndex + 1) % capacity
        
        if count < capacity {
            count += 1
        }
    }
    
    /// Get a snapshot of all items in chronological order (O(n))
    /// Returns array sorted by insertion order (newest first)
    func snapshot() -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        
        if count == 0 {
            return result
        }
        
        // Start from writeIndex - 1 (most recent) and work backwards
        var index = (writeIndex - 1 + capacity) % capacity
        
        for _ in 0..<count {
            if let item = buffer[index] {
                result.append(item)
            }
            index = (index - 1 + capacity) % capacity
        }
        
        return result
    }
    
    /// Get the most recent N items (O(n))
    func recent(_ n: Int) -> [T] {
        return Array(snapshot().prefix(n))
    }
    
    /// Clear all items (O(1))
    func clear() {
        buffer = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }
    
    /// Current number of items
    var size: Int {
        return count
    }
    
    /// Check if buffer is full
    var isFull: Bool {
        return count >= capacity
    }
    
    /// Check if buffer is empty
    var isEmpty: Bool {
        return count == 0
    }
}

/// Observable wrapper for RingBufferActor
final class RingBuffer<T>: ObservableObject {
    private let actor: RingBufferActor<T>
    
    @Published var didUpdate = false
    
    init(capacity: Int = 1000) {
        self.actor = RingBufferActor<T>(capacity: capacity)
    }
    
    /// Push an item to the ring buffer (O(1))
    func push(_ item: T) {
        Task {
            await actor.push(item)
            await MainActor.run {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Get a snapshot of all items (O(n))
    func snapshot() async -> [T] {
        return await actor.snapshot()
    }
    
    /// Get the most recent N items (O(n))
    func recent(_ n: Int) async -> [T] {
        return await actor.recent(n)
    }
    
    /// Clear all items (O(1))
    func clear() {
        Task {
            await actor.clear()
            await MainActor.run {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Current number of items
    var size: Int {
        get async {
            await actor.size
        }
    }
    
    /// Check if buffer is full
    var isFull: Bool {
        get async {
            await actor.isFull
        }
    }
    
    /// Check if buffer is empty
    var isEmpty: Bool {
        get async {
            await actor.isEmpty
        }
    }
}

