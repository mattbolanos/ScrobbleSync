import SwiftUI

// MARK: - Connection Card

struct ConnectionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isConnected: Bool
    var isLoading: Bool = false
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isConnected ? 0.15 : 0.08))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Status indicator
                ZStack {
                    Circle()
                        .fill(isConnected ? Theme.Colors.successMuted : Theme.Colors.secondaryBackground)
                        .frame(width: 32, height: 32)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(accentColor)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: isConnected ? "checkmark" : "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isConnected ? Theme.Colors.success : Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous)
                    .stroke(isConnected ? accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isConnected)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ConnectionCard(
            title: "Apple Music",
            subtitle: "Connected",
            systemImage: "music.note",
            isConnected: true,
            accentColor: Theme.Colors.appleMusicPink
        ) {}
        
        ConnectionCard(
            title: "Last.fm",
            subtitle: "Tap to connect",
            systemImage: "antenna.radiowaves.left.and.right",
            isConnected: false,
            accentColor: Theme.Colors.lastfmRed
        ) {}
    }
    .padding()
    .background(Theme.Colors.background)
}

