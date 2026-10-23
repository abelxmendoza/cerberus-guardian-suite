import SwiftUI
import Foundation

/// Formats and styles command output for better readability
struct OutputFormatter {
    static func addTimestamp(_ text: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        return "[\(timestamp)] \(text)"
    }
    
    static func detectInteractivePrompt(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let prompts = ["select", "choose", "press", "enter", "input", "y/n", "yes/no", "continue"]
        return prompts.contains { lowercased.contains($0) }
    }
}

