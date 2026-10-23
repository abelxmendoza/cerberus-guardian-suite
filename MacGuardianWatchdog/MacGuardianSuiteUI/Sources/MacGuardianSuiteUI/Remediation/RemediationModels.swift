import Foundation

// MARK: - Remediation Models

struct RemediationAction: Identifiable, Codable {
    let id: UUID
    let name: String
    let impact: String // low, medium, high, critical
    let description: String
    let fixCommand: String
    let category: String?
    let requiresConfirmation: Bool
    let estimatedTime: String?
    let riskLevel: String?
    
    init(id: UUID = UUID(), name: String, impact: String, description: String, fixCommand: String, category: String? = nil, requiresConfirmation: Bool = true, estimatedTime: String? = nil, riskLevel: String? = nil) {
        self.id = id
        self.name = name
        self.impact = impact
        self.description = description
        self.fixCommand = fixCommand
        self.category = category
        self.requiresConfirmation = requiresConfirmation
        self.estimatedTime = estimatedTime
        self.riskLevel = riskLevel
    }
}

struct RemediationResult: Identifiable {
    let id: UUID
    let action: RemediationAction
    let success: Bool
    let message: String
    let timestamp: Date
    
    init(id: UUID = UUID(), action: RemediationAction, success: Bool, message: String, timestamp: Date = Date()) {
        self.id = id
        self.action = action
        self.success = success
        self.message = message
        self.timestamp = timestamp
    }
}

