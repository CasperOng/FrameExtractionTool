//
//  ContentView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//  Redesigned with Liquid Glass by Claude on 11/6/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()
    @State private var showingVideoPicker = false
    @State private var showingVideoPlayer = false
    @State private var showingFrameLibrary = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showingSettings = false
    @State private var isProcessingSharedVideo = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.cyan.opacity(0.2),
                    Color.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 100)

            ScrollView {
                VStack(spacing: LiquidGlass.Spacing.lg) {
                    // Header Section
                    VStack(spacing: LiquidGlass.Spacing.md) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(LiquidGlass.Colors.primary.gradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: LiquidGlass.Colors.primary.opacity(0.4), radius: 20, x: 0, y: 10)

                            Image(systemName: "play.rectangle.on.rectangle.fill")
                                .font(.system(size: 50, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: showingVideoPlayer)
                        }
                        .padding(.top, LiquidGlass.Spacing.xl)

                        VStack(spacing: LiquidGlass.Spacing.xxs) {
                            Text("Frame Extractor")
                                .font(LiquidGlass.Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Text("Capture perfect moments from your videos")
                                .font(LiquidGlass.Typography.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.lg)

                    // Main Actions Card
                    VStack(spacing: LiquidGlass.Spacing.md) {
                        // Primary Action
                        Button {
                            withAnimation(LiquidGlass.Animation.springy) {
                                showingVideoPicker = true
                            }
                        } label: {
                            HStack(spacing: LiquidGlass.Spacing.sm) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Choose Video")
                                    .font(LiquidGlass.Typography.headline)
                            }
                        }
                        .buttonStyle(LiquidButtonStyle(isProminent: true, size: .large))

                        // Secondary Action
                        if !videoManager.extractedFrames.isEmpty {
                            Button {
                                withAnimation(LiquidGlass.Animation.springy) {
                                    showingFrameLibrary = true
                                }
                            } label: {
                                HStack(spacing: LiquidGlass.Spacing.sm) {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("View \(videoManager.extractedFrames.count) Extracted Frames")
                                        .font(LiquidGlass.Typography.body)
                                }
                            }
                            .buttonStyle(LiquidButtonStyle(isProminent: false, size: .medium))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .glassCard(cornerRadius: LiquidGlass.CornerRadius.xl, padding: LiquidGlass.Spacing.lg)
                    .padding(.horizontal, LiquidGlass.Spacing.lg)

                    // Recent Frames Gallery
                    if !videoManager.extractedFrames.isEmpty {
                        VStack(alignment: .leading, spacing: LiquidGlass.Spacing.md) {
                            HStack {
                                Text("Recently Extracted")
                                    .font(LiquidGlass.Typography.title3)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    showingFrameLibrary = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("View All")
                                            .font(LiquidGlass.Typography.subheadline)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundStyle(LiquidGlass.Colors.primary)
                                }
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: LiquidGlass.Spacing.sm) {
                                    ForEach(videoManager.extractedFrames.suffix(8), id: \.id) { frame in
                                        RecentFrameThumbnail(frame: frame)
                                    }
                                }
                            }
                        }
                        .glassCard(cornerRadius: LiquidGlass.CornerRadius.xl, padding: LiquidGlass.Spacing.lg)
                        .padding(.horizontal, LiquidGlass.Spacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Quick Stats Card (if frames exist)
                    if !videoManager.extractedFrames.isEmpty {
                        HStack(spacing: LiquidGlass.Spacing.lg) {
                            StatCard(
                                icon: "photo.fill",
                                value: "\(videoManager.extractedFrames.count)",
                                label: "Frames"
                            )

                            StatCard(
                                icon: "checkmark.circle.fill",
                                value: "100%",
                                label: "Success"
                            )
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.lg)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 80)
                }
                .padding(.bottom, LiquidGlass.Spacing.xl)
            }

            // Floating Settings Button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                    }
                    .padding(.trailing, LiquidGlass.Spacing.lg)
                    .padding(.top, LiquidGlass.Spacing.md)
                }

                Spacer()
            }

            // Processing Overlay
            if isProcessingSharedVideo {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    VStack(spacing: LiquidGlass.Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Loading video...")
                            .font(LiquidGlass.Typography.headline)
                            .foregroundStyle(.white)
                    }
                    .glassCard(cornerRadius: LiquidGlass.CornerRadius.xl, padding: LiquidGlass.Spacing.xl)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView(videoManager: videoManager) {
                showingVideoPicker = false
                showingVideoPlayer = true
            }
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let videoURL = videoManager.selectedVideoURL {
                VideoPlayerView(videoURL: videoURL, videoManager: videoManager) {
                    showingVideoPlayer = false
                }
            }
        }
        .sheet(isPresented: $showingFrameLibrary) {
            FrameLibraryView(videoManager: videoManager)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            checkForSharedVideo()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                checkForSharedVideo()
            }
        }
    }

    private func checkForSharedVideo() {
        guard !isProcessingSharedVideo else { return }
        guard SharedDataManager.shared.hasPendingVideo(),
              let videoURL = SharedDataManager.shared.getPendingVideoURL() else {
            return
        }

        withAnimation(LiquidGlass.Animation.smooth) {
            isProcessingSharedVideo = true
        }

        Task {
            do {
                try await videoManager.selectSharedVideo(url: videoURL)
                try? SharedDataManager.shared.cleanupSharedVideos()
                try? await Task.sleep(nanoseconds: 500_000_000)

                await MainActor.run {
                    withAnimation(LiquidGlass.Animation.smooth) {
                        isProcessingSharedVideo = false
                        showingVideoPlayer = true
                    }
                }
            } catch {
                print("Failed to load shared video: \(error)")
                await MainActor.run {
                    withAnimation(LiquidGlass.Animation.smooth) {
                        isProcessingSharedVideo = false
                    }
                    SharedDataManager.shared.clearPendingVideo()
                }
            }
        }
    }
}

// MARK: - Recent Frame Thumbnail

struct RecentFrameThumbnail: View {
    let frame: ExtractedFrame

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: frame.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.md, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Text(frame.originalMarkedFrame.timeString)
                        .font(LiquidGlass.Typography.caption)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(.ultraThinMaterial)
                        }
                        .padding(8)
                }
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: LiquidGlass.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(LiquidGlass.Colors.primary.gradient)

            Text(value)
                .font(LiquidGlass.Typography.title2)
                .fontWeight(.bold)

            Text(label)
                .font(LiquidGlass.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: LiquidGlass.CornerRadius.lg, padding: LiquidGlass.Spacing.md)
    }
}

#Preview {
    ContentView()
}
