import SwiftUI

// Environment key for tab bar visibility
struct TabBarVisibilityKey: EnvironmentKey {
    static var defaultValue: Bool = true
}

// Extend environment values to include our key
extension EnvironmentValues {
    var showTabBar: Bool {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
    }
}

// Convenience modifier for setting tab bar visibility
extension View {
    func showTabBar(_ show: Bool) -> some View {
        environment(\.showTabBar, show)
    }
}
