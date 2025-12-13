import SwiftUI

// MARK: - History View

struct HistoryView: View {
    @Bindable var appState: AppState
    @State private var selectedFilter: ScrobbleFilter = .all
    @State private var selectedScrobble: Scrobble?
    @State private var isRefreshing = false
    
    private var filteredScrobbles: [Scrobble] {
        appState.scrobbles.filter { selectedFilter.matches($0) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ScrobbleFilter.allCases, id: \.self) { filter in
                        Text(filterLabel(for: filter))
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                
                // Scrobbles list
                if filteredScrobbles.isEmpty {
                    emptyStateView
                } else {
                    scrobblesList
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("History")
            .sheet(item: $selectedScrobble) { scrobble in
                ScrobbleDetailSheet(scrobble: scrobble) {
                    appState.retryScrobble(scrobble)
                }
            }
        }
    }
    
    // MARK: - Filter Label
    
    private func filterLabel(for filter: ScrobbleFilter) -> String {
        switch filter {
        case .all:
            return "All (\(appState.scrobbles.count))"
        case .pending:
            let count = appState.pendingCount
            return "Pending\(count > 0 ? " (\(count))" : "")"
        case .failed:
            let count = appState.failedCount
            return "Failed\(count > 0 ? " (\(count))" : "")"
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            switch selectedFilter {
            case .all:
                EmptyStateView(
                    systemImage: "music.note.list",
                    title: "No Scrobbles",
                    description: "Start listening to music and your scrobbles will appear here."
                )
                
            case .pending:
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: "All Caught Up",
                    description: "You have no pending scrobbles. Everything has been synced."
                )
                
            case .failed:
                EmptyStateView(
                    systemImage: "checkmark.shield",
                    title: "No Failures",
                    description: "All your scrobbles have been successfully synced to Last.fm."
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Scrobbles List
    
    @ViewBuilder
    private var scrobblesList: some View {
        List {
            ForEach(filteredScrobbles) { scrobble in
                ScrobbleRow(
                    scrobble: scrobble,
                    showFullTimestamp: true,
                    onTap: scrobble.status.isFailed ? {
                        selectedScrobble = scrobble
                    } : nil
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(
                    top: Theme.Spacing.xs,
                    leading: Theme.Spacing.lg,
                    bottom: Theme.Spacing.xs,
                    trailing: Theme.Spacing.lg
                ))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            isRefreshing = true
            appState.syncNow()
            
            // Wait for sync to complete
            try? await Task.sleep(for: .seconds(1.5))
            isRefreshing = false
        }
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    appState.scrobbles = MockData.scrobbles
    
    return HistoryView(appState: appState)
}

