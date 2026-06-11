//
//  SettingsView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//  Redesigned with Liquid Glass by Claude on 11/6/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingOnboarding = false
    @State private var hapticFeedback = UserDefaults.standard.object(forKey: "hapticFeedback") == nil ? true : UserDefaults.standard.bool(forKey: "hapticFeedback")
    @State private var useCustomAlbum = UserDefaults.standard.bool(forKey: "useCustomAlbum")
    @State private var customAlbumName = UserDefaults.standard.string(forKey: "customAlbumName") ?? "Frame Extractor"
    @State private var showingAlbumNameAlert = false

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.2),
                    Color.pink.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 100)

            ScrollView {
                VStack(spacing: LiquidGlass.Spacing.lg) {
                    // Header
                    VStack(spacing: LiquidGlass.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(LiquidGlass.Colors.primary.gradient)
                                .frame(width: 80, height: 80)

                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, LiquidGlass.Spacing.xl)

                        Text("Settings")
                            .font(LiquidGlass.Typography.largeTitle)
                            .fontWeight(.bold)

                        Text("Version 1.5.1")
                            .font(LiquidGlass.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Preferences Section
                    VStack(spacing: LiquidGlass.Spacing.md) {
                        SectionHeader(title: "Preferences")

                        VStack(spacing: LiquidGlass.Spacing.xs) {
                            SettingToggleRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Haptic Feedback",
                                description: "Feel subtle vibrations when marking frames",
                                isOn: $hapticFeedback,
                                color: .blue
                            )
                            .onChange(of: hapticFeedback) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "hapticFeedback")
                            }
                        }
                        .glassCard(cornerRadius: LiquidGlass.CornerRadius.lg, padding: LiquidGlass.Spacing.md)
                    }

                    // Photo Library Section
                    VStack(spacing: LiquidGlass.Spacing.md) {
                        SectionHeader(title: "Photo Library")

                        VStack(spacing: LiquidGlass.Spacing.xs) {
                            SettingToggleRow(
                                icon: "folder.fill",
                                title: "Custom Album",
                                description: "Save frames to a dedicated album",
                                isOn: $useCustomAlbum,
                                color: .purple
                            )
                            .onChange(of: useCustomAlbum) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "useCustomAlbum")
                            }

                            if useCustomAlbum {
                                Divider()
                                    .padding(.horizontal, LiquidGlass.Spacing.md)

                                Button {
                                    showingAlbumNameAlert = true
                                } label: {
                                    HStack(spacing: LiquidGlass.Spacing.sm) {
                                        Image(systemName: "textformat")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color.pink.gradient)
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Album Name")
                                                .font(LiquidGlass.Typography.body)
                                                .foregroundStyle(.primary)

                                            Text(customAlbumName)
                                                .font(LiquidGlass.Typography.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(LiquidGlass.Spacing.md)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .glassCard(cornerRadius: LiquidGlass.CornerRadius.lg, padding: 0)

                        if useCustomAlbum {
                            Text("Frames will be saved to '\(customAlbumName)'. The album will be created if it doesn't exist.")
                                .font(LiquidGlass.Typography.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, LiquidGlass.Spacing.md)
                                .transition(.opacity)
                        }
                    }

                    // Help & Support Section
                    VStack(spacing: LiquidGlass.Spacing.md) {
                        SectionHeader(title: "Help & Support")

                        VStack(spacing: LiquidGlass.Spacing.xs) {
                            SettingButtonRow(
                                icon: "questionmark.circle.fill",
                                title: "Tutorial",
                                description: "Learn how to use Frame Extractor",
                                color: .green
                            ) {
                                showingOnboarding = true
                            }

                            Divider()
                                .padding(.horizontal, LiquidGlass.Spacing.md)

                            Link(destination: URL(string: "https://developer.apple.com/documentation/avfoundation")!) {
                                HStack(spacing: LiquidGlass.Spacing.sm) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color.orange.gradient)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("About Video Processing")
                                            .font(LiquidGlass.Typography.body)
                                            .foregroundStyle(.primary)

                                        Text("Technical documentation")
                                            .font(LiquidGlass.Typography.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(LiquidGlass.Spacing.md)
                            }
                        }
                        .glassCard(cornerRadius: LiquidGlass.CornerRadius.lg, padding: 0)
                    }

                    // Footer
                    VStack(spacing: LiquidGlass.Spacing.xs) {
                        Text("Made with ❤️")
                            .font(LiquidGlass.Typography.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Following Apple's Design Guidelines")
                            .font(LiquidGlass.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, LiquidGlass.Spacing.lg)
                }
                .padding(.horizontal, LiquidGlass.Spacing.lg)
                .padding(.bottom, LiquidGlass.Spacing.xl)
            }

            // Close Button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                    }
                    .padding(.trailing, LiquidGlass.Spacing.lg)
                    .padding(.top, LiquidGlass.Spacing.md)
                }

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(showOnboarding: $showingOnboarding)
        }
        .alert("Album Name", isPresented: $showingAlbumNameAlert) {
            TextField("Album Name", text: $customAlbumName)
            Button("Save") {
                if !customAlbumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    UserDefaults.standard.set(customAlbumName, forKey: "customAlbumName")
                } else {
                    customAlbumName = "Frame Extractor"
                    UserDefaults.standard.set(customAlbumName, forKey: "customAlbumName")
                }
            }
            Button("Cancel", role: .cancel) {
                customAlbumName = UserDefaults.standard.string(forKey: "customAlbumName") ?? "Frame Extractor"
            }
        } message: {
            Text("Enter a name for the custom album where extracted frames will be saved.")
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(LiquidGlass.Typography.title3)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, LiquidGlass.Spacing.sm)
    }
}

// MARK: - Setting Toggle Row

struct SettingToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        HStack(spacing: LiquidGlass.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color.gradient)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LiquidGlass.Typography.body)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(LiquidGlass.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(LiquidGlass.Spacing.md)
    }
}

// MARK: - Setting Button Row

struct SettingButtonRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LiquidGlass.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color.gradient)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LiquidGlass.Typography.body)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(LiquidGlass.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(LiquidGlass.Spacing.md)
        }
    }
}

#Preview {
    SettingsView()
}
