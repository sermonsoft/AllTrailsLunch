//
//  DesignSystem.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 31/10/25.
//

import SwiftUI

enum DesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        // Primary AllTrails green
        static let primary = Color(red: 66/255, green: 135/255, blue: 52/255)
        static let primaryDark = Color(red: 52/255, green: 107/255, blue: 41/255)
        
        // Accent colors
        static let accent = Color(red: 255/255, green: 107/255, blue: 0/255)
        
        // Text colors
        static let textPrimary = Color(red: 33/255, green: 33/255, blue: 33/255)
        static let textSecondary = Color(red: 117/255, green: 117/255, blue: 117/255)
        static let textTertiary = Color(red: 158/255, green: 158/255, blue: 158/255)
        
        // Background colors
        static let background = Color(red: 250/255, green: 250/255, blue: 250/255)
        static let cardBackground = Color.white
        static let searchBackground = Color(red: 242/255, green: 242/255, blue: 242/255)
        
        // Border colors
        static let border = Color(red: 229/255, green: 229/255, blue: 229/255)
        
        // Status colors
        static let success = Color(red: 66/255, green: 135/255, blue: 52/255)
        static let warning = Color(red: 255/255, green: 152/255, blue: 0/255)
        static let error = Color(red: 255/255, green: 59/255, blue: 48/255)
        
        // Rating star
        static let star = Color(red: 255/255, green: 204/255, blue: 0/255)
        
        // Favorite heart
        static let favorite = Color(red: 255/255, green: 45/255, blue: 85/255)
    }
    
    // MARK: - Typography

    enum Typography {
        // Headings
        static let h1 = Font.custom("Manrope-Bold", size: 28)
        static let h2 = Font.custom("Manrope-Bold", size: 22)
        static let h3 = Font.custom("Manrope-SemiBold", size: 18)

        // Body text
        static let body = Font.custom("Manrope-Regular", size: 16)
        static let bodyBold = Font.custom("Manrope-SemiBold", size: 16)

        // Small text
        static let caption = Font.custom("Manrope-Regular", size: 14)
        static let captionBold = Font.custom("Manrope-SemiBold", size: 14)

        // Tiny text
        static let footnote = Font.custom("Manrope-Regular", size: 12)
        static let footnoteBold = Font.custom("Manrope-SemiBold", size: 12)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 100
    }
    
    // MARK: - Shadows
    
    enum Shadows {
        static let card = Shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let cardHover = Shadow(
            color: Color.black.opacity(0.12),
            radius: 12,
            x: 0,
            y: 4
        )
        
        static let modal = Shadow(
            color: Color.black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Icon Sizes

    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
}

// MARK: - View Extensions

extension View {
    /// Apply card styling with shadow
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .shadow(
                color: DesignSystem.Shadows.card.color,
                radius: DesignSystem.Shadows.card.radius,
                x: DesignSystem.Shadows.card.x,
                y: DesignSystem.Shadows.card.y
            )
    }
    
    /// Apply search bar styling
    func searchBarStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.searchBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

