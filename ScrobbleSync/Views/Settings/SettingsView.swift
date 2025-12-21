import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showDisableSyncAlert = false
    
    var body: some View {
        List {
            // Connected Accounts Section
            Section {
                // Apple Music
                accountRow(
                    title: "Apple Music",
                    subtitle: appState.appleMusicConnected ? "Connected" : "Not connected",
                    systemImage: "music.note",
                    iconColor: Theme.Colors.appleMusicPink,
                    isConnected: appState.appleMusicConnected
                ) {
                    Task {
                        if appState.appleMusicConnected {
                            appState.disconnectAppleMusic()
                        } else {
                            await appState.connectAppleMusic()
                        }
                    }
                }
                
                // Last.fm
                accountRow(
                    title: "Last.fm",
                    subtitle: appState.lastfmConnected ? "@\(appState.lastfmUsername)" : "Not connected",
                    systemImage: "antenna.radiowaves.left.and.right",
                    iconColor: Theme.Colors.lastfmRed,
                    isConnected: appState.lastfmConnected
                ) {
                    Task {
                        if appState.lastfmConnected {
                            appState.disconnectLastfm()
                        } else {
                            await appState.connectLastfm()
                        }
                    }
                }
            } header: {
                Text("Connected Accounts")
            } footer: {
                Text("Tap an account to connect or disconnect.")
            }
            
            // Sync Preferences Section
            Section {
                Button {
                    if appState.backgroundSyncEnabled {
                        showDisableSyncAlert = true
                    } else {
                        appState.backgroundSyncEnabled = true
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Theme.Colors.accentGreen)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        Text("Background Sync")
                            .foregroundStyle(Theme.Colors.primaryText)
                        
                        Spacer()
                        
                        Text(appState.backgroundSyncEnabled ? "Enabled" : "Disabled")
                            .font(.subheadline)
                            .foregroundStyle(appState.backgroundSyncEnabled ? Theme.Colors.accentGreen : Theme.Colors.secondaryText)
                    }
                }
            } header: {
                Text("Sync Preferences")
            } footer: {
                Text("When enabled, ScrobbleSync will automatically sync your listening history when iOS allows background activity.")
            }
            
            // About Section
            Section {
                // Version
                HStack {
                    Label {
                        Text("Version")
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text("1.0.0 (1)")
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                
                // GitHub
                Button {
                    if let url = URL(string: "https://github.com/mattbolanos/ScrobbleSync") {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Label {
                            Text("View on GitHub")
                                .foregroundStyle(Theme.Colors.primaryText)
                        } icon: {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundStyle(Theme.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.tertiaryText)
                    }
                }
                
                // Made by
                HStack {
                    Label {
                        Text("Made by")
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Theme.Colors.appleMusicPink)
                    }
                    
                    Spacer()
                    
                    Text("Matt Bolaños")
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            } header: {
                Text("About")
            }
            

        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Disable Background Sync?", isPresented: $showDisableSyncAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                appState.backgroundSyncEnabled = false
            }
        } message: {
            Text("Automatic scrobbling requires background sync. Your listening history won't be sent to Last.fm until you open the app.")
        }
    }
    
    // MARK: - Account Row
    
    private func accountRow(
        title: String,
        subtitle: String,
        systemImage: String,
        iconColor: Color,
        isConnected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(Theme.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                if isConnected {
                    Text("Disconnect")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.error)
                } else {
                    Text("Connect")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.accentGreen)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView(appState: makePreviewState())
    }
}

// MARK: - Preview Helpers
private func makePreviewState() -> AppState {
    let state = AppState()
    // Configure preview-only derived state without mutating read-only properties
    // If AppState exposes connect methods, prefer those; otherwise, rely on defaults.
    // For safety, we won't directly assign to get-only properties here.
    return state
}
