import SwiftUI

// MARK: - App State

@Observable
final class AppState {
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let isOnboarded = "isOnboarded"
        static let scrobbledIds = "scrobbledAppleMusicIds"
        static let scrobbledIdsTimestamps = "scrobbledIdsTimestamps"
    }
    
    // MARK: - Constants
    
    private enum Constants {
        static let scrobbledIdsMaxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
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
    
    // MARK: - Deduplication
    
    /// Get the set of Apple Music IDs that have already been scrobbled
    private var scrobbledIds: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: Keys.scrobbledIds) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Keys.scrobbledIds)
        }
    }
    
    /// Get timestamps for when each ID was scrobbled (for cleanup)
    private var scrobbledIdsTimestamps: [String: TimeInterval] {
        get {
            UserDefaults.standard.dictionary(forKey: Keys.scrobbledIdsTimestamps) as? [String: TimeInterval] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.scrobbledIdsTimestamps)
        }
    }
    
    /// Add Apple Music IDs to the scrobbled set
    private func markAsScrobbled(ids: [String]) {
        var currentIds = scrobbledIds
        var timestamps = scrobbledIdsTimestamps
        let now = Date().timeIntervalSince1970
        
        for id in ids {
            currentIds.insert(id)
            timestamps[id] = now
        }
        
        scrobbledIds = currentIds
        scrobbledIdsTimestamps = timestamps
    }
    
    /// Clean up old scrobbled IDs (older than 7 days)
    private func cleanupOldScrobbledIds() {
        let now = Date().timeIntervalSince1970
        var timestamps = scrobbledIdsTimestamps
        var ids = scrobbledIds
        
        let expiredIds = timestamps.filter { now - $0.value > Constants.scrobbledIdsMaxAge }.keys
        
        for id in expiredIds {
            ids.remove(id)
            timestamps.removeValue(forKey: id)
        }
        
        if !expiredIds.isEmpty {
            print("📱 [AppState] Cleaned up \(expiredIds.count) old scrobbled IDs")
            scrobbledIds = ids
            scrobbledIdsTimestamps = timestamps
        }
    }
    
    /// Filter tracks to only those that haven't been scrobbled yet
    /// Uses both time-based (lastSyncDate) and ID-based deduplication
    private func filterNewTracks(_ tracks: [Scrobble]) -> [Scrobble] {
        let alreadyScrobbled = scrobbledIds
        
        return tracks.filter { track in
            // Time-based filter: only tracks played after last sync
            if let lastSync = lastSyncDate {
                guard track.timestamp > lastSync else {
                    return false
                }
            }
            
            // ID-based filter: skip if already scrobbled
            if let appleMusicId = track.appleMusicId {
                guard !alreadyScrobbled.contains(appleMusicId) else {
                    return false
                }
            }
            
            return true
        }
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
        do {
            let scrobbles = try await musicKitService.fetchRecentlyPlayed()
            self.scrobbles = scrobbles
        } catch {
            print("❌ [AppState] Failed to fetch recently played tracks: \(error)")
        }
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
        
        // Cleanup old scrobbled IDs periodically
        cleanupOldScrobbledIds()
        
        // Fetch and scrobble
        await fetchAndScrobble()
        
        withAnimation(Theme.Animation.quick) {
            isSyncing = false
        }
    }
    
    @MainActor
    private func fetchAndScrobble() async {
        print("📱 [AppState] Starting fetch and scrobble...")
        
        do {
            // Step 1: Fetch tracks from Apple Music
            let recentTracks = try await musicKitService.fetchRecentlyPlayed()
            print("📱 [AppState] Got \(recentTracks.count) tracks from Apple Music")
            
            // Step 2: Filter to only new tracks (deduplication)
            let newTracks = filterNewTracks(recentTracks)
            print("📱 [AppState] Filtered to \(newTracks.count) new tracks for scrobbling")
            
            guard !newTracks.isEmpty else {
                print("📱 [AppState] No new tracks to scrobble")
                withAnimation(Theme.Animation.quick) {
                    lastSyncDate = Date()
                }
                return
            }
            
            // Step 3: Add tracks to UI with pending status
            withAnimation(Theme.Animation.quick) {
                // Merge with existing, avoiding duplicates by track+artist+timestamp
                let existingKeys = Set(scrobbles.map { "\($0.trackName)-\($0.artistName)-\($0.timestamp.timeIntervalSince1970)" })
                
                let tracksToAdd = newTracks.filter { track in
                    let key = "\(track.trackName)-\(track.artistName)-\(track.timestamp.timeIntervalSince1970)"
                    return !existingKeys.contains(key)
                }
                
                scrobbles.insert(contentsOf: tracksToAdd, at: 0)
                scrobbles.sort { $0.timestamp > $1.timestamp }
            }
            
            // Step 4: Scrobble to Last.fm (if authenticated)
            if lastFmService.isAuthenticated {
                await scrobbleToLastFm(tracks: newTracks)
            } else {
                print("📱 [AppState] Last.fm not authenticated, skipping scrobble")
            }
            
            // Step 5: Update last sync date
            withAnimation(Theme.Animation.quick) {
                lastSyncDate = Date()
            }
            
            print("📱 [AppState] Sync complete. Total scrobbles: \(scrobbles.count)")
            
        } catch {
            print("❌ [AppState] Fetch failed: \(error)")
        }
    }
    
    @MainActor
    private func scrobbleToLastFm(tracks: [Scrobble]) async {
        print("📱 [AppState] Scrobbling \(tracks.count) tracks to Last.fm...")
        
        do {
            let result = try await lastFmService.scrobble(tracks: tracks)
            
            print("📱 [AppState] Scrobble result: \(result.accepted) accepted, \(result.ignored) ignored")
            
            // Update scrobble statuses based on results
            withAnimation(Theme.Animation.quick) {
                for trackResult in result.results {
                    // Find matching scrobble by Apple Music ID or track name + artist
                    let matchIndex = scrobbles.firstIndex { scrobble in
                        if let scrobbleId = scrobble.appleMusicId,
                           let resultId = trackResult.appleMusicId,
                           scrobbleId == resultId {
                            return true
                        }
                        return scrobble.trackName == trackResult.trackName &&
                               scrobble.artistName == trackResult.artistName
                    }
                    
                    if let index = matchIndex {
                        if trackResult.accepted {
                            scrobbles[index].status = .success
                        } else {
                            scrobbles[index].status = .failed(trackResult.errorMessage ?? "Unknown error")
                        }
                    }
                }
            }
            
            // Mark successfully scrobbled tracks as scrobbled (for deduplication)
            let successfulIds = result.results
                .filter { $0.accepted }
                .compactMap { $0.appleMusicId }
            
            if !successfulIds.isEmpty {
                markAsScrobbled(ids: successfulIds)
                print("📱 [AppState] Marked \(successfulIds.count) tracks as scrobbled")
            }
            
        } catch {
            print("❌ [AppState] Scrobble failed: \(error)")
            
            // Mark all tracks as failed
            withAnimation(Theme.Animation.quick) {
                for track in tracks {
                    if let index = scrobbles.firstIndex(where: { $0.id == track.id }) {
                        scrobbles[index].status = .failed(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    @MainActor
    func retryScrobble(_ scrobble: Scrobble) {
        guard let index = scrobbles.firstIndex(where: { $0.id == scrobble.id }) else { return }
        
        withAnimation(Theme.Animation.quick) {
            scrobbles[index].status = .pending
        }
        
        // Actually retry the scrobble
        Task {
            await scrobbleToLastFm(tracks: [scrobble])
        }
    }
    
    /// Retry all failed scrobbles
    @MainActor
    func retryAllFailed() async {
        let failedScrobbles = scrobbles.filter { $0.status.isFailed }
        
        guard !failedScrobbles.isEmpty else { return }
        
        print("📱 [AppState] Retrying \(failedScrobbles.count) failed scrobbles...")
        
        // Mark as pending
        withAnimation(Theme.Animation.quick) {
            for scrobble in failedScrobbles {
                if let index = scrobbles.firstIndex(where: { $0.id == scrobble.id }) {
                    scrobbles[index].status = .pending
                }
            }
        }
        
        // Scrobble
        await scrobbleToLastFm(tracks: failedScrobbles)
    }
}

