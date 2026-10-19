//
//  VideoPlayerView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import AVFoundation
import AVKit
import Combine
import SwiftUI

// MARK: - Player surface

/// An `AVPlayerLayer` without the system playback controls, so the app can put a
/// mark button and its own timeline over the video.
struct PlayerSurface: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.backgroundColor = .black
        view.player = player
        view.playerLayer.videoGravity = videoGravity
        return view
    }

    func updateUIView(_ view: PlayerLayerView, context: Context) {
        view.player = player
        view.playerLayer.videoGravity = videoGravity
    }
}

final class PlayerLayerView: UIView {
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override static var layerClass: AnyClass { AVPlayerLayer.self }
}

// MARK: - Scale

/// How much of the screen the video occupies.
enum VideoScale: Hashable, Identifiable, CaseIterable {
    case fit
    case fill
    case percent(Int)

    static let percentOptions = [50, 60, 70, 80, 90, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200]

    static var allCases: [VideoScale] {
        [.fit, .fill] + percentOptions.map { .percent($0) }
    }

    var id: Self { self }

    var title: String {
        switch self {
        case .fit: "Fit"
        case .fill: "Fill"
        case .percent(let value): "\(value)%"
        }
    }

    /// `nil` for the two presets, which are handled by the layer's gravity.
    var multiplier: CGFloat? {
        switch self {
        case .fit, .fill: nil
        case .percent(let value): CGFloat(value) / 100
        }
    }
}

// MARK: - Player

struct VideoPlayerView: View {

    let videoURL: URL
    let onDismiss: () -> Void

    @Environment(VideoManager.self) private var videoManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isMuted = false
    @State private var currentTime: CMTime = .zero
    @State private var duration: CMTime = .zero
    @State private var loadFailure: String?
    @State private var timeObserver: Any?

    @State private var videoScale: VideoScale = .fit
    @State private var playbackSpeed: Float = 1

    @State private var isShowingExtraction = false
    @State private var extractionTask: Task<Void, Never>?
    @State private var isShowingHelp = false
    @State private var isSuggestingDiscard = false
    @State private var markedFramesAtEntry = 0
    @State private var customSpeedText = ""
    @State private var isEnteringCustomSpeed = false

    private static let speedOptions: [Float] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

    private var markedCount: Int { videoManager.markedFrames.count }

