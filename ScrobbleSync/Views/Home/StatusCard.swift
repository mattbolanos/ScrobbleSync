import SwiftUI

// MARK: - Status Card

struct StatusCard: View {
    let isSyncing: Bool
    let lastSyncDescription: String
    let backgroundSyncEnabled: Bool
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                if isSyncing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(statusColor)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: statusIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
            }
            
            // Text content
            VStack(alignment: .leading, spacing: Theme.Spacing.xxxs) {
                Text(statusTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous)
                .stroke(Theme.Colors.separator.opacity(0.5), lineWidth: 0.5)
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        if isSyncing {
            return Theme.Colors.accentGreen
        }
        return backgroundSyncEnabled ? Theme.Colors.accentGreen : Theme.Colors.secondaryText
    }
    
    private var statusIcon: String {
        backgroundSyncEnabled ? "checkmark.circle.fill" : "pause.circle.fill"
    }
    
    private var statusTitle: String {
        if isSyncing {
            return "Syncing..."
        }
        return backgroundSyncEnabled ? "Syncing in Background" : "Background Sync Paused"
    }
    
    private var statusSubtitle: String {
        if isSyncing {
            return "Updating your scrobbles"
        }
        return lastSyncDescription
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StatusCard(
            isSyncing: false,
            lastSyncDescription: "Last synced 5 minutes ago",
            backgroundSyncEnabled: true
        )
        
        StatusCard(
            isSyncing: true,
            lastSyncDescription: "Last synced 5 minutes ago",
            backgroundSyncEnabled: true
        )
        
        StatusCard(
            isSyncing: false,
            lastSyncDescription: "Last synced 2 hours ago",
            backgroundSyncEnabled: false
        )
    }
    .padding()
    .background(Theme.Colors.background)
}

