import SwiftUI

/// Central theme configuration
struct MacGuardianTheme {
    static let name = "Omega Technologies Dark"
    static let version = "1.0"
}

/// Theme environment values
struct ThemeKey: EnvironmentKey {
    static let defaultValue = MacGuardianTheme()
}

extension EnvironmentValues {
    var theme: MacGuardianTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

