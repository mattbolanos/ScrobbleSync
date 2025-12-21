import Foundation

// MARK: - Scrobble Status

enum ScrobbleStatus: Equatable, Hashable {
    case success
    case pending
    case failed(String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isPending: Bool {
        if case .pending = self { return true }
        return false
    }
    
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

// MARK: - Scrobble Model

struct Scrobble: Identifiable, Hashable {
    let id: UUID
    let trackName: String
    let artistName: String
    let albumName: String
    let artworkURL: URL?
    let timestamp: Date
    var status: ScrobbleStatus
    
    init(
        id: UUID = UUID(),
        trackName: String,
        artistName: String,
        albumName: String,
        artworkURL: URL? = nil,
        timestamp: Date,
        status: ScrobbleStatus = .success
    ) {
        self.id = id
        self.trackName = trackName
        self.artistName = artistName
        self.albumName = albumName
        self.artworkURL = artworkURL
        self.timestamp = timestamp
        self.status = status
    }
    
    // Relative timestamp formatting
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Filter Type

enum ScrobbleFilter: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case failed = "Failed"
    
    func matches(_ scrobble: Scrobble) -> Bool {
        switch self {
        case .all:
            return true
        case .pending:
            return scrobble.status.isPending
        case .failed:
            return scrobble.status.isFailed
        }
    }
}

