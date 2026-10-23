import Foundation

// MARK: - Security Audit Models

struct AuditCheck: Identifiable, Codable {
    let id: UUID
    let name: String
    let status: String // pass / fail / warning
    let description: String
    let category: String?
    let recommendation: String?
    let severity: String?
    
    init(id: UUID = UUID(), name: String, status: String, description: String, category: String? = nil, recommendation: String? = nil, severity: String? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.description = description
        self.category = category
        self.recommendation = recommendation
        self.severity = severity
    }
}

struct AuditSummary: Codable {
    let score: Int
    let passed: Int
    let failed: Int
    let warnings: Int
    let total: Int
    
    init(score: Int = 0, passed: Int = 0, failed: Int = 0, warnings: Int = 0, total: Int = 0) {
        self.score = score
        self.passed = passed
        self.failed = failed
        self.warnings = warnings
        self.total = total
    }
}

struct AuditCategory: Identifiable {
    let id: UUID
    let name: String
    let checks: [AuditCheck]
    
    init(id: UUID = UUID(), name: String, checks: [AuditCheck]) {
        self.id = id
        self.name = name
        self.checks = checks
    }
}

