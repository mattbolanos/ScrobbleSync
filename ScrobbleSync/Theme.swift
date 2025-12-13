import SwiftUI

// MARK: - Theme

enum Theme {
    // MARK: - Colors
    
    enum Colors {
        // Primary accent - green for success/connected states
        static let accent = Color("AccentColor")
        static let accentGreen = Color(red: 0.30, green: 0.78, blue: 0.47)
        
        // Error states
        static let error = Color(red: 0.94, green: 0.33, blue: 0.31)
        static let errorMuted = Color(red: 0.94, green: 0.33, blue: 0.31).opacity(0.15)
        
        // Warning/Pending states
        static let pending = Color(red: 1.0, green: 0.76, blue: 0.03)
        static let pendingMuted = Color(red: 1.0, green: 0.76, blue: 0.03).opacity(0.15)
        
        // Success states
        static let success = Color(red: 0.30, green: 0.78, blue: 0.47)
        static let successMuted = Color(red: 0.30, green: 0.78, blue: 0.47).opacity(0.15)
        
        // Backgrounds
        static let background = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
        
        // Text
        static let primaryText = Color(uiColor: .label)
        static let secondaryText = Color(uiColor: .secondaryLabel)
        static let tertiaryText = Color(uiColor: .tertiaryLabel)
        
        // Separators
        static let separator = Color(uiColor: .separator)
        
        // Card backgrounds with subtle tint
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        
        // Last.fm red
        static let lastfmRed = Color(red: 0.73, green: 0.04, blue: 0.04)
        
        // Apple Music gradient colors
        static let appleMusicPink = Color(red: 0.98, green: 0.18, blue: 0.47)
        static let appleMusicRed = Color(red: 0.89, green: 0.09, blue: 0.31)
    }
    
    // MARK: - Spacing (4pt grid)
    
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 100
    }
    
    // MARK: - Icon Sizes
    
    enum IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 44
        static let huge: CGFloat = 56
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
    }
    
    func cardStyleWithShadow() -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

