import SwiftUI

@main
struct ScrobbleSyncApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isOnboarded {
                    MainTabView(appState: appState)
                } else {
                    OnboardingView(appState: appState)
                }
            }
            .animation(Theme.Animation.spring, value: appState.isOnboarded)
            .preferredColorScheme(.none)
        }
    }
}
