//
//  ExtractionProgressView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

/// Reports the progress of an extraction run and lets the user stop it.
///
/// The run is cancelable on purpose: saving a long list of frames can take a
/// while, and frames that were already written stay saved
/// (HIG › Progress indicators › Best practices).
struct ExtractionProgressView: View {

    /// Called when the user is finished; `leavePlayer` is true when the work is
    /// done and the player can be closed too.
    let onFinish: (Bool) -> Void
    let onCancel: () -> Void

    @Environment(VideoManager.self) private var videoManager
    @State private var didCancel = false

    private var summary: ExtractionSummary? { videoManager.lastSummary }

    private var completedCount: Int {
        let total = Double(videoManager.extractionTotal)
        return total > 0 ? Int((videoManager.extractionProgress * total).rounded()) : 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                icon
                status
                Spacer()
                footer
            }
            .padding(AppTheme.Spacing.lg)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if videoManager.isExtracting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            didCancel = true
                            onCancel()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(videoManager.isExtracting)
        .presentationDetents([.medium, .large])
    }

    private var navigationTitle: String {
        videoManager.isExtracting ? "Extracting Frames" : "Frames Saved"
    }

    private var icon: some View {
        Image(systemName: iconName)
            .font(.system(size: 56, weight: .light))
            .foregroundStyle(iconColor)
            .symbolRenderingMode(.hierarchical)
            .accessibilityHidden(true)
    }

    private var iconName: String {
        if videoManager.isExtracting { return "photo.stack" }
        if didCancel { return "stop.circle" }
        return summary?.failedCount == 0 ? "checkmark.circle" : "exclamationmark.triangle"
    }

    private var iconColor: Color {
        if videoManager.isExtracting { return .accentColor }
        return summary?.failedCount == 0 ? .green : .orange
    }

    @ViewBuilder
    private var status: some View {
        if videoManager.isExtracting {
            VStack(spacing: AppTheme.Spacing.lg) {
                ProgressView(value: videoManager.extractionProgress)
                    .progressViewStyle(.linear)
                Text("Frame \(completedCount) of \(videoManager.extractionTotal)")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(maxWidth: 320)
        } else {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(resultHeadline)
                    .font(AppTheme.Typography.title2)

                Text(resultDetail)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
        }
    }

    private var resultHeadline: String {
        if didCancel { return "Extraction Stopped" }
        guard let summary else { return "Nothing Saved" }
        if summary.savedCount == 0 { return "Nothing Saved" }
        return summary.savedCount == 1 ? "1 Frame Saved" : "\(summary.savedCount) Frames Saved"
    }

    private var resultDetail: String {
        var parts: [String] = []
        if let summary {
            if summary.failedCount > 0 {
                let noun = summary.failedCount == 1 ? "frame" : "frames"
                parts.append("\(summary.failedCount) \(noun) could not be saved.")
            }
            if let note = summary.note {
                parts.append(note)
            }
        }
        if parts.isEmpty {
            let album = AppSettings.usesCustomAlbum ? "the “\(AppSettings.albumName)” album in your photo library" : "your photo library"
            parts.append("Your frames are in \(album).")
        }
        return parts.joined(separator: " ")
    }

    @ViewBuilder
    private var footer: some View {
        if !videoManager.isExtracting {
            Button {
                onFinish(savedAnything)
            } label: {
                Text(savedAnything ? "Done" : "Back to Video")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var savedAnything: Bool {
        (summary?.savedCount ?? 0) > 0
    }
}

#Preview {
    ExtractionProgressView(onFinish: { _ in }, onCancel: {})
        .environment(VideoManager())
}