    private var hasUnmarkedChanges: Bool {
        markedCount != markedFramesAtEntry
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    videoSurface
                    controlPanel
                        // Attached here rather than to the stack that hosts the
                        // other alerts, so each alert has its own presenter.
                        .alert(
                            "Photo Library Problem",
                            isPresented: Binding(
                                get: { videoManager.errorMessage != nil },
                                set: { if !$0 { videoManager.errorMessage = nil } }
                            ),
                            presenting: videoManager.errorMessage
                        ) { _ in
                            Button("OK", role: .cancel) {}
                        } message: { message in
                            Text(message)
                        }
                }
            }
            .navigationTitle(videoURL.deletingPathExtension().lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarContent }
        }
        // A player reads as a dark surface; the chrome and the loading/error
        // text follow the video rather than the light appearance of the app.
        .preferredColorScheme(.dark)
        .onAppear {
            startPlayback()
            markedFramesAtEntry = markedCount
        }
        .onDisappear {
            stopPlayback()
        }
        .onChange(of: scenePhase) { _, phase in
            // Leaving the app pauses the video rather than playing on unseen.
            if phase != .active { player?.pause() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            isPlaying = false
        }
        .sheet(isPresented: $isShowingExtraction) {
            ExtractionProgressView(
                onFinish: { leavePlayer in
                    isShowingExtraction = false
                    if leavePlayer { onDismiss() }
                },
                onCancel: { extractionTask?.cancel() }
            )
        }
        .sheet(isPresented: $isShowingHelp) {
            FrameMarkingHelpView()
                .presentationDetents([.medium, .large])
        }
        .alert("Custom Playback Speed", isPresented: $isEnteringCustomSpeed) {
            TextField("1.0×", text: $customSpeedText)
                .keyboardType(.decimalPad)
            Button("Set") { applyCustomSpeed() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a speed between 0.25× and 2×.")
        }
        .alert("Unmarked Your Frames?", isPresented: $isSuggestingDiscard) {
            Button("Discard \(markedCount) Marked Frames", role: .destructive) {
                videoManager.clearMarkedFrames()
                onDismiss()
            }
            Button("Keep Marking", role: .cancel) {}
        } message: {
            Text("These frames have not been extracted yet. Leaving now loses them.")
        }
    }

    // MARK: - Video

    @ViewBuilder
    private var videoSurface: some View {
        GeometryReader { geometry in
            ZStack {
                videoLayer(in: geometry.size)
                    .accessibilityHidden(true)

                if player != nil {
                    markButton
                }
            }
        }
    }

    @ViewBuilder
    private func videoLayer(in size: CGSize) -> some View {
        if let loadFailure {
            ContentUnavailableView {
                Label("Can’t Play This Video", systemImage: "exclamationmark.triangle")
            } description: {
                Text(loadFailure)
            }
        } else if let player {
            surface(for: player, in: size)
        } else {
            ProgressView()
                .tint(.white)
                .accessibilityLabel("Loading video")
        }
    }

    @ViewBuilder
    private func surface(for player: AVPlayer, in size: CGSize) -> some View {
        if let multiplier = videoScale.multiplier {
            PlayerSurface(player: player, videoGravity: .resizeAspect)
                .frame(width: size.width * multiplier, height: size.height * multiplier)
                .position(x: size.width / 2, y: size.height / 2)
                .clipped()
                .onTapGesture { togglePlayPause() }
        } else {
            PlayerSurface(player: player, videoGravity: videoScale == .fill ? .resizeAspectFill : .resizeAspect)
                .frame(width: size.width, height: size.height)
                .clipped()
                .onTapGesture { togglePlayPause() }
        }
    }

    private var markButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    videoManager.markFrame(at: player?.currentTime() ?? currentTime)
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.tint, in: .circle)
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Mark frame")
                .accessibilityHint("Adds the frame on screen to the frames to extract")
                .padding(AppTheme.Spacing.xl)
            }
        }
    }

    // MARK: - Controls

    private var controlPanel: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            VideoTimelineView(
                currentTime: currentTime,
                duration: duration,
                markedFrames: videoManager.markedFrames,
                onSeek: { seek(to: $0) },
                onRemoveMark: { videoManager.unmarkFrame(id: $0) }
            )

            HStack(spacing: AppTheme.Spacing.xxl) {
                transportButton(systemImage: "gobackward.10", label: "Back 10 seconds") {
                    skip(by: -10)
                }
                transportButton(
                    systemImage: isPlaying ? "pause.fill" : "play.fill",
                    label: isPlaying ? "Pause" : "Play",
                    size: 64
                ) {
                    togglePlayPause()
                }
                transportButton(systemImage: "goforward.10", label: "Forward 10 seconds") {
                    skip(by: 10)
                }
            }

            if markedCount > 0 {
                Button {
                    extractFrames()
                } label: {
                    Label("Extract \(markedCount) Frame\(markedCount == 1 ? "" : "s")", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Saves every marked frame to your photo library")
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(.bar)
        .animation(AppTheme.Motion.springy(reduceMotion), value: markedCount)
    }

    private func transportButton(
        systemImage: String,
        label: String,
        size: CGFloat = 48,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(.thickMaterial, in: .circle)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                attemptDismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Close video")
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                toggleMute()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }
            .accessibilityLabel(isMuted ? "Unmute" : "Mute")

            Menu {
                Menu("Playback Speed") {
                    ForEach(Self.speedOptions, id: \.self) { speed in
                        Toggle(Self.speedTitle(speed), isOn: Binding(
                            get: { abs(playbackSpeed - speed) < 0.01 },
                            set: { isOn in if isOn { setSpeed(speed) } }
                        ))
                    }
                    Divider()
                    Button("Custom Speed…") {
                        customSpeedText = String(format: "%.2f", playbackSpeed)
                        isEnteringCustomSpeed = true
                    }
                }

                Menu("Video Size") {
                    ForEach(VideoScale.allCases) { scale in
                        Toggle(scale.title, isOn: Binding(
                            get: { videoScale == scale },
                            set: { isOn in if isOn { videoScale = scale } }
                        ))
                    }
                }

                Divider()

                Button {
                    isShowingHelp = true
                } label: {
                    Label("How to Mark Frames", systemImage: "questionmark.circle")
                }
            } label: {
                Label("Playback options", systemImage: "slider.horizontal.3")
            }
        }
    }

    // MARK: - Playback

    private func startPlayback() {
        let player = AVPlayer(url: videoURL)
        player.defaultRate = playbackSpeed
        self.player = player

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { time in
            currentTime = time
            isPlaying = player.timeControlStatus == .playing
        }

        Task {
            let asset = AVURLAsset(url: videoURL)
            do {
                let (playable, assetDuration) = try await asset.load(.isPlayable, .duration)
                guard playable else {
                    loadFailure = "This file does not contain a video track that can be played."
                    return
                }
                duration = assetDuration.isNumeric ? assetDuration : .zero
            } catch {
                loadFailure = error.localizedDescription
            }
        }
    }

    private func stopPlayback() {
        player?.pause()
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        player = nil
    }

    private func togglePlayPause() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            if duration.isNumeric, player.currentTime() >= duration {
                player.seek(to: .zero)
            }
            player.play()
            isPlaying = true
        }
    }

    private func toggleMute() {
        guard let player else { return }
        player.isMuted.toggle()
        isMuted = player.isMuted
    }

    private func skip(by seconds: Double) {
        guard let player, duration.isNumeric else { return }
        let target = CMTimeAdd(player.currentTime(), CMTime(seconds: seconds, preferredTimescale: 600))
        seek(to: CMTimeMaximum(.zero, CMTimeMinimum(target, duration)))
    }

    private func seek(to time: CMTime) {
        guard let player, time.isNumeric else { return }
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }

    private func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        guard let player else { return }
        player.defaultRate = speed
        // Keep playing at the new speed; do not start playback if it is paused.
        if player.timeControlStatus == .playing {
            player.rate = speed
        }
    }

    private func applyCustomSpeed() {
        let normalized = customSpeedText
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "×", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let speed = Float(normalized), (0.25...2).contains(speed) else { return }
        setSpeed(speed)
    }

    private static func speedTitle(_ speed: Float) -> String {
        var text = String(format: "%.2f", speed)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text + "×"
    }

    // MARK: - Actions

    private func attemptDismiss() {
        if hasUnmarkedChanges {
            isSuggestingDiscard = true
        } else {
            onDismiss()
        }
    }

    private func extractFrames() {
        isShowingExtraction = true
        extractionTask = Task { await videoManager.extractMarkedFrames() }
    }
}

#Preview {
    VideoPlayerView(videoURL: URL(fileURLWithPath: "/dev/null")) {}
        .environment(VideoManager())
}
