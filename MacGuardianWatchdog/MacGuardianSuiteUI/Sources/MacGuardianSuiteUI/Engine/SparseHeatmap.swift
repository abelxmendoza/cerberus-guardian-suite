import Foundation
import Combine
import SwiftUI

/// Sparse matrix implementation for privacy heatmap
/// Only stores non-zero cells, dramatically reducing memory and computation
final class SparseHeatmap: ObservableObject {
    private var matrix: [String: Int] = [:]  // Dictionary<(row, col), Int>
    private let queue = DispatchQueue(label: "com.macguardian.sparseheatmap", attributes: .concurrent)
    
    @Published var didUpdate = false
    
    /// Update intensity for a specific cell (O(1))
    func update(row: String, col: String, intensity: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let key = "\(row):\(col)"
            
            if intensity > 0 {
                self.matrix[key] = intensity
            } else {
                // Remove zero values to keep sparse
                self.matrix.removeValue(forKey: key)
            }
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Increment intensity for a cell (O(1))
    func increment(row: String, col: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let key = "\(row):\(col)"
            self.matrix[key, default: 0] += 1
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Get intensity for a cell (O(1))
    func intensity(row: String, col: String) -> Int {
        return queue.sync {
            let key = "\(row):\(col)"
            return matrix[key] ?? 0
        }
    }
    
    /// Get all non-zero cells (O(n) where n = non-zero cells)
    func allCells() -> [(row: String, col: String, intensity: Int)] {
        return queue.sync {
            return matrix.map { key, intensity in
                let parts = key.split(separator: ":")
                let row = String(parts[0])
                let col = parts.count > 1 ? String(parts[1]) : ""
                return (row: row, col: col, intensity: intensity)
            }
        }
    }
    
    /// Get cells for a specific row (O(n) where n = non-zero cells in row)
    func cells(forRow row: String) -> [(col: String, intensity: Int)] {
        return queue.sync {
            return matrix.compactMap { key, intensity in
                let parts = key.split(separator: ":")
                if parts[0] == row {
                    let col = parts.count > 1 ? String(parts[1]) : ""
                    return (col: col, intensity: intensity)
                }
                return nil
            }
        }
    }
    
    /// Get cells for a specific column (O(n) where n = non-zero cells in column)
    func cells(forCol col: String) -> [(row: String, intensity: Int)] {
        return queue.sync {
            return matrix.compactMap { key, intensity in
                let parts = key.split(separator: ":")
                if parts.count > 1 && String(parts[1]) == col {
                    let row = String(parts[0])
                    return (row: row, intensity: intensity)
                }
                return nil
            }
        }
    }
    
    /// Clear all cells (O(1))
    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.matrix.removeAll()
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Get total count of non-zero cells
    var count: Int {
        return queue.sync { matrix.count }
    }
    
    /// Check if empty
    var isEmpty: Bool {
        return queue.sync { matrix.isEmpty }
    }
}

/// Privacy heatmap specific implementation
final class PrivacyHeatmapModel: ObservableObject {
    private let sparseMatrix: SparseHeatmap
    
    // Permission types (rows)
    enum PermissionType: String, CaseIterable {
        case fullDiskAccess = "Full Disk Access"
        case screenRecording = "Screen Recording"
        case microphone = "Microphone"
        case camera = "Camera"
        case inputMonitoring = "Input Monitoring"
        case accessibility = "Accessibility"
    }
    
    // App names (columns) - dynamically populated
    @Published var appNames: Set<String> = []
    
    init() {
        self.sparseMatrix = SparseHeatmap()
    }
    
    /// Update permission count for an app (O(1))
    func updatePermission(permission: PermissionType, appName: String, count: Int) {
        sparseMatrix.update(row: permission.rawValue, col: appName, intensity: count)
        
        if count > 0 {
            appNames.insert(appName)
        } else if count == 0 {
            // Check if app has any other permissions
            let hasOtherPermissions = PermissionType.allCases.contains { otherPerm in
                sparseMatrix.intensity(row: otherPerm.rawValue, col: appName) > 0
            }
            if !hasOtherPermissions {
                appNames.remove(appName)
            }
        }
    }
    
    /// Increment permission count (O(1))
    func incrementPermission(permission: PermissionType, appName: String) {
        sparseMatrix.increment(row: permission.rawValue, col: appName)
        appNames.insert(appName)
    }
    
    /// Get count for a specific permission and app (O(1))
    func count(permission: PermissionType, appName: String) -> Int {
        return sparseMatrix.intensity(row: permission.rawValue, col: appName)
    }
    
    /// Get total count for a permission across all apps (O(n) where n = apps)
    func totalCount(for permission: PermissionType) -> Int {
        return appNames.reduce(0) { total, appName in
            total + count(permission: permission, appName: appName)
        }
    }
    
    /// Get all permissions for an app (O(k) where k = permission types)
    func permissions(for appName: String) -> [PermissionType: Int] {
        var result: [PermissionType: Int] = [:]
        for permission in PermissionType.allCases {
            let count = count(permission: permission, appName: appName)
            if count > 0 {
                result[permission] = count
            }
        }
        return result
    }
    
    /// Get heatmap color for intensity (purple-based gradient)
    func heatmapColor(intensity: Int, isHighRisk: Bool) -> Color {
        if intensity == 0 {
            return .themePurple.opacity(0.3)
        } else if intensity == 1 {
            return .themePurple
        } else if intensity <= 3 {
            return .themePurpleLight
        } else {
            return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple
        }
    }
    
    /// Clear all data
    func clear() {
        sparseMatrix.clear()
        appNames.removeAll()
    }
}

