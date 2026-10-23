import Foundation
import IOKit.pwr_mgt
import Combine

/// macOS Power-Aware Service
/// Detects battery level and Low Power Mode to reduce background load
@MainActor
class PowerAwareService: ObservableObject {
    static let shared = PowerAwareService()
    
    @Published var isLowPowerMode: Bool = false
    @Published var isOnBattery: Bool = false
    @Published var batteryLevel: Int = 100
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkPowerStatus()
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Check power status every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkPowerStatus()
            }
            .store(in: &cancellables)
    }
    
    private func checkPowerStatus() {
        // Check Low Power Mode (macOS 12+)
        if #available(macOS 12.0, *) {
            isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        
        // Check battery status
        checkBatteryStatus()
    }
    
    private func checkBatteryStatus() {
        // Use IOKit to check power source
        let powerSource = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSourcesList = IOPSCopyPowerSourcesList(powerSource).takeRetainedValue() as? [CFTypeRef]
        
        guard let sources = powerSourcesList, !sources.isEmpty else {
            isOnBattery = false
            batteryLevel = 100
            return
        }
        
        if let source = sources.first,
           let sourceInfo = IOPSGetPowerSourceDescription(powerSource, source).takeUnretainedValue() as? [String: Any] {
            
            // Check power source type
            if let powerSourceState = sourceInfo[kIOPSPowerSourceStateKey] as? String {
                isOnBattery = (powerSourceState == kIOPSBatteryPowerValue)
            }
            
            // Get battery level
            if let currentCapacity = sourceInfo[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = sourceInfo[kIOPSMaxCapacityKey] as? Int,
               maxCapacity > 0 {
                batteryLevel = Int((Double(currentCapacity) / Double(maxCapacity)) * 100)
            }
        }
    }
    
    /// Get recommended polling interval based on power state
    var recommendedInterval: TimeInterval {
        if isLowPowerMode {
            return 30.0  // Very conservative
        } else if isOnBattery && batteryLevel < 20 {
            return 20.0  // Conservative
        } else if isOnBattery {
            return 10.0  // Moderate
        } else {
            return 5.0   // Normal (plugged in)
        }
    }
    
    /// Check if background processing should be reduced
    var shouldReduceProcessing: Bool {
        return isLowPowerMode || (isOnBattery && batteryLevel < 20)
    }
}

