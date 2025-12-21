import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: Theme.Spacing.md) {
                // App icon
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.accentGreen,
                                    Theme.Colors.accentGreen.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "music.note.square.stack.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: Theme.Colors.accentGreen.opacity(0.3), radius: 16, x: 0, y: 8)
                
                VStack(spacing: Theme.Spacing.sm) {
                    Text("ScrobbleSync")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Colors.primaryText)
                    
                    Text("Automatically scrobble your\nApple Music to Last.fm")
                        .font(.body)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.bottom, Theme.Spacing.huge)
            
            // Connection cards
            VStack(spacing: Theme.Spacing.md) {
                ConnectionCard(
                    title: "Apple Music",
                    subtitle: appState.appleMusicStatusDescription,
                    systemImage: "music.note",
                    isConnected: appState.appleMusicConnected,
                    isLoading: appState.isConnectingAppleMusic,
                    accentColor: Theme.Colors.appleMusicPink
                ) {
                    if !appState.appleMusicConnected {
                        Task {
                            await appState.connectAppleMusic()
                        }
                    }
                }
                
                ConnectionCard(
                    title: "Last.fm",
                    subtitle: appState.lastfmConnected ? "@\(appState.lastfmUsername)" : "Tap to connect",
                    systemImage: "antenna.radiowaves.left.and.right",
                    isConnected: appState.lastfmConnected,
                    accentColor: Theme.Colors.lastfmRed
                ) {
                    if appState.lastfmConnected {
                        appState.disconnectLastfm()
                    } else {
                        appState.connectLastfm()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            
            Spacer()
            
            // Get Started button
            VStack(spacing: Theme.Spacing.md) {
                Button {
                    appState.completeOnboarding()
                } label: {
                    Text(appState.canGetStarted ? "Get Started" : "Connect services to continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous)
                                .fill(appState.canGetStarted ? Theme.Colors.accentGreen : Theme.Colors.accentGreen.opacity(0.4))
                        )
                }
                .disabled(!appState.canGetStarted)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: appState.canGetStarted)
                
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxxl)
        }
        .background(Theme.Colors.background)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(appState: AppState())
}

