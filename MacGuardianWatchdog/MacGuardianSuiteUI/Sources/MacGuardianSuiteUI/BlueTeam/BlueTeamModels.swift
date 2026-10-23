import Foundation

// MARK: - Blue Team Models

struct ThreatEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let source: String
    let severity: String
    let description: String
    let category: String?
    let details: [String: String]?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), source: String, severity: String, description: String, category: String? = nil, details: [String: String]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.severity = severity
        self.description = description
        self.category = category
        self.details = details
    }
}

struct SystemStats: Codable {
    var cpu: Double
    var memory: Double
    var disk: Double
    var networkOut: Double
    var networkIn: Double
    var processCount: Int?
    var connectionCount: Int?
    
    init(cpu: Double = 0, memory: Double = 0, disk: Double = 0, networkOut: Double = 0, networkIn: Double = 0, processCount: Int? = nil, connectionCount: Int? = nil) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.networkOut = networkOut
        self.networkIn = networkIn
        self.processCount = processCount
        self.connectionCount = connectionCount
    }
}

struct NetworkConnection: Identifiable, Codable {
    let id: UUID
    let localAddress: String
    let remoteAddress: String
    let port: Int
    let protocolType: String
    let process: String?
    let status: String
    
    init(id: UUID = UUID(), localAddress: String, remoteAddress: String, port: Int, protocolType: String, process: String? = nil, status: String = "ESTABLISHED") {
        self.id = id
        self.localAddress = localAddress
        self.remoteAddress = remoteAddress
        self.port = port
        self.protocolType = protocolType
        self.process = process
        self.status = status
    }
}

struct BlueTeamProcessInfo: Identifiable, Codable {
    let id: UUID
    let pid: Int
    let name: String
    let cpu: Double
    let memory: Double
    let command: String
    let user: String
    
    init(id: UUID = UUID(), pid: Int, name: String, cpu: Double, memory: Double, command: String, user: String) {
        self.id = id
        self.pid = pid
        self.name = name
        self.cpu = cpu
        self.memory = memory
        self.command = command
        self.user = user
    }
}

