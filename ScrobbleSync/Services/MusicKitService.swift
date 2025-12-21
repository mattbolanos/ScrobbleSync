import MusicKit
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
}

