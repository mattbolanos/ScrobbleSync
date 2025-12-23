import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Last.fm Service

@Observable
final class LastFmService: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let baseURL = "https://ws.audioscrobbler.com/2.0/"
        static let authURL = "https://www.last.fm/api/auth/"
        static let callbackScheme = "scrobblesync"
        static let callbackURL = "scrobblesync://auth"
        static let maxBatchSize = 50
    }
    
    // MARK: - Properties
    
    private(set) var isAuthenticated: Bool = false
    private(set) var username: String = ""
    private(set) var isAuthenticating: Bool = false
    
    private var sessionKey: String?
    private var webAuthSession: ASWebAuthenticationSession?
    
    // MARK: - Computed Properties
    
    var statusDescription: String {
        if isAuthenticating {
            return "Connecting..."
        } else if isAuthenticated {
            return "@\(username)"
        } else {
            return "Tap to connect"
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        print("🎸 [LastFm] Service initialized")
        loadStoredCredentials()
    }
    
    // MARK: - Authentication
    
    /// Start the Last.fm OAuth authentication flow
    @MainActor
    func authenticate() async throws {
        print("🎸 [LastFm] authenticate() called")
        guard !isAuthenticating else {
            print("🎸 [LastFm] Already authenticating, returning")
            return
        }
        
        isAuthenticating = true
        defer { 
            isAuthenticating = false 
            print("🎸 [LastFm] isAuthenticating set to false")
        }
        
        // Build auth URL
        print("🎸 [LastFm] Getting API key from Secrets...")
        let apiKey = Secrets.lastFmApiKey
        print("🎸 [LastFm] API key retrieved: \(apiKey.prefix(8))...")
        
        var components = URLComponents(string: Constants.authURL)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "cb", value: Constants.callbackURL)
        ]
        
        guard let authURL = components.url else {
            print("❌ [LastFm] Failed to build auth URL")
            throw LastFmError.invalidURL
        }
        
        print("🎸 [LastFm] Auth URL: \(authURL)")
        
        // Get token from web auth
        print("🎸 [LastFm] Starting web auth...")
        let token = try await performWebAuth(url: authURL)
        print("🎸 [LastFm] Got token: \(token.prefix(8))...")
        
        // Exchange token for session
        print("🎸 [LastFm] Exchanging token for session...")
        try await getSession(token: token)
        print("🎸 [LastFm] Authentication complete!")
    }
    
    /// Sign out and clear stored credentials
    func signOut() {
        print("🎸 [LastFm] Signing out...")
        KeychainService.clearAll()
        sessionKey = nil
        username = ""
        isAuthenticated = false
        print("🎸 [LastFm] Signed out successfully")
    }
    
    // MARK: - Scrobbling
    
    /// Scrobble tracks to Last.fm
    /// - Parameter tracks: Array of Scrobble objects to submit
    /// - Returns: ScrobbleResult containing success/failure details for each track
    func scrobble(tracks: [Scrobble]) async throws -> ScrobbleResult {
        guard isAuthenticated, let sk = sessionKey else {
            print("❌ [LastFm] Cannot scrobble - not authenticated")
            throw LastFmError.notAuthenticated
        }
        
        guard !tracks.isEmpty else {
            print("🎸 [LastFm] No tracks to scrobble")
            return ScrobbleResult(accepted: 0, ignored: 0, results: [])
        }
        
        print("🎸 [LastFm] Scrobbling \(tracks.count) tracks...")
        
        // Process in batches of 50
        var allResults: [ScrobbleTrackResult] = []
        var totalAccepted = 0
        var totalIgnored = 0
        
        for batchStart in stride(from: 0, to: tracks.count, by: Constants.maxBatchSize) {
            let batchEnd = min(batchStart + Constants.maxBatchSize, tracks.count)
            let batch = Array(tracks[batchStart..<batchEnd])
            
            print("🎸 [LastFm] Processing batch \(batchStart/Constants.maxBatchSize + 1): \(batch.count) tracks")
            
            let result = try await scrobbleBatch(tracks: batch, sessionKey: sk)
            allResults.append(contentsOf: result.results)
            totalAccepted += result.accepted
            totalIgnored += result.ignored
        }
        
        print("🎸 [LastFm] Scrobble complete: \(totalAccepted) accepted, \(totalIgnored) ignored")
        
        return ScrobbleResult(accepted: totalAccepted, ignored: totalIgnored, results: allResults)
    }
    
    /// Scrobble a single batch of up to 50 tracks
    private func scrobbleBatch(tracks: [Scrobble], sessionKey: String) async throws -> ScrobbleResult {
        let apiKey = Secrets.lastFmApiKey
        let apiSecret = Secrets.lastFmApiSecret
        
        // Build params with array notation
        var params: [(String, String)] = [
            ("api_key", apiKey),
            ("method", "track.scrobble"),
            ("sk", sessionKey)
        ]
        
        // Add track params with array notation
        for (index, track) in tracks.enumerated() {
            params.append(("artist[\(index)]", track.artistName))
            params.append(("track[\(index)]", track.trackName))
            params.append(("timestamp[\(index)]", String(Int(track.timestamp.timeIntervalSince1970))))
            params.append(("album[\(index)]", track.albumName))
            
            if let duration = track.duration {
                params.append(("duration[\(index)]", String(Int(duration))))
            }
        }
        
        // Generate signature (params must be sorted by ASCII)
        let signature = generateSignature(params: params, secret: apiSecret)
        params.append(("api_sig", signature))
        params.append(("format", "json"))
        
        // Build POST body
        let bodyString = params.map { "\($0.0)=\(percentEncode($0.1))" }.joined(separator: "&")
        
        guard let url = URL(string: Constants.baseURL) else {
            throw LastFmError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🎸 [LastFm] Sending scrobble request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LastFmError.requestFailed
        }
        
        print("🎸 [LastFm] Scrobble response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🎸 [LastFm] Scrobble response: \(responseString.prefix(500))...")
        }
        
        // Parse JSON response
        let scrobbleResponse = try JSONDecoder().decode(ScrobbleResponse.self, from: data)
        
        // Check for API error
        if let error = scrobbleResponse.error {
            let message = scrobbleResponse.message ?? "Unknown error"
            print("❌ [LastFm] Scrobble API error \(error): \(message)")
            throw LastFmError.apiError(code: error, message: message)
        }
        
        guard let scrobbles = scrobbleResponse.scrobbles else {
            throw LastFmError.invalidResponse
        }
        
        // Map response to results
        let results = mapScrobbleResults(scrobbles: scrobbles, originalTracks: tracks)
        
        return ScrobbleResult(
            accepted: scrobbles.attr.accepted,
            ignored: scrobbles.attr.ignored,
            results: results
        )
    }
    
    /// Map Last.fm scrobble response to our result format
    private func mapScrobbleResults(scrobbles: ScrobblesWrapper, originalTracks: [Scrobble]) -> [ScrobbleTrackResult] {
        // Handle both single scrobble (object) and multiple scrobbles (array)
        let scrobbleItems: [ScrobbleItem]
        switch scrobbles.scrobble {
        case .single(let item):
            scrobbleItems = [item]
        case .multiple(let items):
            scrobbleItems = items
        }
        
        return zip(originalTracks, scrobbleItems).map { track, item in
            let ignoredCode = Int(item.ignoredMessage.code) ?? 0
            let errorMessage = mapIgnoredCode(ignoredCode)
            
            return ScrobbleTrackResult(
                appleMusicId: track.appleMusicId,
                trackName: track.trackName,
                artistName: track.artistName,
                accepted: ignoredCode == 0,
                ignoredCode: ignoredCode,
                errorMessage: errorMessage
            )
        }
    }
    
    /// Map Last.fm ignored codes to human-readable messages
    private func mapIgnoredCode(_ code: Int) -> String? {
        switch code {
        case 0:
            return nil
        case 1:
            return "Artist was ignored"
        case 2:
            return "Track was ignored"
        case 3:
            return "Timestamp too old"
        case 4:
            return "Timestamp too new"
        case 5:
            return "Daily scrobble limit exceeded"
        default:
            return "Unknown error (code \(code))"
        }
    }
    
    /// Percent-encode a string for URL form encoding
    private func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
    
    // MARK: - Private Methods
    
    private func loadStoredCredentials() {
        print("🎸 [LastFm] Loading stored credentials...")
        if let storedSessionKey = KeychainService.get(.sessionKey),
           let storedUsername = KeychainService.get(.username) {
            sessionKey = storedSessionKey
            username = storedUsername
            isAuthenticated = true
            print("🎸 [LastFm] Found stored credentials for @\(storedUsername)")
        } else {
            print("🎸 [LastFm] No stored credentials found")
        }
    }
    
    @MainActor
    private func performWebAuth(url: URL) async throws -> String {
        print("🎸 [LastFm] performWebAuth() starting...")
        
        return try await withCheckedThrowingContinuation { continuation in
            print("🎸 [LastFm] Creating ASWebAuthenticationSession...")
            
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: Constants.callbackScheme
            ) { callbackURL, error in
                print("🎸 [LastFm] Web auth callback received")
                
                if let error = error {
                    print("❌ [LastFm] Web auth error: \(error)")
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: LastFmError.userCancelled)
                    } else {
                        continuation.resume(throwing: LastFmError.authFailed(error.localizedDescription))
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    print("❌ [LastFm] No callback URL received")
                    continuation.resume(throwing: LastFmError.noToken)
                    return
                }
                
                print("🎸 [LastFm] Callback URL: \(callbackURL)")
                
                guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
                    print("❌ [LastFm] Could not extract token from callback URL")
                    continuation.resume(throwing: LastFmError.noToken)
                    return
                }
                
                print("🎸 [LastFm] Token extracted successfully")
                continuation.resume(returning: token)
            }
            
            print("🎸 [LastFm] Setting presentation context provider...")
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            self.webAuthSession = session
            
            print("🎸 [LastFm] Starting auth session...")
            if !session.start() {
                print("❌ [LastFm] Failed to start auth session")
                continuation.resume(throwing: LastFmError.authFailed("Failed to start auth session"))
            } else {
                print("🎸 [LastFm] Auth session started successfully")
            }
        }
    }
    
    private func getSession(token: String) async throws {
        print("🎸 [LastFm] getSession() starting...")
        
        let apiKey = Secrets.lastFmApiKey
        let apiSecret = Secrets.lastFmApiSecret
        
        // Build params (must be sorted alphabetically for signature)
        let params: [(String, String)] = [
            ("api_key", apiKey),
            ("method", "auth.getSession"),
            ("token", token)
        ]
        
        // Generate signature
        let signature = generateSignature(params: params, secret: apiSecret)
        print("🎸 [LastFm] Generated signature: \(signature.prefix(8))...")
        
        // Build URL
        var components = URLComponents(string: Constants.baseURL)!
        components.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
        components.queryItems?.append(URLQueryItem(name: "api_sig", value: signature))
        components.queryItems?.append(URLQueryItem(name: "format", value: "json"))
        
        guard let url = components.url else {
            print("❌ [LastFm] Failed to build session URL")
            throw LastFmError.invalidURL
        }
        
        print("🎸 [LastFm] Requesting session from: \(url)")
        
        // Make request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [LastFm] Invalid response type")
            throw LastFmError.requestFailed
        }
        
        print("🎸 [LastFm] Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🎸 [LastFm] Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [LastFm] Request failed with status \(httpResponse.statusCode)")
            throw LastFmError.requestFailed
        }
        
        // Parse response
        let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
        
        guard let session = sessionResponse.session else {
            if let error = sessionResponse.error {
                print("❌ [LastFm] API error \(error): \(sessionResponse.message ?? "Unknown")")
                throw LastFmError.apiError(code: error, message: sessionResponse.message ?? "Unknown error")
            }
            print("❌ [LastFm] Invalid response - no session object")
            throw LastFmError.invalidResponse
        }
        
        print("🎸 [LastFm] Got session for user: @\(session.name)")
        
        // Store credentials
        let savedKey = KeychainService.save(session.key, for: .sessionKey)
        let savedUsername = KeychainService.save(session.name, for: .username)
        
        print("🎸 [LastFm] Keychain save - key: \(savedKey), username: \(savedUsername)")
        
        guard savedKey && savedUsername else {
            print("❌ [LastFm] Failed to save to Keychain")
            throw LastFmError.keychainError
        }
        
        // Update state
        sessionKey = session.key
        username = session.name
        isAuthenticated = true
        
        print("🎸 [LastFm] Session established successfully!")
    }
    
    /// Generate MD5 signature per Last.fm API spec
    private func generateSignature(params: [(String, String)], secret: String) -> String {
        // Sort params alphabetically by key and concatenate
        let sortedParams = params.sorted { $0.0 < $1.0 }
        let signatureBase = sortedParams.map { "\($0.0)\($0.1)" }.joined() + secret
        
        // MD5 hash
        let digest = Insecure.MD5.hash(data: Data(signatureBase.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension LastFmService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        print("🎸 [LastFm] presentationAnchor() called")
        
        // Get the first connected window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            print("⚠️ [LastFm] No window scene found")
            fatalError("No window scene available for authentication")
        }
        
        // Return the key window or first window from the scene
        if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            print("🎸 [LastFm] Using key window as anchor")
            return keyWindow
        }
        
        if let firstWindow = windowScene.windows.first {
            print("🎸 [LastFm] Using first window as anchor")
            return firstWindow
        }
        
        print("⚠️ [LastFm] No windows found, creating new window")
        return UIWindow(windowScene: windowScene)
    }
}

