import Foundation
import Combine

// MARK: - Incident Store (Publisher)

class IncidentStore: ObservableObject {
    static let shared = IncidentStore()
    
    @Published var incidents: [Incident] = []
    @Published var unacknowledgedCount: Int = 0
    @Published var criticalCount: Int = 0
    
    private let storageURL: URL
    private let maxIncidents = 1000
    
    private init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let omegaDir = homeDir.appendingPathComponent(".macguardian/omega_guardian")
        storageURL = omegaDir.appendingPathComponent("incidents.json")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: omegaDir, withIntermediateDirectories: true)
        
        loadIncidents()
        updateCounts()
    }
    
    func add(_ incident: Incident) {
        incidents.insert(incident, at: 0)
        
        // Keep only last maxIncidents
        if incidents.count > maxIncidents {
            incidents = Array(incidents.prefix(maxIncidents))
        }
        
        updateCounts()
        saveIncidents()
        
        // Post notification for critical incidents
        if incident.severity == .critical {
            NotificationCenter.default.post(
                name: NSNotification.Name("OmegaGuardianCriticalIncident"),
                object: incident
            )
        }
    }
    
    func acknowledge(_ incident: Incident) {
        if let index = incidents.firstIndex(where: { $0.id == incident.id }) {
            incidents[index].acknowledged = true
            updateCounts()
            saveIncidents()
        }
    }
    
    func resolve(_ incident: Incident) {
        if let index = incidents.firstIndex(where: { $0.id == incident.id }) {
            incidents[index].resolved = true
            updateCounts()
            saveIncidents()
        }
    }
    
    func clearResolved() {
        incidents = incidents.filter { !$0.resolved }
        updateCounts()
        saveIncidents()
    }
    
    private func updateCounts() {
        unacknowledgedCount = incidents.filter { !$0.acknowledged && !$0.resolved }.count
        criticalCount = incidents.filter { $0.severity == .critical && !$0.resolved }.count
    }
    
    private func loadIncidents() {
        guard FileManager.default.fileExists(atPath: storageURL.path),
              let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Incident].self, from: data) else {
            incidents = []
            return
        }
        incidents = decoded
    }
    
    private func saveIncidents() {
        guard let data = try? JSONEncoder().encode(incidents) else { return }
        try? data.write(to: storageURL)
    }
}

