import Foundation
import Security

/// Secure storage using macOS Keychain for sensitive data
class SecureStorage {
    static let shared = SecureStorage()
    
    private let service = "com.macguardian.suite"
    private let accessGroup: String? = nil // Use nil for app-specific keychain
    
    private init() {}
    
    /// Store a password securely in Keychain
    func storePassword(_ password: String, forKey key: String) -> Bool {
        // Delete existing item first
        _ = deletePassword(forKey: key)
        
        guard let passwordData = password.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            auditLog(action: "password_stored", key: key, success: true)
            return true
        } else {
            auditLog(action: "password_stored", key: key, success: false, error: "Keychain error: \(status)")
            return false
        }
    }
    
    /// Retrieve a password from Keychain
    func getPassword(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let password = String(data: data, encoding: .utf8) {
            auditLog(action: "password_retrieved", key: key, success: true)
            return password
        } else {
            auditLog(action: "password_retrieved", key: key, success: false, error: "Keychain error: \(status)")
            return nil
        }
    }
    
    /// Delete a password from Keychain
    func deletePassword(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        auditLog(action: "password_deleted", key: key, success: status == errSecSuccess)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Check if a password exists in Keychain
    func hasPassword(forKey key: String) -> Bool {
        return getPassword(forKey: key) != nil
    }
    
    /// Audit logging helper
    private func auditLog(action: String, key: String, success: Bool, error: String? = nil) {
        let logEntry = """
        [\(Date().ISO8601Format())] SECURITY: \(action) - Key: \(key) - Success: \(success)\(error != nil ? " - Error: \(error!)" : "")
        """
        
        // Write to secure audit log
        if let logDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("MacGuardianSuite/audit") {
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
            let logFile = logDir.appendingPathComponent("security_audit.log")
            
            if let data = logEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFile.path) {
                    if let fileHandle = FileHandle(forWritingAtPath: logFile.path) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: logFile)
                }
            }
        }
    }
}

