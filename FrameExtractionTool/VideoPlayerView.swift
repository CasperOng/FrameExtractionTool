//
//  VideoPlayerView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI
import AVKit
import AVFoundation
import Combine

struct CustomVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity
    
    init(player: AVPlayer, videoGravity: AVLayerVideoGravity = .resizeAspectFill) {
        self.player = player
        self.videoGravity = videoGravity
    }
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        view.playerLayer.videoGravity = videoGravity
        return view
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.videoGravity = videoGravity
    }
}

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

enum VideoScale: CaseIterable, Identifiable {
    case percent50, percent60, percent70, percent80, percent90, fit, fill, percent110, percent120, percent130, percent140, percent150, percent160, percent170, percent180, percent190, percent200
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .percent50: return "50%"
        case .percent60: return "60%"
        case .percent70: return "70%"
        case .percent80: return "80%"
        case .percent90: return "90%"
        case .fit: return "Fit"
        case .fill: return "Fill"
        case .percent110: return "110%"
        case .percent120: return "120%"
        case .percent130: return "130%"
        case .percent140: return "140%"
        case .percent150: return "150%"
        case .percent160: return "160%"
        case .percent170: return "170%"
        case .percent180: return "180%"
        case .percent190: return "190%"
        case .percent200: return "200%"
        }
    }
    
    var scaleValue: CGFloat? {
        switch self {
        case .percent50: return 0.5
        case .percent60: return 0.6
        case .percent70: return 0.7
        case .percent80: return 0.8
        case .percent90: return 0.9
        case .fit: return nil // Will use aspectRatio fit
        case .fill: return -1 // Special case for fill
        case .percent110: return 1.1
        case .percent120: return 1.2
        case .percent130: return 1.3
        case .percent140: return 1.4
        case .percent150: return 1.5
        case .percent160: return 1.6
        case .percent170: return 1.7
        case .percent180: return 1.8
        case .percent190: return 1.9
        case .percent200: return 2.0
        }
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    @ObservedObject var videoManager: VideoManager
    let onDismiss: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: CMTime = .zero
    @State private var duration: CMTime = .zero
    @State private var showingExtractButton = false
    @State private var showingExtractionProgress = false
    @State private var showingHelp = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var videoScale: VideoScale = .fit
    @State private var showingScaleOptions = false
    @State private var showingDiscardAlert = false
    @State private var initialMarkedFramesCount = 0
    
    private var hasUnsavedChanges: Bool {
        return videoManager.markedFrames.count != initialMarkedFramesCount
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                
                // Video Player
                GeometryReader { geometry in
                    ZStack {
                        if let player = player {
                            if let scaleValue = videoScale.scaleValue {
                                if scaleValue == -1 {
                                    // Fill screen
                                    CustomVideoPlayerView(player: player, videoGravity: .resizeAspectFill)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                        .onTapGesture {
                                            togglePlayPause()
                                        }
                                        .animation(.easeInOut(duration: 0.3), value: videoScale)
                                } else {
                                    // Custom scale
                                    CustomVideoPlayerView(player: player, videoGravity: .resizeAspect)
                                        .frame(width: geometry.size.width * scaleValue, height: geometry.size.height * scaleValue)
                                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                        .clipped()
                                        .onTapGesture {
                                            togglePlayPause()
                                        }
                                        .animation(.easeInOut(duration: 0.3), value: videoScale)
                                }
                            } else {
                                // Fit to screen
                                CustomVideoPlayerView(player: player, videoGravity: .resizeAspect)
                                    .onTapGesture {
                                        togglePlayPause()
                                    }
                                    .animation(.easeInOut(duration: 0.3), value: videoScale)
                            }
                        }
                        
                        // Mark Frame Button Overlay
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    markCurrentFrame()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 56, height: 56)
                                .background(.blue, in: Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .padding(.trailing, 30)
                                .padding(.bottom, 30)
                            }
                        }
                    }
                }
                
                // Controls
                VStack(spacing: 20) {
                    // Timeline with marked frames
                    VideoTimelineView(
                        currentTime: currentTime,
                        duration: duration,
                        markedFrames: videoManager.markedFrames,
                        onSeek: { time in
                            player?.seek(to: time)
                        },
                        onRemoveFrame: { frameId in
                            videoManager.unmarkFrame(frameId: frameId)
                        }
                    )
                    .padding(.top, 8)
                    
                    // Play/Pause Controls
                    HStack(spacing: 30) {
                        Button {
                            seekBackward()
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        
                        Button {
                            togglePlayPause()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 64, height: 64)
                        .background(.ultraThinMaterial, in: Circle())
                        
                        Button {
                            seekForward()
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
                .background(.ultraThinMaterial.opacity(0.8))
            }
            .navigationTitle("Video Player (\(videoManager.markedFrames.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        if hasUnsavedChanges {
                            showingDiscardAlert = true
                        } else {
                            onDismiss()
                        }
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showingScaleOptions = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "viewfinder")
                                Text(videoScale.displayName)
                            }
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                        }
                        
                        Button {
                            showingHelp = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.white)
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    
                    if !videoManager.markedFrames.isEmpty {
                        Button("Extract Frames") {
                            showingExtractButton = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                }
            }
        }
        .onAppear {
            setupPlayer()
            initialMarkedFramesCount = videoManager.markedFrames.count
        }
        .onDisappear {
            player?.pause()
        }
        .confirmationDialog("Extract Frames", isPresented: $showingExtractButton) {
            Button("Extract \(videoManager.markedFrames.count) frames") {
                extractFrames()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let useCustomAlbum = UserDefaults.standard.bool(forKey: "useCustomAlbum")
            let customAlbumName = UserDefaults.standard.string(forKey: "customAlbumName") ?? "Frame Extractor"
            
            if useCustomAlbum {
                Text("This will save \(videoManager.markedFrames.count) frames to the '\(customAlbumName)' album in your photo library.")
            } else {
                Text("This will save \(videoManager.markedFrames.count) frames to your photo library.")
            }
        }
        .confirmationDialog("Discard Changes", isPresented: $showingDiscardAlert) {
            Button("Discard \(videoManager.markedFrames.count) marked frames", role: .destructive) {
                videoManager.clearMarkedFrames()
                onDismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have \(videoManager.markedFrames.count) marked frames that haven't been extracted. Do you want to discard them?")
        }
        .sheet(isPresented: $showingExtractionProgress) {
            ExtractionProgressView(videoManager: videoManager) {
                showingExtractionProgress = false
                onDismiss()
            }
        }
        .sheet(isPresented: $showingHelp) {
            FrameMarkingHelpView()
        }
        .sheet(isPresented: $showingScaleOptions) {
            VideoScaleOptionsView(selectedScale: $videoScale)
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
        
        // Observe time updates
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            currentTime = time
        }
        
        // Get duration
        Task {
            let asset = AVAsset(url: videoURL)
            duration = try await asset.load(.duration)
        }
        
        // Observe playing state
        player?.publisher(for: \.rate)
            .map { $0 > 0 }
            .sink { playing in
                isPlaying = playing
            }
            .store(in: &cancellables)
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: max(newTime, .zero))
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: min(newTime, duration))
    }
    
    private func markCurrentFrame() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        videoManager.markFrame(at: currentTime, player: player)
    }
    
    private func extractFrames() {
        showingExtractionProgress = true
        Task {
            try await videoManager.extractAllMarkedFrames()
        }
    }
}

