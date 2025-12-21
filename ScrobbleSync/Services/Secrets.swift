import Foundation

// MARK: - Secrets

/// Provides access to API keys stored in Info.plist (injected from xcconfig)
enum Secrets {
    
    /// Last.fm API Key
    static let lastFmApiKey: String = {
        print("🔑 [Secrets] Accessing LASTFM_API_KEY...")
        
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("❌ [Secrets] Info.plist not found")
        }
        
        print("🔑 [Secrets] Info.plist keys: \(infoDictionary.keys.joined(separator: ", "))")
        
        guard let key = infoDictionary["LASTFM_API_KEY"] as? String else {
            fatalError("❌ [Secrets] LASTFM_API_KEY not found in Info.plist")
        }
        
        guard !key.isEmpty, !key.contains("$(") else {
            fatalError("❌ [Secrets] LASTFM_API_KEY not configured (found: '\(key)'). Check your .xcconfig file and ensure it's linked to the target.")
        }
        
        print("🔑 [Secrets] LASTFM_API_KEY loaded: \(key.prefix(8))...")
        return key
    }()
    
    /// Last.fm API Secret (used for signing requests)
    static let lastFmApiSecret: String = {
        print("🔑 [Secrets] Accessing LASTFM_API_SECRET...")
        
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("❌ [Secrets] Info.plist not found")
        }
        
        guard let secret = infoDictionary["LASTFM_API_SECRET"] as? String else {
            fatalError("❌ [Secrets] LASTFM_API_SECRET not found in Info.plist")
        }
        
        guard !secret.isEmpty, !secret.contains("$(") else {
            fatalError("❌ [Secrets] LASTFM_API_SECRET not configured (found: '\(secret)'). Check your .xcconfig file and ensure it's linked to the target.")
        }
        
        print("🔑 [Secrets] LASTFM_API_SECRET loaded: \(secret.prefix(8))...")
        return secret
    }()
}

