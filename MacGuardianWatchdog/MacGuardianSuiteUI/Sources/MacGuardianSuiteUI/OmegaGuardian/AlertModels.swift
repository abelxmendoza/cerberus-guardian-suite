import Foundation

// MARK: - Omega Guardian Alert Models

enum AlertCondition: Codable, Equatable, Hashable {
    case iocMatch
    case processBehavior
    case networkAnomaly
    case fileModification
    case custom(pattern: String)
    
    var displayName: String {
        switch self {
        case .iocMatch: return "IOC Match"
        case .processBehavior: return "Process Behavior"
        case .networkAnomaly: return "Network Anomaly"
        case .fileModification: return "File Modification"
        case .custom(let pattern): return "Custom: \(pattern)"
        }
    }
}

struct AlertRule: Identifiable, Codable {
    let id: UUID
    var name: String
    var severity: ThreatSeverity
    var condition: AlertCondition
    var enabled: Bool
    var throttleMinutes: Int
    var description: String?
    
    init(id: UUID = UUID(), name: String, severity: ThreatSeverity, condition: AlertCondition, enabled: Bool = true, throttleMinutes: Int = 5, description: String? = nil) {
        self.id = id
        self.name = name
        self.severity = severity
        self.condition = condition
        self.enabled = enabled
        self.throttleMinutes = throttleMinutes
        self.description = description
    }
}

struct Incident: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let severity: ThreatSeverity
    let title: String
    let message: String
    let sourceModule: String
    let metadata: [String: String]
    var acknowledged: Bool
    var resolved: Bool
    
    init(id: UUID = UUID(), timestamp: Date = Date(), severity: ThreatSeverity, title: String, message: String, sourceModule: String, metadata: [String: String] = [:], acknowledged: Bool = false, resolved: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.severity = severity
        self.title = title
        self.message = message
        self.sourceModule = sourceModule
        self.metadata = metadata
        self.acknowledged = acknowledged
        self.resolved = resolved
    }
}

