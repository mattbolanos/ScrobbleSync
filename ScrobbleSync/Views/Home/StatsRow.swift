import SwiftUI

// MARK: - Stats Row

struct StatsRow: View {
    let todayCount: Int
    let weekCount: Int
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatItem(
                title: "Today",
                value: todayCount,
                systemImage: "calendar"
            )
            
            StatItem(
                title: "This Week",
                value: weekCount,
                systemImage: "chart.bar.fill"
            )
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: Int
    let systemImage: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentGreen.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accentGreen)
            }
            
            // Text
            VStack(alignment: .leading, spacing: Theme.Spacing.xxxs) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .contentTransition(.numericText())
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    StatsRow(todayCount: 12, weekCount: 84)
        .padding()
        .background(Theme.Colors.background)
}

