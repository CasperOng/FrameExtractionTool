//
//  LiquidGlassDesign.swift
//  FrameExtractionTool
//
//  Created by Claude on 11/6/2026.
//

import SwiftUI

// MARK: - Liquid Glass Design System

/// Modern liquid glass design system with iOS 27 materials
struct LiquidGlass {

    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let accent = Color.cyan
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red

        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.gray
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }

    // MARK: - Animations
    struct Animation {
        static let springy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let fluid = SwiftUI.Animation.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.2)
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = LiquidGlass.CornerRadius.lg
    var padding: CGFloat = LiquidGlass.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
    }
}

// MARK: - Frosted Glass Modifier

struct FrostedGlass: ViewModifier {
    var material: Material = .ultraThinMaterial
    var cornerRadius: CGFloat = LiquidGlass.CornerRadius.md
    var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .opacity(opacity)
            }
    }
}

// MARK: - Liquid Button Style

struct LiquidButtonStyle: ButtonStyle {
    var isProminent: Bool = true
    var size: Size = .medium

    enum Size {
        case small, medium, large

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 17
            case .large: return 20
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
            .padding(size.padding)
            .frame(maxWidth: .infinity)
            .background {
                if isProminent {
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.md, style: .continuous)
                        .fill(LiquidGlass.Colors.primary.gradient)
                } else {
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .foregroundStyle(isProminent ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(LiquidGlass.Animation.springy, value: configuration.isPressed)
    }
}

// MARK: - Glass Icon Button

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 56
    var color: Color = LiquidGlass.Colors.primary

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(color.gradient)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var label: String? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))

                if let label = label {
                    Text(label)
                        .font(LiquidGlass.Typography.headline)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, label != nil ? 24 : 20)
            .padding(.vertical, 20)
            .background {
                Capsule()
                    .fill(LiquidGlass.Colors.primary.gradient)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Navigation Bar

struct GlassNavigationBar<Leading: View, Trailing: View>: View {
    let title: String
    let leading: Leading
    let trailing: Trailing

    init(title: String, @ViewBuilder leading: () -> Leading = { EmptyView() }, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            leading

            Spacer()

            Text(title)
                .font(LiquidGlass.Typography.headline)

            Spacer()

            trailing
        }
        .padding(.horizontal, LiquidGlass.Spacing.md)
        .padding(.vertical, LiquidGlass.Spacing.sm)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
            }
            .mask(content)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = LiquidGlass.CornerRadius.lg, padding: CGFloat = LiquidGlass.Spacing.md) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }

    func frostedGlass(material: Material = .ultraThinMaterial, cornerRadius: CGFloat = LiquidGlass.CornerRadius.md, opacity: Double = 1.0) -> some View {
        modifier(FrostedGlass(material: material, cornerRadius: cornerRadius, opacity: opacity))
    }

    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }

    func liquidScale(isPressed: Bool) -> some View {
        scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(LiquidGlass.Animation.springy, value: isPressed)
    }
}
