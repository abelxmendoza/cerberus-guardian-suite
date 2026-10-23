import Foundation
import SwiftUI
import Combine

/// Optimized view model for Incident Timeline
/// Implements pagination and lazy loading
@MainActor
class TimelineViewModel: ObservableObject {
    @Published var events: [MacGuardianEvent] = []
    @Published var isLoading = false
    
    private let liveService = LiveUpdateService.shared
    private let pageSize = 50
    private var currentPage = 0
    private var cancellables = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?
    
    init() {
        setupObservers()
        startPeriodicUpdate()
    }
    
    private func setupObservers() {
        // Observe LiveUpdateService reverseChronologicalEvents updates with debouncing
        liveService.$reverseChronologicalEvents
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadPage(0)
            }
            .store(in: &cancellables)
        
        // Also observe lastUpdate for immediate refresh
        liveService.$lastUpdate
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadPage(0)
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpdate() {
        updateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.loadPage(0)
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    func loadPage(_ page: Int) {
        isLoading = true
        
        let allEvents = liveService.reverseChronologicalEvents
        
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, allEvents.count)
        
        if startIndex < allEvents.count {
            let pageEvents = Array(allEvents[startIndex..<endIndex])
            
            // Only update if changed
            if pageEvents != Array(events.prefix(pageEvents.count)) {
                events = pageEvents
            }
        }
        
        isLoading = false
    }
    
    func loadNextPage() {
        currentPage += 1
        let allEvents = liveService.reverseChronologicalEvents
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allEvents.count)
        
        if startIndex < allEvents.count {
            let newEvents = Array(allEvents[startIndex..<endIndex])
            events.append(contentsOf: newEvents)
        }
    }
    
    deinit {
        updateTask?.cancel()
    }
}

