import SwiftUI

// MARK: - App State

@Observable
final class AppState {
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let isOnboarded = "isOnboarded"
    }
    
    // MARK: - Services
    
    let musicKitService = MusicKitService()
    let lastFmService = LastFmService()
    
    // MARK: - Onboarding State
    
    var isOnboarded: Bool = UserDefaults.standard.bool(forKey: Keys.isOnboarded) {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: Keys.isOnboarded)
        }
    }
    
    // MARK: - Last.fm State (from service)
    
    var lastfmConnected: Bool {
        lastFmService.isAuthenticated
    }
    
    var lastfmUsername: String {
        lastFmService.username
    }
    
    var isConnectingLastfm: Bool {
        lastFmService.isAuthenticating
    }
    
    var lastfmStatusDescription: String {
        lastFmService.statusDescription
    }
    
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
    
    @MainActor
    func connectLastfm() async {
        do {
            try await lastFmService.authenticate()
        } catch LastFmError.userCancelled {
            // User cancelled - no action needed
        } catch {
            print("❌ [AppState] Last.fm auth failed: \(error)")
        }
    }
    
    func disconnectLastfm() {
        lastFmService.signOut()
    }
    
    @MainActor
    func completeOnboarding() async {
        withAnimation(Theme.Animation.spring) {
            isOnboarded = true
        }
        
        // Fetch initial data from Apple Music
        await fetchRecentlyPlayed()
    }
    
    func resetOnboarding() {
        withAnimation(Theme.Animation.spring) {
            isOnboarded = false
            // Note: Apple Music authorization persists and cannot be revoked programmatically
            musicKitService.refreshStatus()
            lastFmService.signOut()
            scrobbles = []
            lastSyncDate = nil
        }
    }
    
    @MainActor
    func syncNow() async {
        guard !isSyncing else { return }
        
        withAnimation(Theme.Animation.quick) {
            isSyncing = true
        }
        
        await fetchRecentlyPlayed()
        
        withAnimation(Theme.Animation.quick) {
            isSyncing = false
        }
    }
    
    @MainActor
    private func fetchRecentlyPlayed() async {
        print("📱 [AppState] Starting fetch...")
        do {
            let recentTracks = try await musicKitService.fetchRecentlyPlayed()
            print("📱 [AppState] Got \(recentTracks.count) tracks from service")
            
            withAnimation(Theme.Animation.quick) {
                // Merge new tracks with existing, avoiding duplicates based on track+artist+timestamp
                let existingKeys = Set(scrobbles.map { "\($0.trackName)-\($0.artistName)-\($0.timestamp.timeIntervalSince1970)" })
                
                let newScrobbles = recentTracks.filter { track in
                    let key = "\(track.trackName)-\(track.artistName)-\(track.timestamp.timeIntervalSince1970)"
                    return !existingKeys.contains(key)
                }
                
                print("📱 [AppState] Adding \(newScrobbles.count) new scrobbles (filtered from \(recentTracks.count))")
                
                scrobbles.insert(contentsOf: newScrobbles, at: 0)
                scrobbles.sort { $0.timestamp > $1.timestamp }
                lastSyncDate = Date()
                
                print("📱 [AppState] Total scrobbles now: \(scrobbles.count)")
            }
        } catch {
            print("❌ [AppState] Failed to fetch: \(error)")
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

