//
//  DesignSystem.swift
//  FrameExtractionTool
//
//  Design tokens for the app. Everything here is deliberately semantic: text
//  styles rather than point sizes, system materials rather than hand-built
//  translucency, and animation that can be switched off.
//

import SwiftUI
import UIKit

enum AppTheme {

    // MARK: - Spacing (4 pt grid)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner radius

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Typography
    //
    // Uses text styles, so every label follows the Dynamic Type setting
    // (HIG › Typography › Supporting Dynamic Type).

    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title, design: .rounded).weight(.bold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }

    // MARK: - Motion
    //
    // Every animation goes through here so Reduce Motion can turn it off
    // (HIG › Accessibility › Motion).

    enum Motion {
        static func springy(_ reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .snappy(duration: 0.3, extraBounce: 0.05)
        }

        static func quick(_ reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeInOut(duration: 0.2)
        }
    }

    // MARK: - Sizes

    /// Minimum hit region for any control.
    /// HIG › Buttons › Best practices: "a button needs a hit region of at least 44x44 pt".
    static let minimumHitTarget: CGFloat = 44
}

// MARK: - Press state

/// Adds the press state every tappable custom surface needs
/// (HIG › Buttons › Best practices: "Always include a press state for a custom button").
struct PressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Haptics

/// Haptics that respect the user's preference in Settings.
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard AppSettings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard AppSettings.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Helpers

extension View {
    /// Expands a small icon to a full 44×44 pt hit target without changing its look.
    func minimumHitTarget(_ size: CGFloat = AppTheme.minimumHitTarget) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }
}
