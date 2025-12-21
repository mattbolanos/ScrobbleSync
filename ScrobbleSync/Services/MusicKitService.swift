import MusicKit
import Foundation
import Observation

// MARK: - MusicKit Service

@Observable
final class MusicKitService {
    // MARK: - Properties
    
    var authorizationStatus: MusicAuthorization.Status = .notDetermined
    var isAuthorizing: Bool = false
    
    // MARK: - Computed Properties
    
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Tap to connect"
        case .denied:
            return "Access denied - check Settings"
        case .restricted:
            return "Access restricted"
        case .authorized:
            return "Connected"
        @unknown default:
            return "Unknown status"
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Check current status on init
        authorizationStatus = MusicAuthorization.currentStatus
    }
    
    // MARK: - Authorization
    
    @MainActor
    func requestAuthorization() async {
        guard !isAuthorizing else { return }
        
        isAuthorizing = true
        defer { isAuthorizing = false }
        
        let status = await MusicAuthorization.request()
        authorizationStatus = status
    }
    
    /// Refresh the current authorization status without prompting
    func refreshStatus() {
        authorizationStatus = MusicAuthorization.currentStatus
    }
    
    // MARK: - Data Fetching
    
    /// Fetch recently played tracks from Apple Music
    func fetchRecentlyPlayed() async throws -> [Scrobble] {
        print("🎵 [MusicKit] Fetching recently played tracks...")
        print("🎵 [MusicKit] Authorization status: \(authorizationStatus)")
        
        guard isAuthorized else {
            print("❌ [MusicKit] Not authorized")
            throw MusicKitError.notAuthorized
        }
        
        let request = MusicRecentlyPlayedRequest<Track>()
        let response = try await request.response()
        
        print("🎵 [MusicKit] Received \(response.items.count) tracks")
        
        let scrobbles = response.items.compactMap { track in
            print("  - \(track.title) by \(track.artistName), lastPlayed: \(track.lastPlayedDate?.description ?? "nil")")
            return Scrobble(
                trackName: track.title,
                artistName: track.artistName,
                albumName: track.albumTitle ?? "Unknown Album",
                artworkURL: track.artwork?.url(width: 100, height: 100),
                timestamp: track.lastPlayedDate ?? Date(),
                status: .pending
            )
        }
        
        print("🎵 [MusicKit] Returning \(scrobbles.count) scrobbles")
        return scrobbles
    }
}

// MARK: - MusicKit Errors

enum MusicKitError: LocalizedError {
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Apple Music access not authorized"
        }
    }
}

