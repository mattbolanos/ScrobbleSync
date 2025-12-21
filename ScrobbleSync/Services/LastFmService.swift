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
        }
    }
}

