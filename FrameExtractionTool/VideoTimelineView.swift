//
//  VideoTimelineView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import AVFoundation
import SwiftUI

/// Scrubbing bar plus the frames marked so far.
struct VideoTimelineView: View {

    let currentTime: CMTime
    let duration: CMTime
    let markedFrames: [MarkedFrame]
    let onSeek: (CMTime) -> Void
    let onRemoveMark: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isScrubbing = false

    private var progress: Double {
        let seconds = duration.seconds
        guard seconds.isFinite, seconds > 0 else { return 0 }
        return min(max(currentTime.seconds / seconds, 0), 1)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text(Self.shortTime(currentTime.seconds))
                    .monospacedDigit()
                    .accessibilityLabel("Current position \(MarkedFrame.timeString(fromSeconds: currentTime.seconds))")
                Spacer()
                Text(Self.shortTime(duration.seconds))
                    .monospacedDigit()
                    .accessibilityLabel("Duration \(MarkedFrame.timeString(fromSeconds: duration.seconds))")
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)

            track

            if !markedFrames.isEmpty {
                markedFrameStrip
            }
        }
    }

    // MARK: - Track

    private var track: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 6)

                Capsule()
                    .fill(.tint)
                    .frame(width: width * progress, height: 6)

                ForEach(markedFrames) { frame in
                    marker(for: frame, in: CGSize(width: width, height: height))
                }

                Circle()
                    .fill(.white)
                    .frame(width: isScrubbing ? 22 : 16, height: isScrubbing ? 22 : 16)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .position(x: width * progress, y: height / 2)
            }
            .contentShape(Rectangle())
            // A zero-distance drag also covers taps, so scrubbing starts on touch down.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isScrubbing = true
                        seek(toFraction: value.location.x / width)
                    }
                    .onEnded { _ in isScrubbing = false }
            )
            .animation(AppTheme.Motion.quick(reduceMotion), value: isScrubbing)
        }
        .frame(height: AppTheme.minimumHitTarget)
        .accessibilityElement()
        .accessibilityLabel("Playback position")
        .accessibilityValue(MarkedFrame.timeString(fromSeconds: currentTime.seconds))
        .accessibilityHint("Swipe up or down to move one second at a time")
        .accessibilityAdjustableAction { direction in
            let step = 1.0
            switch direction {
            case .increment: seek(toFraction: (currentTime.seconds + step) / max(duration.seconds, step))
            case .decrement: seek(toFraction: (currentTime.seconds - step) / max(duration.seconds, step))
            @unknown default: break
            }
        }
    }

    private func marker(for frame: MarkedFrame, in size: CGSize) -> some View {
        let position = duration.seconds > 0 ? frame.seconds / duration.seconds : 0
        let x = min(max(size.width * position, 0), size.width)

        return Button {
            onSeek(frame.timeStamp)
        } label: {
            Image(systemName: "flag.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.tint)
                .frame(width: AppTheme.minimumHitTarget, height: AppTheme.minimumHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .position(x: x, y: size.height / 2)
        .accessibilityLabel("Marked frame at \(frame.accessibilityTimeString)")
        .accessibilityHint("Jumps to this frame")
        .contextMenu {
            Button(role: .destructive) {
                onRemoveMark(frame.id)
            } label: {
                Label("Remove Mark", systemImage: "trash")
            }
        }
    }

    // MARK: - Marked frames

    private var markedFrameStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(markedFrames) { frame in
                    Button {
                        onSeek(frame.timeStamp)
                    } label: {
                        Text(frame.timeString)
                            .font(AppTheme.Typography.caption)
                            .monospacedDigit()
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(.quaternary, in: .capsule)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Marked frame at \(frame.accessibilityTimeString)")
                    .contextMenu {
                        Button("Remove Mark", systemImage: "trash", role: .destructive) {
                            onRemoveMark(frame.id)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .animation(AppTheme.Motion.springy(reduceMotion), value: markedFrames.count)
    }

    // MARK: - Helpers

    private func seek(toFraction fraction: Double) {
        guard duration.isNumeric, duration.seconds > 0 else { return }
        let clamped = min(max(fraction, 0), 1)
        onSeek(CMTime(seconds: duration.seconds * clamped, preferredTimescale: 600))
    }

    /// `mm:ss`, or `h:mm:ss` for long videos.
    private static func shortTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total / 60) % 60
        let remainder = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, remainder)
            : String(format: "%02d:%02d", minutes, remainder)
    }
}
