//
//  FrameLibraryView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//  Redesigned with Liquid Glass by Claude on 11/6/2026.
//

import SwiftUI

struct FrameLibraryView: View {
    @ObservedObject var videoManager: VideoManager
    @Environment(\.dismiss) private var dismiss
    @State private var isSelecting = false
    @State private var selectedFrames: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    @State private var frameToDelete: ExtractedFrame?

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.2),
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 100)

            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    if isSelecting {
                        Button("Cancel") {
                            cancelSelection()
                        }
                        .font(LiquidGlass.Typography.body)
                        .foregroundStyle(LiquidGlass.Colors.primary)
                    }

                    Spacer()

                    Text(isSelecting ? "\(selectedFrames.count) Selected" : "Library")
                        .font(LiquidGlass.Typography.headline)

                    Spacer()

                    HStack(spacing: LiquidGlass.Spacing.sm) {
                        if !videoManager.extractedFrames.isEmpty {
                            Button(isSelecting ? "Delete" : "Select") {
                                if isSelecting {
                                    deleteSelectedFrames()
                                } else {
                                    startSelection()
                                }
                            }
                            .font(LiquidGlass.Typography.body)
                            .foregroundStyle(isSelecting ? (selectedFrames.isEmpty ? .secondary : LiquidGlass.Colors.danger) : LiquidGlass.Colors.primary)
                            .disabled(isSelecting && selectedFrames.isEmpty)
                        }

                        if !isSelecting {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 32, height: 32)
                                    .background {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, LiquidGlass.Spacing.lg)
                .padding(.vertical, LiquidGlass.Spacing.md)
                .background {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                }

                // Content
                if videoManager.extractedFrames.isEmpty {
                    EmptyLibraryView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(videoManager.extractedFrames.reversed()) { frame in
                                GlassFrameThumbnail(
                                    frame: frame,
                                    isSelecting: isSelecting,
                                    isSelected: selectedFrames.contains(frame.id),
                                    onSelect: { toggleSelection(for: frame) },
                                    onDelete: { deleteFrame(frame) }
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(LiquidGlass.Spacing.lg)
                        .animation(LiquidGlass.Animation.springy, value: videoManager.extractedFrames.count)
                    }
                }
            }
        }
        .alert("Delete Frame", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let frame = frameToDelete {
                    withAnimation(LiquidGlass.Animation.springy) {
                        videoManager.deleteExtractedFrame(frame)
                    }
                    frameToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                frameToDelete = nil
            }
        } message: {
            Text("This will permanently delete the frame from your photo library.")
        }
    }

    private func toggleSelection(for frame: ExtractedFrame) {
        withAnimation(LiquidGlass.Animation.quick) {
            if selectedFrames.contains(frame.id) {
                selectedFrames.remove(frame.id)
            } else {
                selectedFrames.insert(frame.id)
            }
        }
    }

    private func startSelection() {
        withAnimation(LiquidGlass.Animation.springy) {
            isSelecting = true
            selectedFrames.removeAll()
        }
    }

    private func cancelSelection() {
        withAnimation(LiquidGlass.Animation.springy) {
            isSelecting = false
            selectedFrames.removeAll()
        }
    }

    private func deleteFrame(_ frame: ExtractedFrame) {
        frameToDelete = frame
        showingDeleteConfirmation = true
    }

    private func deleteSelectedFrames() {
        let framesToDelete = videoManager.extractedFrames.filter { selectedFrames.contains($0.id) }
        withAnimation(LiquidGlass.Animation.springy) {
            videoManager.deleteExtractedFrames(framesToDelete)
        }
        cancelSelection()
    }
}

// MARK: - Empty Library View

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: LiquidGlass.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LiquidGlass.Colors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.stack")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(LiquidGlass.Colors.primary.gradient)
            }

            VStack(spacing: LiquidGlass.Spacing.xs) {
                Text("No Frames Yet")
                    .font(LiquidGlass.Typography.title2)
                    .fontWeight(.bold)

                Text("Extract frames from videos\nto see them here")
                    .font(LiquidGlass.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Glass Frame Thumbnail

struct GlassFrameThumbnail: View {
    let frame: ExtractedFrame
    let isSelecting: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var showingFullScreen = false

    var body: some View {
        Button {
            if isSelecting {
                onSelect()
            } else {
                showingFullScreen = true
            }
        } label: {
            ZStack {
                // Frame Image
                Image(uiImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.lg, style: .continuous))

                // Time Badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text(frame.originalMarkedFrame.timeString)
                                .font(LiquidGlass.Typography.caption)
                                .monospacedDigit()
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(.ultraThinMaterial)
                        }
                        .padding(8)
                    }
                }

                // Selection Overlay
                if isSelecting {
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.lg, style: .continuous)
                        .strokeBorder(isSelected ? LiquidGlass.Colors.primary : Color.white.opacity(0.3), lineWidth: 3)
                        .background(
                            RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.lg, style: .continuous)
                                .fill(isSelected ? LiquidGlass.Colors.primary.opacity(0.3) : .clear)
                        )

                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(isSelected ? LiquidGlass.Colors.primary : .white)
                                .background {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 24, height: 24)
                                }
                                .padding(12)
                        }
                        Spacer()
                    }
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            if !isSelecting {
                onDelete()
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            GlassFullScreenImageView(image: frame.image, timeString: frame.originalMarkedFrame.timeString) {
                showingFullScreen = false
            }
        }
    }
}

// MARK: - Glass Full Screen Image View

struct GlassFullScreenImageView: View {
    let image: UIImage
    let timeString: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1.0, min(lastScale * value.magnitude, 4.0))
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1.2 {
                                    withAnimation(LiquidGlass.Animation.springy) {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                }
                            },
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = value.translation
                                }
                            }
                            .onEnded { _ in
                                if scale <= 1.0 {
                                    withAnimation(LiquidGlass.Animation.springy) {
                                        offset = .zero
                                    }
                                }
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation(LiquidGlass.Animation.springy) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                        } else {
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }

            // Top Bar
            VStack {
                HStack {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(timeString)
                            .font(LiquidGlass.Typography.subheadline)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                }
                .padding(LiquidGlass.Spacing.lg)

                Spacer()
            }
        }
    }
}

#Preview {
    FrameLibraryView(videoManager: VideoManager())
}
