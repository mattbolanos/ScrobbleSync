import SwiftUI

// MARK: - Empty State View

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(width: 80, height: 80)
                
                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
            
            // Text
            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            
            // Optional action button
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(Theme.Colors.accentGreen)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xxxl)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        EmptyStateView(
            systemImage: "checkmark.circle",
            title: "All Caught Up",
            description: "You have no pending scrobbles. Everything is synced to Last.fm."
        )
        
        Divider()
        
        EmptyStateView(
            systemImage: "wifi.slash",
            title: "No Connection",
            description: "Check your internet connection and try again.",
            actionTitle: "Retry"
        ) {
            print("Retry tapped")
        }
    }
}