struct VideoScaleOptionsView: View {
    @Binding var selectedScale: VideoScale
    @Environment(\.dismiss) private var dismiss
    
    private let presetScales: [VideoScale] = [.fit, .fill]
    private let percentageScales: [VideoScale] = [.percent50, .percent60, .percent70, .percent80, .percent90, .percent110, .percent120, .percent130, .percent140, .percent150, .percent160, .percent170, .percent180, .percent190, .percent200]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(presetScales) { scale in
                        ScaleOptionRow(scale: scale, selectedScale: $selectedScale) {
                            dismiss()
                        }
                    }
                } header: {
                    Text("Preset Options")
                } footer: {
                    Text("'Fit' maintains aspect ratio within screen bounds. 'Fill' scales to fill the entire screen.")
                }
                
                Section {
                    ForEach(percentageScales) { scale in
                        ScaleOptionRow(scale: scale, selectedScale: $selectedScale) {
                            dismiss()
                        }
                    }
                } header: {
                    Text("Custom Scale")
                } footer: {
                    Text("Choose a specific percentage to scale the video. Values over 100% may require scrolling.")
                }
            }
            .navigationTitle("Video Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ScaleOptionRow: View {
    let scale: VideoScale
    @Binding var selectedScale: VideoScale
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            selectedScale = scale
            onSelect()
        } label: {
            HStack {
                Text(scale.displayName)
                    .foregroundStyle(.primary)
                    .fontWeight(scale == selectedScale ? .semibold : .regular)
                
                Spacer()
                
                if scale == selectedScale {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
