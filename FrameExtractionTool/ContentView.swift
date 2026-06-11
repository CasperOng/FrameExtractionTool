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

    var body: some View {
        ZStack {
            // Clean background
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 12) {
                        // App Icon
                        Image(systemName: "play.rectangle.on.rectangle.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(.blue)
                            .symbolEffect(.bounce, value: showingVideoPlayer)

                        VStack(spacing: 4) {
                            Text("Frame Extractor")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("Extract frames from videos with precision")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 32)

                    // Main Actions Card
                    VStack(spacing: 12) {
                        // Primary Action
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingVideoPicker = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Choose Video")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .opacity(0.6)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Secondary Action
                        if !videoManager.extractedFrames.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingFrameLibrary = true
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 18, weight: .semibold))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("View Extracted Frames")
                                            .font(.system(size: 15, weight: .semibold))
                                        Text("\(videoManager.extractedFrames.count) frames")
                                            .font(.caption)
                                            .opacity(0.6)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .opacity(0.6)
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)

                    // Recent Frames Gallery
                    if !videoManager.extractedFrames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recently Extracted")
                                .font(.system(size: 17, weight: .semibold))
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(videoManager.extractedFrames.suffix(6), id: \.id) { frame in
                                        VStack(spacing: 0) {
                                            Image(uiImage: frame.image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                            Text(frame.originalMarkedFrame.timeString)
                                                .font(.caption2)
                                                .monospacedDigit()
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Quick Stats
                    if !videoManager.extractedFrames.isEmpty {
                        HStack(spacing: 12) {
                            StatTile(
                                icon: "photo.fill",
                                label: "Frames",
                                value: "\(videoManager.extractedFrames.count)"
                            )

                            StatTile(
                                icon: "checkmark.circle.fill",
                                label: "Success",
                                value: "100%"
                            )
                        }
                        .padding(.horizontal, 16)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 16)
            }

            // Settings Button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 40, height: 40)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }
                Spacer()
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
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.blue)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ContentView()
}
