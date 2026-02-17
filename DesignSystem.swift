import SwiftUI

/// Centralized design system for consistent UI across the app
struct DesignSystem {
    
    // MARK: - Typography (Dynamic Type support)
    struct Typography {
        // Use relative text styles so fonts scale with accessibility settings
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title, design: .rounded, weight: .bold)
        static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
        static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
        static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let callout = Font.system(.callout, design: .default, weight: .regular)
        static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
        static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .medium)
        static let captionBold = Font.system(.caption2, design: .rounded, weight: .bold)
    }
    
    // MARK: - Colors (System-adaptive)
    struct Colors {
        // Brand colors
        static let primary = Color(hue: 0.58, saturation: 0.75, brightness: 0.95) // Vibrant blue
        static let primaryDark = Color(hue: 0.58, saturation: 0.85, brightness: 0.75)
        static let accent = Color(hue: 0.78, saturation: 0.65, brightness: 0.95) // Purple accent
        static let secondary = Color.secondary
        
        // Backgrounds
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        // Gradient backgrounds
        static let cardGradientStart = Color(hue: 0.58, saturation: 0.08, brightness: 0.98)
        static let cardGradientEnd = Color(hue: 0.72, saturation: 0.06, brightness: 0.96)
        
        // Labels
        static let label = Color(.label)
        static let secondaryLabel = Color(.secondaryLabel)
        static let tertiaryLabel = Color(.tertiaryLabel)
        
        static let separator = Color(.separator)
        
        // Semantic colors
        static let recordButton = Color(hue: 0.0, saturation: 0.75, brightness: 0.95)
        static let success = Color(hue: 0.38, saturation: 0.7, brightness: 0.8)
        static let warning = Color(hue: 0.08, saturation: 0.8, brightness: 0.95)
        static let keywordHighlight = Color(hue: 0.14, saturation: 0.3, brightness: 1.0)
        
        // Tag/badge colors
        static let tagBackground = Color(hue: 0.58, saturation: 0.12, brightness: 0.95)
        static let tagText = Color(hue: 0.58, saturation: 0.8, brightness: 0.6)
        
        // Glass effect colors (adaptive)
        static let glassTint = Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor.systemGray6.withAlphaComponent(0.2) : 
                UIColor.white.withAlphaComponent(0.55)
        })
        
        static let glassBorder = Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor.white.withAlphaComponent(0.1) : 
                UIColor.white.withAlphaComponent(0.3)
        })
        
        static let searchBarBackground = Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor.systemGray5.withAlphaComponent(0.4) : 
                UIColor.white.withAlphaComponent(0.85)
        })
        
        static let transcriptBackground = Color(UIColor.secondarySystemGroupedBackground)
        
        static let homeGradientStart = Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(hue: 0.58, saturation: 0.75, brightness: 0.95, alpha: 0.50) // Increased opacity for darker feel
            } else {
                // Darker, richer blue for light mode
                return UIColor(hue: 0.58, saturation: 0.85, brightness: 0.70, alpha: 0.95) // Darker brightness, higher alpha
            }
        })
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let xxlarge: CGFloat = 28
        static let circle: CGFloat = 1000
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.6)
    }
    
    // MARK: - Shadow
    struct Shadow {
        static let small = (radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
}

// MARK: - View Extensions for Design System
extension View {
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(color: Color.black.opacity(0.06),
                   radius: DesignSystem.Shadow.small.radius,
                   x: DesignSystem.Shadow.small.x,
                   y: DesignSystem.Shadow.small.y)
    }
    
    func premiumCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .fill(DesignSystem.Colors.glassTint)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .stroke(DesignSystem.Colors.glassBorder, lineWidth: 0.5)
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.callout)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.primary.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.small)
    }
    
    func tagStyle() -> some View {
        self
            .font(DesignSystem.Typography.captionBold)
            .foregroundColor(DesignSystem.Colors.tagText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignSystem.Colors.tagBackground)
            .cornerRadius(6)
    }
}
