import SwiftUI
import Yams

struct ConfigEditorView: View {
    @StateObject private var configLoader = ConfigLoader.shared
    @State private var config: MacGuardianConfig?
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                        .foregroundColor(.themePurple)
                    VStack(alignment: .leading) {
                        Text("Configuration")
                            .font(.title.bold())
                        Text("Edit MacGuardian settings")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Button {
                        saveConfig()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.themePurple)
                    .disabled(isSaving || config == nil)
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    ProgressView("Loading configuration...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if var config = config {
                    // Monitoring Settings
                    ConfigSection(title: "Real-Time Monitoring") {
                        Toggle("Enable Process Monitor", isOn: Binding(
                            get: { config.monitoring.enableProcessMonitor },
                            set: { self.config?.monitoring.enableProcessMonitor = $0 }
                        ))
                        
                        Toggle("Enable Network Monitor", isOn: Binding(
                            get: { config.monitoring.enableNetworkMonitor },
                            set: { self.config?.monitoring.enableNetworkMonitor = $0 }
                        ))
                        
                        Toggle("Enable FSEvents", isOn: Binding(
                            get: { config.monitoring.enableFSEvents },
                            set: { self.config?.monitoring.enableFSEvents = $0 }
                        ))
                        
                        Toggle("Enable IDS", isOn: Binding(
                            get: { config.monitoring.enableIDS },
                            set: { self.config?.monitoring.enableIDS = $0 }
                        ))
                        
                        HStack {
                            Text("Check Interval (seconds)")
                            Spacer()
                            TextField("", value: Binding(
                                get: { config.monitoring.interval },
                                set: { self.config?.monitoring.interval = $0 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                    }
                    
                    // Privacy Settings
                    ConfigSection(title: "Privacy Monitoring") {
                        Toggle("Alert on New Permissions", isOn: Binding(
                            get: { config.privacy.alertOnNewPermissions },
                            set: { self.config?.privacy.alertOnNewPermissions = $0 }
                        ))
                        
                        Toggle("Monitor TCC Changes", isOn: Binding(
                            get: { config.privacy.monitorTCCChanges },
                            set: { self.config?.privacy.monitorTCCChanges = $0 }
                        ))
                        
                        Toggle("Alert on Full Disk Access", isOn: Binding(
                            get: { config.privacy.alertOnFullDiskAccess },
                            set: { self.config?.privacy.alertOnFullDiskAccess = $0 }
                        ))
                        
                        Toggle("Alert on Screen Recording", isOn: Binding(
                            get: { config.privacy.alertOnScreenRecording },
                            set: { self.config?.privacy.alertOnScreenRecording = $0 }
                        ))
                    }
                    
                    // SSH Settings
                    ConfigSection(title: "SSH Monitoring") {
                        Toggle("Alert on Key Change", isOn: Binding(
                            get: { config.ssh.alertOnKeyChange },
                            set: { self.config?.ssh.alertOnKeyChange = $0 }
                        ))
                        
                        Toggle("Alert on Config Change", isOn: Binding(
                            get: { config.ssh.alertOnConfigChange },
                            set: { self.config?.ssh.alertOnConfigChange = $0 }
                        ))
                        
                        Toggle("Monitor Authorized Keys", isOn: Binding(
                            get: { config.ssh.monitorAuthorizedKeys },
                            set: { self.config?.ssh.monitorAuthorizedKeys = $0 }
                        ))
                    }
                    
                    // IDS Settings
                    ConfigSection(title: "Intrusion Detection") {
                        Toggle("Enable Correlation", isOn: Binding(
                            get: { config.ids.enableCorrelation },
                            set: { self.config?.ids.enableCorrelation = $0 }
                        ))
                        
                        HStack {
                            Text("Correlation Window (seconds)")
                            Spacer()
                            TextField("", value: Binding(
                                get: { config.ids.correlationWindow },
                                set: { self.config?.ids.correlationWindow = $0 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                        
                        HStack {
                            Text("File Change Threshold")
                            Spacer()
                            TextField("", value: Binding(
                                get: { config.ids.fileChangeThreshold },
                                set: { self.config?.ids.fileChangeThreshold = $0 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                    }
                    
                    // Alert Settings
                    ConfigSection(title: "Alerting") {
                        Toggle("Enable Email Alerts", isOn: Binding(
                            get: { config.alerts.enableEmail },
                            set: { self.config?.alerts.enableEmail = $0 }
                        ))
                        
                        Toggle("Enable Webhook", isOn: Binding(
                            get: { config.alerts.enableWebhook },
                            set: { self.config?.alerts.enableWebhook = $0 }
                        ))
                        
                        HStack {
                            Text("Webhook URL")
                            Spacer()
                            TextField("", text: Binding(
                                get: { config.alerts.webhookURL },
                                set: { self.config?.alerts.webhookURL = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                        }
                        
                        Toggle("Critical Alerts", isOn: Binding(
                            get: { config.alerts.criticalAlerts },
                            set: { self.config?.alerts.criticalAlerts = $0 }
                        ))
                        
                        Toggle("High Alerts", isOn: Binding(
                            get: { config.alerts.highAlerts },
                            set: { self.config?.alerts.highAlerts = $0 }
                        ))
                    }
                } else {
                    EmptyStateView(
                        icon: "gearshape",
                        title: "No configuration",
                        message: "Configuration file not found"
                    )
                }
            }
        }
        .background(Color.themeBlack)
        .alert("Configuration Saved", isPresented: $showSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveMessage)
        }
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            // Use high-performance config loader with caching
            let loadedConfig = configLoader.load()
            DispatchQueue.main.async {
                self.config = loadedConfig
                self.isLoading = false
            }
        }
    }
    
    private func saveConfig() {
        guard let config = config else { return }
        
        isSaving = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Update config loader cache
                configLoader.update(config)
                
                // Save to disk (only writes if dirty)
                try configLoader.save()
                
                DispatchQueue.main.async {
                    self.saveMessage = "Configuration saved successfully. Restart daemon to apply changes."
                    self.showSaveAlert = true
                    self.isSaving = false
                }
            } catch {
                print("⚠️ Failed to save config: \(error)")
                DispatchQueue.main.async {
                    self.saveMessage = "Failed to save configuration: \(error.localizedDescription)"
                    self.showSaveAlert = true
                    self.isSaving = false
                }
            }
        }
    }
}

struct ConfigSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(12)
    }
}

struct MacGuardianConfig {
    var monitoring: MonitoringConfig
    var privacy: PrivacyConfig
    var ssh: SSHConfig
    var ids: IDSConfig
    var alerts: AlertConfig
    
    static func fromDict(_ dict: [String: Any]) -> MacGuardianConfig {
        let monitoringDict = dict["monitoring"] as? [String: Any] ?? [:]
        let privacyDict = dict["privacy"] as? [String: Any] ?? [:]
        let sshDict = dict["ssh"] as? [String: Any] ?? [:]
        let idsDict = dict["ids"] as? [String: Any] ?? [:]
        let alertsDict = dict["alerts"] as? [String: Any] ?? [:]
        
        return MacGuardianConfig(
            monitoring: MonitoringConfig.fromDict(monitoringDict),
            privacy: PrivacyConfig.fromDict(privacyDict),
            ssh: SSHConfig.fromDict(sshDict),
            ids: IDSConfig.fromDict(idsDict),
            alerts: AlertConfig.fromDict(alertsDict)
        )
    }
    
    func toDict() -> [String: Any] {
        return [
            "monitoring": monitoring.toDict(),
            "privacy": privacy.toDict(),
            "ssh": ssh.toDict(),
            "ids": ids.toDict(),
            "alerts": alerts.toDict()
        ]
    }
    
    static var `default`: MacGuardianConfig {
        MacGuardianConfig(
            monitoring: MonitoringConfig(
                interval: 2,
                enableProcessMonitor: true,
                enableNetworkMonitor: true,
                enableFSEvents: true,
                enableIDS: true
            ),
            privacy: PrivacyConfig(
                alertOnNewPermissions: true,
                monitorTCCChanges: true,
                alertOnFullDiskAccess: true,
                alertOnScreenRecording: true
            ),
            ssh: SSHConfig(
                alertOnKeyChange: true,
                alertOnConfigChange: true,
                monitorAuthorizedKeys: true
            ),
            ids: IDSConfig(
                enableCorrelation: true,
                correlationWindow: 60,
                fileChangeThreshold: 50
            ),
            alerts: AlertConfig(
                enableEmail: false,
                enableWebhook: false,
                webhookURL: "",
                criticalAlerts: true,
                highAlerts: true
            )
        )
    }
}

struct MonitoringConfig {
    var interval: Int
    var enableProcessMonitor: Bool
    var enableNetworkMonitor: Bool
    var enableFSEvents: Bool
    var enableIDS: Bool
    
    static func fromDict(_ dict: [String: Any]) -> MonitoringConfig {
        return MonitoringConfig(
            interval: dict["interval"] as? Int ?? 2,
            enableProcessMonitor: dict["enable_process_monitor"] as? Bool ?? true,
            enableNetworkMonitor: dict["enable_network_monitor"] as? Bool ?? true,
            enableFSEvents: dict["enable_fsevents"] as? Bool ?? true,
            enableIDS: dict["enable_ids"] as? Bool ?? true
        )
    }
    
    func toDict() -> [String: Any] {
        return [
            "interval": interval,
            "enable_process_monitor": enableProcessMonitor,
            "enable_network_monitor": enableNetworkMonitor,
            "enable_fsevents": enableFSEvents,
            "enable_ids": enableIDS
        ]
    }
}

struct PrivacyConfig {
    var alertOnNewPermissions: Bool
    var monitorTCCChanges: Bool
    var alertOnFullDiskAccess: Bool
    var alertOnScreenRecording: Bool
    
    static func fromDict(_ dict: [String: Any]) -> PrivacyConfig {
        return PrivacyConfig(
            alertOnNewPermissions: dict["alert_on_new_permissions"] as? Bool ?? true,
            monitorTCCChanges: dict["monitor_tcc_changes"] as? Bool ?? true,
            alertOnFullDiskAccess: dict["alert_on_full_disk_access"] as? Bool ?? true,
            alertOnScreenRecording: dict["alert_on_screen_recording"] as? Bool ?? true
        )
    }
    
    func toDict() -> [String: Any] {
        return [
            "alert_on_new_permissions": alertOnNewPermissions,
            "monitor_tcc_changes": monitorTCCChanges,
            "alert_on_full_disk_access": alertOnFullDiskAccess,
            "alert_on_screen_recording": alertOnScreenRecording
        ]
    }
}

struct SSHConfig {
    var alertOnKeyChange: Bool
    var alertOnConfigChange: Bool
    var monitorAuthorizedKeys: Bool
    
    static func fromDict(_ dict: [String: Any]) -> SSHConfig {
        return SSHConfig(
            alertOnKeyChange: dict["alert_on_key_change"] as? Bool ?? true,
            alertOnConfigChange: dict["alert_on_config_change"] as? Bool ?? true,
            monitorAuthorizedKeys: dict["monitor_authorized_keys"] as? Bool ?? true
        )
    }
    
    func toDict() -> [String: Any] {
        return [
            "alert_on_key_change": alertOnKeyChange,
            "alert_on_config_change": alertOnConfigChange,
            "monitor_authorized_keys": monitorAuthorizedKeys
        ]
    }
}

struct IDSConfig {
    var enableCorrelation: Bool
    var correlationWindow: Int
    var fileChangeThreshold: Int
    
    static func fromDict(_ dict: [String: Any]) -> IDSConfig {
        return IDSConfig(
            enableCorrelation: dict["enable_correlation"] as? Bool ?? true,
            correlationWindow: dict["correlation_window"] as? Int ?? 60,
            fileChangeThreshold: dict["file_change_threshold"] as? Int ?? 50
        )
    }
    
    func toDict() -> [String: Any] {
        return [
            "enable_correlation": enableCorrelation,
            "correlation_window": correlationWindow,
            "file_change_threshold": fileChangeThreshold
        ]
    }
}

struct AlertConfig {
    var enableEmail: Bool
    var enableWebhook: Bool
    var webhookURL: String
    var criticalAlerts: Bool
    var highAlerts: Bool
    
    static func fromDict(_ dict: [String: Any]) -> AlertConfig {
        return AlertConfig(
            enableEmail: dict["enable_email"] as? Bool ?? false,
            enableWebhook: dict["enable_webhook"] as? Bool ?? false,
            webhookURL: dict["webhook_url"] as? String ?? "",
            criticalAlerts: dict["critical_alerts"] as? Bool ?? true,
            highAlerts: dict["high_alerts"] as? Bool ?? true
        )
    }
    
    func toDict() -> [String: Any] {
        return [
            "enable_email": enableEmail,
            "enable_webhook": enableWebhook,
            "webhook_url": webhookURL,
            "critical_alerts": criticalAlerts,
            "high_alerts": highAlerts
        ]
    }
}

