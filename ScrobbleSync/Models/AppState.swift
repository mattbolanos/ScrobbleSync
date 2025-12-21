import SwiftUI

// MARK: - App State

@Observable
final class AppState {
    // MARK: - Services
    
    let musicKitService = MusicKitService()
    
    // MARK: - Onboarding State
    
    var isOnboarded: Bool = false
    var lastfmConnected: Bool = false
    var lastfmUsername: String = ""
    
    // MARK: - Apple Music State
    
    var appleMusicConnected: Bool {
        musicKitService.isAuthorized
    }
    
    var isConnectingAppleMusic: Bool {
        musicKitService.isAuthorizing
    }
    
    var appleMusicStatusDescription: String {
        musicKitService.statusDescription
    }
    
    // MARK: - Sync State
    
    var isSyncing: Bool = false
    var lastSyncDate: Date? = nil
    var backgroundSyncEnabled: Bool = true
    
    // MARK: - Scrobbles
    
    var scrobbles: [Scrobble] = []
    
    // MARK: - Computed Properties
    
    var canGetStarted: Bool {
        appleMusicConnected && lastfmConnected
    }
    
    var todayScrobbleCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return scrobbles.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
    }
    
    var weekScrobbleCount: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return scrobbles.filter { $0.timestamp >= weekAgo }.count
    }
    
    var pendingCount: Int {
        scrobbles.filter { $0.status.isPending }.count
    }
    
    var failedCount: Int {
        scrobbles.filter { $0.status.isFailed }.count
    }
    
    var recentScrobbles: [Scrobble] {
        Array(scrobbles.prefix(15))
    }
    
    var lastSyncDescription: String {
        guard let lastSync = lastSyncDate else {
            return "Never synced"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
    }
    
    // MARK: - Actions
    
    @MainActor
    func connectAppleMusic() async {
        await musicKitService.requestAuthorization()
    }
    
    /// Note: Apple Music authorization cannot be revoked programmatically.
    /// User must disable in Settings > Privacy > Media & Apple Music
    func disconnectAppleMusic() {
        // Cannot programmatically revoke - just refresh status
        musicKitService.refreshStatus()
    }
    
    func connectLastfm(username: String = "mattbolanos") {
        withAnimation(Theme.Animation.spring) {
            lastfmConnected = true
            lastfmUsername = username
        }
    }
    
    func disconnectLastfm() {
        withAnimation(Theme.Animation.spring) {
            lastfmConnected = false
            lastfmUsername = ""
        }
    }
    
    func completeOnboarding() {
        withAnimation(Theme.Animation.spring) {
            isOnboarded = true
            scrobbles = MockData.scrobbles
            lastSyncDate = Date()
        }
    }
    
    func resetOnboarding() {
        withAnimation(Theme.Animation.spring) {
            isOnboarded = false
            // Note: Apple Music authorization persists and cannot be revoked programmatically
            musicKitService.refreshStatus()
            lastfmConnected = false
            lastfmUsername = ""
            scrobbles = []
            lastSyncDate = nil
        }
    }
    
    func syncNow() {
        guard !isSyncing else { return }
        
        withAnimation(Theme.Animation.quick) {
            isSyncing = true
        }
        
        // Simulate sync delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(Theme.Animation.quick) {
                self.isSyncing = false
                self.lastSyncDate = Date()
                
                // Randomly resolve some pending/failed scrobbles for demo
                for index in self.scrobbles.indices {
                    if self.scrobbles[index].status.isPending {
                        self.scrobbles[index].status = Bool.random() ? .success : .failed("Network timeout")
                    }
                }
            }
        }
    }
    
    func retryScrobble(_ scrobble: Scrobble) {
        guard let index = scrobbles.firstIndex(where: { $0.id == scrobble.id }) else { return }
        
        withAnimation(Theme.Animation.quick) {
            scrobbles[index].status = .pending
        }
        
        // Simulate retry
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(Theme.Animation.quick) {
                self.scrobbles[index].status = Bool.random() ? .success : .failed("Server error: Rate limited")
            }
        }
    }
}

