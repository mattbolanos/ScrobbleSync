import Foundation

// MARK: - Preview Data

enum PreviewData {
    /// Sample scrobbles for SwiftUI previews
    static let scrobbles: [Scrobble] = [
        Scrobble(
            trackName: "Blinding Lights",
            artistName: "The Weeknd",
            albumName: "After Hours",
            timestamp: Date(),
            status: .success
        ),
        Scrobble(
            trackName: "Heat Waves",
            artistName: "Glass Animals",
            albumName: "Dreamland",
            timestamp: Date().addingTimeInterval(-3600),
            status: .pending
        ),
        Scrobble(
            trackName: "Levitating",
            artistName: "Dua Lipa",
            albumName: "Future Nostalgia",
            timestamp: Date().addingTimeInterval(-7200),
            status: .failed("Network error")
        ),
        Scrobble(
            trackName: "Anti-Hero",
            artistName: "Taylor Swift",
            albumName: "Midnights",
            timestamp: Date().addingTimeInterval(-10800),
            status: .success
        ),
        Scrobble(
            trackName: "As It Was",
            artistName: "Harry Styles",
            albumName: "Harry's House",
            timestamp: Date().addingTimeInterval(-14400),
            status: .success
        )
    ]
}
