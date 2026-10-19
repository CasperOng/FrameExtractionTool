//
//  FrameLibraryView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

/// Everything that has been extracted, with selection and deletion.
struct FrameLibraryView: View {

    @Environment(VideoManager.self) private var videoManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isSelecting = false
    @State private var selection: Set<UUID> = []
    @State private var framePendingDeletion: ExtractedFrame?
    @State private var isConfirmingSelectionDelete = false

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 240), spacing: AppTheme.Spacing.md)]

    var body: some View {
        Group {
            if videoManager.extractedFrames.isEmpty {
                ContentUnavailableView {
                    Label("No Frames Yet", systemImage: "photo.stack")
                } description: {
                    Text("Frames you extract from a video are listed here.")
                }
            } else {
                grid
            }
        }
        .navigationTitle(isSelecting ? "\(selection.count) Selected" : "Extracted Frames")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert("Delete Frame?", isPresented: Binding(
            get: { framePendingDeletion != nil },
            set: { if !$0 { framePendingDeletion = nil } }
        ), presenting: framePendingDeletion) { frame in
            Button("Delete", role: .destructive) {
                delete([frame])
                framePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { framePendingDeletion = nil }
        } message: { _ in
            Text("The frame is removed from Frame Extractor and from your photo library. This can’t be undone.")
        }
        .alert("Delete \(selection.count) Frames?", isPresented: $isConfirmingSelectionDelete) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They are removed from Frame Extractor and from your photo library. This can’t be undone.")
        }
    }

    // MARK: - Grid

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
                ForEach(videoManager.extractedFrames.reversed()) { frame in
                    FrameThumbnail(
                        frame: frame,
                        isSelecting: isSelecting,
                        isSelected: selection.contains(frame.id),
                        onTap: { handleTap(on: frame) },
                        onDelete: { framePendingDeletion = frame }
                    )
                }
            }
            .padding(AppTheme.Spacing.lg)
            .animation(AppTheme.Motion.springy(reduceMotion), value: videoManager.extractedFrames.count)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !videoManager.extractedFrames.isEmpty {
                Button(isSelecting ? "Done" : "Select") {
                    withAnimation(AppTheme.Motion.springy(reduceMotion)) {
                        isSelecting.toggle()
                        if !isSelecting { selection.removeAll() }
                    }
                }
                .accessibilityHint(isSelecting ? "Leaves selection mode" : "Lets you choose several frames at once")
            }
        }

        if isSelecting {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Select All") {
                    selection = Set(videoManager.extractedFrames.map(\.id))
                }
                .disabled(selection.count == videoManager.extractedFrames.count)

                Spacer()

                Button("Delete", role: .destructive) {
                    isConfirmingSelectionDelete = true
                }
                .disabled(selection.isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func handleTap(on frame: ExtractedFrame) {
        if isSelecting {
            if selection.contains(frame.id) {
                selection.remove(frame.id)
            } else {
                selection.insert(frame.id)
            }
            Haptics.impact(.light)
        }
    }

    private func delete(_ frames: [ExtractedFrame]) {
        withAnimation(AppTheme.Motion.springy(reduceMotion)) {
            videoManager.deleteFrames(frames)
        }
        selection.subtract(frames.map(\.id))
    }

    private func deleteSelected() {
        let frames = videoManager.extractedFrames.filter { selection.contains($0.id) }
        delete(frames)
    }
}

// MARK: - Thumbnail

private struct FrameThumbnail: View {

    let frame: ExtractedFrame
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingFullScreen = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                if isSelecting {
                    onTap()
                } else {
                    isShowingFullScreen = true
                }
            } label: {
                Image(uiImage: frame.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(.rect(cornerRadius: AppTheme.CornerRadius.md))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                .strokeBorder(.tint, lineWidth: 3)
                        }
                    }
            }
            .buttonStyle(PressableButtonStyle())
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Frame", systemImage: "trash")
                }
            }
            .accessibilityLabel("Frame at \(frame.originalMarkedFrame.accessibilityTimeString)")
            .accessibilityHint(isSelecting ? "Selects or deselects this frame" : "Opens the frame full screen")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)

            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.9), isSelected ? Color.accentColor : Color.black.opacity(0.35))
                    .padding(AppTheme.Spacing.sm)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            if !isSelecting {
                timeBadge
            }
        }
        .fullScreenCover(isPresented: $isShowingFullScreen) {
            FrameDetailView(frame: frame)
        }
    }

    private var timeBadge: some View {
        Text(frame.timeString)
            .font(AppTheme.Typography.caption2)
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(.black.opacity(0.55), in: .capsule)
            .padding(AppTheme.Spacing.sm)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Detail

/// The extracted frame on its own, with zoom, and a way to pass it on.
private struct FrameDetailView: View {

    let frame: ExtractedFrame

    @Environment(VideoManager.self) private var videoManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var fullImage: UIImage?
    @State private var zoom: CGFloat = 1
    @State private var committedZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    private var image: UIImage { fullImage ?? frame.thumbnail }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(zoom)
                .offset(offset)
                .gesture(zoomGesture)
                .simultaneousGesture(panGesture)
                .onTapGesture(count: 2) { toggleZoom() }
                .accessibilityLabel("Extracted frame at \(frame.originalMarkedFrame.accessibilityTimeString)")

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: AppTheme.minimumHitTarget, height: AppTheme.minimumHitTarget)
                            .background(.regularMaterial, in: .circle)
                    }
                    .accessibilityLabel("Close")

                    Spacer()

                    Text(frame.timeString)
                        .font(AppTheme.Typography.subheadline)
                        .monospacedDigit()
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(.regularMaterial, in: .capsule)

                    Spacer()

                    ShareLink(item: Image(uiImage: image), preview: SharePreview(frame.timeString, image: Image(uiImage: image))) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .frame(width: AppTheme.minimumHitTarget, height: AppTheme.minimumHitTarget)
                            .background(.regularMaterial, in: .circle)
                    }
                    .accessibilityLabel("Share frame")
                }
                .padding(AppTheme.Spacing.lg)

                Spacer()
            }
        }
        .task {
            fullImage = await videoManager.fullImage(for: frame)
        }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(committedZoom * value.magnification, 1), 6)
            }
            .onEnded { _ in
                committedZoom = zoom
                resetIfNeeded()
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoom > 1 else { return }
                offset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height
                )
            }
            .onEnded { _ in committedOffset = offset }
    }

    private func toggleZoom() {
        withAnimation(AppTheme.Motion.springy(reduceMotion)) {
            zoom = zoom > 1 ? 1 : 2.5
            committedZoom = zoom
            offset = .zero
            committedOffset = .zero
        }
    }

    private func resetIfNeeded() {
        guard zoom < 1.05 else { return }
        withAnimation(AppTheme.Motion.springy(reduceMotion)) {
            zoom = 1
            committedZoom = 1
            offset = .zero
            committedOffset = .zero
        }
    }
}

#Preview {
    NavigationStack {
        FrameLibraryView()
    }
    .environment(VideoManager())
}
