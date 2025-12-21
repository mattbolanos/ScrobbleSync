import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @Bindable var appState: AppState
    @State private var selectedTab: Tab = .home
    
    enum Tab: Hashable {
        case home
        case history
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(appState: appState)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            HistoryView(appState: appState)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)
            
            NavigationStack {
                SettingsView(appState: appState)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .tint(Theme.Colors.accentGreen)
    }
}

// MARK: - Preview

#Preview {
    MainTabView(appState: {
        let appState = AppState()
        appState.isOnboarded = true
        appState.scrobbles = PreviewData.scrobbles
        appState.lastSyncDate = Date().addingTimeInterval(-300)
        return appState
    }())
}