// MARK: - Response Models

private struct SessionResponse: Decodable {
    let session: Session?
    let error: Int?
    let message: String?
    
    struct Session: Decodable {
        let name: String
        let key: String
        let subscriber: Int
    }
}

// MARK: - Scrobble Response Models

private struct ScrobbleResponse: Decodable {
    let scrobbles: ScrobblesWrapper?
    let error: Int?
    let message: String?
}

private struct ScrobblesWrapper: Decodable {
    let scrobble: ScrobbleItemOrArray
    let attr: ScrobblesAttr
    
    enum CodingKeys: String, CodingKey {
        case scrobble
        case attr = "@attr"
    }
}

private struct ScrobblesAttr: Decodable {
    let accepted: Int
    let ignored: Int
}

/// Handles Last.fm returning either a single object or an array for scrobbles
private enum ScrobbleItemOrArray: Decodable {
    case single(ScrobbleItem)
    case multiple([ScrobbleItem])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([ScrobbleItem].self) {
            self = .multiple(array)
        } else if let single = try? container.decode(ScrobbleItem.self) {
            self = .single(single)
        } else {
            throw DecodingError.typeMismatch(
                ScrobbleItemOrArray.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected array or single scrobble item")
            )
        }
    }
}

private struct ScrobbleItem: Decodable {
    let track: CorrectedValue
    let artist: CorrectedValue
    let album: CorrectedValue
    let albumArtist: CorrectedValue
    let timestamp: String
    let ignoredMessage: IgnoredMessage
}

