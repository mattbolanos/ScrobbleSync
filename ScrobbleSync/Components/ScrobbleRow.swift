import SwiftUI

// MARK: - Scrobble Row

struct ScrobbleRow: View {
    let scrobble: Scrobble
    var showFullTimestamp: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Album art placeholder
                albumArtPlaceholder
                
                // Track info
                VStack(alignment: .leading, spacing: Theme.Spacing.xxxs) {
                    Text(scrobble.trackName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text(scrobble.artistName)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Timestamp and status
                VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
                    Text(showFullTimestamp ? scrobble.formattedTimestamp : scrobble.relativeTimestamp)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryText)
                    
                    statusIndicator
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
    
    // MARK: - Subviews
    
    private var albumArtPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small, style: .continuous)
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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
        .frame(width: 44, height: 44)
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch scrobble.status {
        case .success:
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.success)
            }
            
        case .pending:
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.pending)
            }
            
        case .failed:
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.error)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        ScrobbleRow(
            scrobble: Scrobble(
                trackName: "Blinding Lights",
                artistName: "The Weeknd",
                albumName: "After Hours",
                timestamp: Date(),
                status: .success
            )
        )
        
        ScrobbleRow(
            scrobble: Scrobble(
                trackName: "Heat Waves",
                artistName: "Glass Animals",
                albumName: "Dreamland",
                timestamp: Date().addingTimeInterval(-3600),
                status: .pending
            )
        )
        
        ScrobbleRow(
            scrobble: Scrobble(
                trackName: "Levitating",
                artistName: "Dua Lipa",
                albumName: "Future Nostalgia",
                timestamp: Date().addingTimeInterval(-7200),
                status: .failed("Network error")
            )
        )
    }
}

