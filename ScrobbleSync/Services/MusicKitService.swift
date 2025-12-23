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
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultTrackDuration: TimeInterval = 210 // ~3.5 minutes
    }
    
    // MARK: - Data Fetching
    
    /// Fetch recently played tracks from Apple Music
    func fetchRecentlyPlayed() async throws -> [Scrobble] {
        guard isAuthorized else {
            throw MusicKitError.notAuthorized
        }
        
        let request = MusicRecentlyPlayedRequest<Track>()
        let response = try await request.response()
        
        // Convert to array for processing
        let tracks = Array(response.items)
        
        // Estimate timestamps for tracks with nil lastPlayedDate
        let estimatedTimestamps = estimateTimestamps(for: tracks)
        
        let scrobbles = tracks.enumerated().compactMap { (index, track) -> Scrobble? in
            let timestamp = estimatedTimestamps[index]
            let trackDuration = track.duration
            
            return Scrobble(
                trackName: track.title,
                artistName: track.artistName,
                albumName: track.albumTitle ?? "Unknown Album",
                artworkURL: track.artwork?.url(width: 300, height: 300),
                timestamp: track.lastPlayedDate ?? timestamp,
                status: .pending,
                appleMusicId: track.id.rawValue,
                duration: trackDuration,
                isEstimated: track.lastPlayedDate == nil,
            )
        }
        
        return scrobbles
    }
    
    // MARK: - Timestamp Estimation
    
    /// Estimate timestamps for tracks with nil lastPlayedDate values.
    /// Works backwards from known timestamps using track durations.
    private func estimateTimestamps(for tracks: [Track]) -> [Date] {
        var timestamps: [Date] = []
        
        guard !tracks.isEmpty else { return [] }
        
        // Start at now minus the duration of the first track
        let firstTrackDuration = tracks.first?.duration ?? Constants.defaultTrackDuration
        var currentEstimate = Date().addingTimeInterval(-firstTrackDuration)
        
        // MusicKit returns tracks ordered by recency (most recent first)
        // We process forward through the array, using known dates as anchors
        // and estimating backwards for nil dates
        
        for track in tracks {
            if let actualDate = track.lastPlayedDate {
                // Use the actual date as an anchor point
                currentEstimate = actualDate
            }
            
            timestamps.append(currentEstimate)
            
            // Move backwards in time for the next track
            let duration = track.duration ?? Constants.defaultTrackDuration
            currentEstimate = currentEstimate.addingTimeInterval(-duration)
        }
        
        return timestamps
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

