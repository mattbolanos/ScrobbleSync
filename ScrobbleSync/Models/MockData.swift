import Foundation

// MARK: - Mock Data

enum MockData {
    static let scrobbles: [Scrobble] = generateMockScrobbles()
    
    private static func generateMockScrobbles() -> [Scrobble] {
        let tracks: [(track: String, artist: String, album: String)] = [
            ("Blinding Lights", "The Weeknd", "After Hours"),
            ("Heat Waves", "Glass Animals", "Dreamland"),
            ("Levitating", "Dua Lipa", "Future Nostalgia"),
            ("Save Your Tears", "The Weeknd", "After Hours"),
            ("drivers license", "Olivia Rodrigo", "SOUR"),
            ("good 4 u", "Olivia Rodrigo", "SOUR"),
            ("Stay", "The Kid LAROI & Justin Bieber", "F*CK LOVE 3: OVER YOU"),
            ("Montero (Call Me By Your Name)", "Lil Nas X", "MONTERO"),
            ("Kiss Me More", "Doja Cat ft. SZA", "Planet Her"),
            ("Peaches", "Justin Bieber ft. Daniel Caesar & Giveon", "Justice"),
            ("Shivers", "Ed Sheeran", "="),
            ("Bad Habits", "Ed Sheeran", "="),
            ("Industry Baby", "Lil Nas X & Jack Harlow", "MONTERO"),
            ("Need to Know", "Doja Cat", "Planet Her"),
            ("Take My Breath", "The Weeknd", "Dawn FM"),
            ("Easy On Me", "Adele", "30"),
            ("Oh My God", "Adele", "30"),
            ("Ghost", "Justin Bieber", "Justice"),
            ("Happier Than Ever", "Billie Eilish", "Happier Than Ever"),
            ("Therefore I Am", "Billie Eilish", "Happier Than Ever"),
            ("positions", "Ariana Grande", "Positions"),
            ("34+35", "Ariana Grande", "Positions"),
            ("Dynamite", "BTS", "BE"),
            ("Butter", "BTS", "Butter"),
            ("Permission to Dance", "BTS", "Butter"),
            ("Watermelon Sugar", "Harry Styles", "Fine Line"),
            ("As It Was", "Harry Styles", "Harry's House"),
            ("Late Night Talking", "Harry Styles", "Harry's House"),
            ("Anti-Hero", "Taylor Swift", "Midnights"),
            ("Lavender Haze", "Taylor Swift", "Midnights"),
            ("Midnight Rain", "Taylor Swift", "Midnights"),
            ("About Damn Time", "Lizzo", "Special"),
            ("Running Up That Hill", "Kate Bush", "Hounds of Love"),
            ("Break My Soul", "Beyoncé", "RENAISSANCE"),
            ("CUFF IT", "Beyoncé", "RENAISSANCE"),
            ("Unholy", "Sam Smith & Kim Petras", "Gloria"),
            ("Flowers", "Miley Cyrus", "Endless Summer Vacation"),
            ("Kill Bill", "SZA", "SOS"),
            ("Vampire", "Olivia Rodrigo", "GUTS"),
            ("greedy", "Tate McRae", "THINK LATER"),
        ]
        
        var scrobbles: [Scrobble] = []
        let now = Date()
        let calendar = Calendar.current
        
        // Generate scrobbles over the past week
        for i in 0..<40 {
            let track = tracks[i % tracks.count]
            
            // Random time within the past 7 days, weighted toward recent
            let hoursAgo = Double(i) * 2.5 + Double.random(in: 0...3)
            let timestamp = calendar.date(byAdding: .hour, value: -Int(hoursAgo), to: now) ?? now
            
            // Determine status - mostly success, some pending/failed
            let status: ScrobbleStatus
            let statusRoll = Int.random(in: 0..<100)
            if statusRoll < 85 {
                status = .success
            } else if statusRoll < 93 {
                status = .pending
            } else {
                let errors = [
                    "Network connection lost",
                    "Last.fm API rate limited",
                    "Invalid session key",
                    "Server timeout",
                    "Track not found in Last.fm database"
                ]
                status = .failed(errors.randomElement()!)
            }
            
            scrobbles.append(Scrobble(
                trackName: track.track,
                artistName: track.artist,
                albumName: track.album,
                timestamp: timestamp,
                status: status
            ))
        }
        
        // Sort by timestamp descending (most recent first)
        return scrobbles.sorted { $0.timestamp > $1.timestamp }
    }
}

