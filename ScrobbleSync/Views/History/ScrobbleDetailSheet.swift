import SwiftUI

// MARK: - Scrobble Detail Sheet

struct ScrobbleDetailSheet: View {
    let scrobble: Scrobble
    let onRetry: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xxl) {
                // Track info card
                VStack(spacing: Theme.Spacing.lg) {
                    // Album art placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.tertiaryBackground,
                                        Theme.Colors.secondaryBackground
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(Theme.Colors.tertiaryText)
                    }
                    .frame(width: 120, height: 120)
                    
                    // Track details
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(scrobble.trackName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text(scrobble.artistName)
                            .font(.body)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        
                        Text(scrobble.albumName)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.tertiaryText)
                    }
                    
                    // Timestamp
                    Text(scrobble.formattedTimestamp)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.tertiaryText)
                        .padding(.top, Theme.Spacing.xs)
                }
                .padding(Theme.Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
                
                // Error info (if failed)
                if case .failed(let errorMessage) = scrobble.status {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.Colors.error)
                            
                            Text("Scrobble Failed")
                                .font(.headline)
                                .foregroundStyle(Theme.Colors.primaryText)
                        }
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.errorMuted)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: Theme.Spacing.md) {
                    if scrobble.status.isFailed {
                        Button {
                            onRetry()
                            dismiss()
                        } label: {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Retry Scrobble")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous)
                                    .fill(Theme.Colors.accentGreen)
                            )
                        }
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous)
                                    .fill(Theme.Colors.cardBackground)
                            )
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.background)
            .navigationTitle("Scrobble Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.tertiaryText)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    ScrobbleDetailSheet(
        scrobble: Scrobble(
            trackName: "Blinding Lights",
            artistName: "The Weeknd",
            albumName: "After Hours",
            timestamp: Date().addingTimeInterval(-3600),
            status: .failed("Network connection lost. Please check your internet connection and try again.")
        ),
        onRetry: {}
    )
}

