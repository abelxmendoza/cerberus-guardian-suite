import Foundation
import Combine

/// High-performance hash-indexed event store using Swift Actors
/// O(1) lookups by event_type, thread-safe and lock-free
actor EventIndexActor {
    private var index: [String: [MacGuardianEvent]] = [:]
    private let maxEventsPerType: Int
    
    init(maxEventsPerType: Int = 500) {
        self.maxEventsPerType = maxEventsPerType
    }
    
    /// Insert an event into the index (O(1))
    func insert(_ event: MacGuardianEvent) {
        let eventType = event.event_type
        
        if index[eventType] == nil {
            index[eventType] = []
        }
        
        // Insert at beginning (newest first)
        index[eventType]?.insert(event, at: 0)
        
        // Trim to maxEventsPerType
        if let count = index[eventType]?.count, count > maxEventsPerType {
            index[eventType] = Array(index[eventType]!.prefix(maxEventsPerType))
        }
    }
    
    /// Get all events of a specific type (O(1))
    func events(forType type: String) -> [MacGuardianEvent] {
        return index[type] ?? []
    }
    
    /// Get events matching multiple types (O(k) where k = number of types)
    func events(forTypes types: [String]) -> [MacGuardianEvent] {
        var result: [MacGuardianEvent] = []
        for type in types {
            if let events = index[type] {
                result.append(contentsOf: events)
            }
        }
        // Sort by timestamp (newest first)
        return result.sorted { event1, event2 in
            guard let date1 = event1.date, let date2 = event2.date else {
                return event1.timestamp > event2.timestamp
            }
            return date1 > date2
        }
    }
    
    /// Get all events (O(n) where n = total events)
    func allEvents() -> [MacGuardianEvent] {
        var result: [MacGuardianEvent] = []
        for events in index.values {
            result.append(contentsOf: events)
        }
        // Sort by timestamp (newest first)
        return result.sorted { event1, event2 in
            guard let date1 = event1.date, let date2 = event2.date else {
                return event1.timestamp > event2.timestamp
            }
            return date1 > date2
        }
    }
    
    /// Get count of events for a specific type (O(1))
    func count(forType type: String) -> Int {
        return index[type]?.count ?? 0
    }
    
    /// Get total count across all types (O(k) where k = number of types)
    func totalCount() -> Int {
        return index.values.reduce(0) { $0 + $1.count }
    }
    
    /// Clear all events (O(1))
    func clear() {
        index.removeAll()
    }
    
    /// Clear events for a specific type (O(1))
    func clear(forType type: String) {
        index.removeValue(forKey: type)
    }
    
    /// Get all event types currently in index (O(k))
    func eventTypes() -> [String] {
        return Array(index.keys)
    }
}

/// Observable wrapper for EventIndexActor
final class EventIndex: ObservableObject {
    private let actor: EventIndexActor
    
    @Published var didUpdate = false
    
    init(maxEventsPerType: Int = 500) {
        self.actor = EventIndexActor(maxEventsPerType: maxEventsPerType)
    }
    
    /// Insert an event into the index (O(1))
    func insert(_ event: MacGuardianEvent) {
        Task {
            await actor.insert(event)
            await MainActor.run {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Get all events of a specific type (O(1))
    func events(forType type: String) async -> [MacGuardianEvent] {
        return await actor.events(forType: type)
    }
    
    /// Get events matching multiple types (O(k) where k = number of types)
    func events(forTypes types: [String]) async -> [MacGuardianEvent] {
        return await actor.events(forTypes: types)
    }
    
    /// Get all events (O(n) where n = total events)
    func allEvents() async -> [MacGuardianEvent] {
        return await actor.allEvents()
    }
    
    /// Get count of events for a specific type (O(1))
    func count(forType type: String) async -> Int {
        return await actor.count(forType: type)
    }
    
    /// Get total count across all types (O(k) where k = number of types)
    func totalCount() async -> Int {
        return await actor.totalCount()
    }
    
    /// Clear all events (O(1))
    func clear() {
        Task {
            await actor.clear()
            await MainActor.run {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Clear events for a specific type (O(1))
    func clear(forType type: String) {
        Task {
            await actor.clear(forType: type)
            await MainActor.run {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Get all event types currently in index (O(k))
    func eventTypes() async -> [String] {
        return await actor.eventTypes()
    }
    
    /// Subscript access for convenience (async)
    subscript(eventType: String) -> [MacGuardianEvent] {
        get async {
            await actor.events(forType: eventType)
        }
    }
}

