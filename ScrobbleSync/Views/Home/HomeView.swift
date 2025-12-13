import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Status card
                    StatusCard(
                        isSyncing: appState.isSyncing,
                        lastSyncDescription: appState.lastSyncDescription,
                        backgroundSyncEnabled: appState.backgroundSyncEnabled
                    )
                    
                    // Stats row
                    StatsRow(
                        todayCount: appState.todayScrobbleCount,
                        weekCount: appState.weekScrobbleCount
                    )
                    
                    // Sync Now button
                    Button {
                        appState.syncNow()
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            if appState.isSyncing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(appState.isSyncing ? "Syncing..." : "Sync Now")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous)
                                .fill(appState.isSyncing ? Theme.Colors.accentGreen.opacity(0.7) : Theme.Colors.accentGreen)
                        )
                    }
                    .disabled(appState.isSyncing)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: appState.isSyncing)
                    
                    // Recent scrobbles section
                    recentScrobblesSection
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("ScrobbleSync")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView(appState: appState)) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Scrobbles Section
    
    @ViewBuilder
    private var recentScrobblesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("Recent Scrobbles")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Spacer()
                
                if appState.pendingCount > 0 || appState.failedCount > 0 {
                    HStack(spacing: Theme.Spacing.sm) {
                        if appState.pendingCount > 0 {
                            statusBadge(count: appState.pendingCount, color: Theme.Colors.pending, icon: "clock.fill")
                        }
                        if appState.failedCount > 0 {
                            statusBadge(count: appState.failedCount, color: Theme.Colors.error, icon: "xmark.circle.fill")
                        }
                    }
                }
            }
            
            // Scrobbles list
            if appState.recentScrobbles.isEmpty {
                EmptyStateView(
                    systemImage: "music.note.list",
                    title: "No Scrobbles Yet",
                    description: "Start listening to music and your scrobbles will appear here."
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xxl)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(appState.recentScrobbles) { scrobble in
                        ScrobbleRow(scrobble: scrobble)
                        
                        if scrobble.id != appState.recentScrobbles.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
            }
        }
    }
    
    private func statusBadge(count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    appState.isOnboarded = true
    appState.appleMusicConnected = true
    appState.lastfmConnected = true
    appState.lastfmUsername = "mattbolanos"
    appState.scrobbles = MockData.scrobbles
    appState.lastSyncDate = Date().addingTimeInterval(-300)
    
    return HomeView(appState: appState)
}