private struct CorrectedValue: Decodable {
    let corrected: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case corrected
        case text = "#text"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        corrected = try container.decode(String.self, forKey: .corrected)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
    }
}

private struct IgnoredMessage: Decodable {
    let code: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case text = "#text"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
    }
}

// MARK: - Scrobble Result Types

struct ScrobbleResult {
    let accepted: Int
    let ignored: Int
    let results: [ScrobbleTrackResult]
}

struct ScrobbleTrackResult {
    let appleMusicId: String?
    let trackName: String
    let artistName: String
    let accepted: Bool
    let ignoredCode: Int
    let errorMessage: String?
}

// MARK: - Errors

enum LastFmError: LocalizedError {
    case invalidURL
    case userCancelled
    case noToken
    case authFailed(String)
    case requestFailed
    case invalidResponse
    case apiError(code: Int, message: String)
    case keychainError
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .userCancelled:
            return "Authentication was cancelled"
        case .noToken:
            return "No authentication token received"
        case .authFailed(let message):
            return "Authentication failed: \(message)"
        case .requestFailed:
            return "Request failed"
        case .invalidResponse:
            return "Invalid response from Last.fm"
        case .apiError(_, let message):
            return message
        case .keychainError:
            return "Failed to save credentials"
        case .notAuthenticated:
            return "Not authenticated with Last.fm"
        }
    }
}

