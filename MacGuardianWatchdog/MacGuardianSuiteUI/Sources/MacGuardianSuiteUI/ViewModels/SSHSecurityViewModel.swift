import Foundation
import SwiftUI
import Combine

/// Optimized view model for SSH Security Dashboard
/// Uses async/await and batching to minimize UI updates
@MainActor
class SSHSecurityViewModel: ObservableObject {
    @Published var sshEvents: [MacGuardianEvent] = []
    @Published var isLoading = false
    
    private let liveService = LiveUpdateService.shared
    private var cancellables = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?
    
    init() {
        setupObservers()
        startPeriodicUpdate()
    }
    
    private func setupObservers() {
        // Observe LiveUpdateService sshEvents updates (synchronous @Published property)
        liveService.$sshEvents
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] events in
                // Only update if changed (diffing)
                if events != self?.sshEvents {
                    self?.sshEvents = events
                }
            }
            .store(in: &cancellables)
        
        // Also observe lastUpdate for immediate refresh
        liveService.$lastUpdate
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateEvents()
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpdate() {
        updateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.updateEvents()
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            }
        }
    }
    
    private func updateEvents() {
        // Use synchronous @Published property
        let events = liveService.sshEvents
        
        // Only update if changed (diffing)
        if events != sshEvents {
            sshEvents = events
        }
    }
    
    deinit {
        updateTask?.cancel()
    }
}

