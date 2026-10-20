//
//  ContentView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import PhotosUI
import SwiftUI

struct ContentView: View {

    @Environment(VideoManager.self) private var videoManager
    @Environment(IncomingVideoHandler.self) private var incoming
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    private enum Route: Hashable {
        case library
        case settings
    }

    @State private var path: [Route] = []
    @State private var pickedVideo: PhotosPickerItem?
    @State private var isChoosingVideo = false
    @State private var isShowingPlayer = false
    @State private var isImportingPick = false
    @State private var isShowingTutorial = !UserDefaults.standard.bool(forKey: AppSettings.Key.hasSeenOnboarding)
    /// A hand-off that arrived while the tutorial was on screen.
    @State private var videoAwaitingTutorialDismissal: URL?

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Frame Extractor")
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .library: FrameLibraryView()
                    case .settings: SettingsView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            path.append(.settings)
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isChoosingVideo = true
                        } label: {
                            Label("Choose Video", systemImage: "video.badge.plus")
                        }
                    }
                }
        }
        .photosPicker(isPresented: $isChoosingVideo, selection: $pickedVideo, matching: .videos)
        .onChange(of: pickedVideo) { _, item in
            importPicked(item)
        }
        .fullScreenCover(isPresented: $isShowingPlayer, onDismiss: { incoming.consumeReadyVideo() }) {
            if let videoURL = videoManager.selectedVideoURL {
                VideoPlayerView(videoURL: videoURL) {
                    isShowingPlayer = false
                }
                // A video handed over while the player is open replaces it.
                .id(videoURL)
            }
        }
        .fullScreenCover(isPresented: $isShowingTutorial, onDismiss: {
            markOnboardingSeen()
            presentPendingVideo()
        }) {
            OnboardingView { isShowingTutorial = false }
        }
        .overlay { importOverlay }
        .task {
            // Videos the share extension filed while the app was not running.
            await incoming.importSharedVideos()
        }
        .onChange(of: scenePhase) { _, phase in
            // Sharing happens in another app, so the app is usually already
            // running when its share extension has something to hand over.
            guard phase == .active else { return }
            Task { await incoming.importSharedVideos() }
        }
        .onChange(of: incoming.readyVideoURL) { _, url in
            open(url)
        }
        .onAppear {
            // A hand-off that arrived while the app was launching.
            open(incoming.readyVideoURL)
        }
        .alert(
            "Couldn’t Open Video",
            isPresented: Binding(
                get: { if case .failed = incoming.state { return true } else { return false } },
                set: { if !$0 { incoming.dismissFailure() } }
            )
        ) {
            Button("OK", role: .cancel) { incoming.dismissFailure() }
        } message: {
            if case .failed(let message) = incoming.state {
                Text(message)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if videoManager.extractedFrames.isEmpty {
            emptyState
        } else {
            librarySummary
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            ContentUnavailableView {
                Label("No Frames Yet", systemImage: "play.rectangle.on.rectangle")
            } description: {
                Text("Choose a video from your library to mark frames, or share a video to Frame Extractor from another app.")
            } actions: {
                Button {
                    isChoosingVideo = true
                } label: {
                    Text("Choose Video")
                        .frame(maxWidth: 240)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            // The developer credit sits where the app is first seen, as it does
            // on casperong.is-a.dev and in the Visitor Connect apps. At the
            // largest text sizes there is no room left for it on this screen, so
            // it stays reachable in Settings instead of crowding the controls.
            if !dynamicTypeSize.isAccessibilitySize {
                DeveloperCreditView(signatureWidth: 140)
                    .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
    }

    private var librarySummary: some View {
        List {
            Section {
                Button {
                    path.append(.library)
                } label: {
                    LabeledContent {
                        Text(videoManager.extractedFrames.count.formatted())
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Extracted Frames", systemImage: "photo.stack")
                    }
                }

                Button {
                    isChoosingVideo = true
                } label: {
                    Label("Choose Another Video", systemImage: "video.badge.plus")
                }
            }

            Section("Recently Extracted") {
                ScrollView(.horizontal) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        ForEach(videoManager.extractedFrames.suffix(6).reversed()) { frame in
                            Button {
                                path.append(.library)
                            } label: {
                                VStack(spacing: AppTheme.Spacing.xs) {
                                    Image(uiImage: frame.thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 96, height: 96)
                                        .clipShape(.rect(cornerRadius: AppTheme.CornerRadius.md))
                                    Text(frame.timeString)
                                        .font(AppTheme.Typography.caption2)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(PressableButtonStyle())
                            .accessibilityLabel("Frame at \(frame.originalMarkedFrame.accessibilityTimeString)")
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Import progress

    @ViewBuilder
    private var importOverlay: some View {
        if incoming.state.isImporting || isImportingPick {
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.lg) {
                    ProgressView()
                        .controlSize(.large)
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("Preparing Video")
                            .font(AppTheme.Typography.headline)
                        if let name = incoming.pendingName {
                            Text(name)
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                .padding(AppTheme.Spacing.xl)
                .background(.regularMaterial, in: .rect(cornerRadius: AppTheme.CornerRadius.xl))
                .padding(AppTheme.Spacing.xxl)
                .accessibilityElement(children: .combine)
            }
            .transition(.opacity)
        }
    }

    // MARK: - Actions

    private func open(_ url: URL?) {
        guard let url else { return }
        incoming.consumeReadyVideo()
        videoManager.selectVideo(url: url)

        // One modal at a time: hand the video to the player once the tutorial
        // has finished dismissing (HIG › Modality).
        if isShowingTutorial {
            videoAwaitingTutorialDismissal = url
        } else {
            isShowingPlayer = true
        }
    }

    private func presentPendingVideo() {
        guard let url = videoAwaitingTutorialDismissal else { return }
        videoAwaitingTutorialDismissal = nil
        videoManager.selectVideo(url: url)
        isShowingPlayer = true
    }

    private func importPicked(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            isImportingPick = true
            defer {
                isImportingPick = false
                pickedVideo = nil
            }
            do {
                let url = try await VideoImporter.importPicked(item)
                open(url)
            } catch {
                incoming.reportFailure(error.localizedDescription)
            }
        }
    }

    private func markOnboardingSeen() {
        UserDefaults.standard.set(true, forKey: AppSettings.Key.hasSeenOnboarding)
    }
}

#Preview {
    ContentView()
        .environment(VideoManager())
        .environment(IncomingVideoHandler())
}
