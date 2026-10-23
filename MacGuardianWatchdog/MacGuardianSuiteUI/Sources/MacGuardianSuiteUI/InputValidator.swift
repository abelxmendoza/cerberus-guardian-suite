import Foundation

/// Validates and sanitizes user inputs to prevent injection attacks
class InputValidator {
    static let shared = InputValidator()
    
    private init() {}
    
    /// Validate email address
    func validateEmail(_ email: String) -> (isValid: Bool, message: String) {
        if email.isEmpty {
            return (false, "Email cannot be empty")
        }
        
        // Basic email regex
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if predicate.evaluate(with: email) {
            return (true, "Valid email")
        } else {
            return (false, "Invalid email format")
        }
    }
    
    /// Sanitize file path to prevent directory traversal
    func sanitizePath(_ path: String) -> String {
        // Remove any path traversal attempts
        var sanitized = path
            .replacingOccurrences(of: "../", with: "")
            .replacingOccurrences(of: "..\\", with: "")
            .replacingOccurrences(of: "~/", with: "")
        
        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        
        // Remove leading/trailing whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return sanitized
    }
    
    /// Validate script path
    func validateScriptPath(_ path: String, repositoryPath: String) -> (isValid: Bool, message: String) {
        let sanitized = sanitizePath(path)
        
        // Check if path is within repository
        let repoURL = URL(fileURLWithPath: repositoryPath)
        let scriptURL = URL(fileURLWithPath: sanitized)
        
        guard scriptURL.path.hasPrefix(repoURL.path) else {
            auditLog(action: "path_validation_failed", path: sanitized, reason: "Path outside repository")
            return (false, "Script path must be within repository directory")
        }
        
        // Check file extension
        let allowedExtensions = [".sh", ".py", ".bash"]
        let hasValidExtension = allowedExtensions.contains { scriptURL.pathExtension == $0.replacingOccurrences(of: ".", with: "") }
        
        if !hasValidExtension && !scriptURL.pathExtension.isEmpty {
            return (false, "Invalid script extension. Allowed: .sh, .py, .bash")
        }
        
        // Check if file exists
        if !FileManager.default.fileExists(atPath: sanitized) {
            return (false, "Script file does not exist")
        }
        
        return (true, "Valid script path")
    }
    
    /// Sanitize command arguments to prevent injection
    func sanitizeArguments(_ args: [String]) -> [String] {
        return args.map { arg in
            // Remove dangerous characters
            var sanitized = arg
                .replacingOccurrences(of: ";", with: "")
                .replacingOccurrences(of: "&", with: "")
                .replacingOccurrences(of: "|", with: "")
                .replacingOccurrences(of: "`", with: "")
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
            
            // Remove null bytes
            sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
            
            return sanitized
        }
    }
    
    /// Validate SMTP settings
    func validateSMTPSettings(username: String, password: String, email: String) -> (isValid: Bool, message: String) {
        let emailValidation = validateEmail(email)
        if !emailValidation.isValid {
            return emailValidation
        }
        
        if username.isEmpty {
            return (false, "SMTP username cannot be empty")
        }
        
        if password.isEmpty {
            return (false, "SMTP password cannot be empty")
        }
        
        // Validate username is email-like
        let usernameValidation = validateEmail(username)
        if !usernameValidation.isValid && !username.contains("@") {
            return (false, "SMTP username should be an email address")
        }
        
        return (true, "SMTP settings valid")
    }
    
    /// Audit logging
    private func auditLog(action: String, path: String, reason: String) {
        let logEntry = """
        [\(Date().ISO8601Format())] VALIDATION: \(action) - Path: \(path) - Reason: \(reason)
        """
        
        if let logDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("MacGuardianSuite/audit") {
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
            let logFile = logDir.appendingPathComponent("validation_audit.log")
            
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

