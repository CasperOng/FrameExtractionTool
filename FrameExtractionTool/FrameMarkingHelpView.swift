//
//  FrameMarkingHelpView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

/// Short instructions, shown from the player while a video is open.
struct FrameMarkingHelpView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Marking Frames") {
                    HelpRow(
                        symbol: "play.fill",
                        title: "Play and pause",
                        detail: "Tap the video or the play button. The 10-second buttons jump back and forth."
                    )
                    HelpRow(
                        symbol: "plus",
                        title: "Mark a frame",
                        detail: "Tap the blue plus button to add the frame on screen to the list."
                    )
                    HelpRow(
                        symbol: "flag.fill",
                        title: "Revisit a mark",
                        detail: "Tap a flag on the timeline, or a time at the bottom, to jump to that frame."
                    )
                    HelpRow(
                        symbol: "trash",
                        title: "Remove a mark",
                        detail: "Touch and hold a flag, or a time at the bottom, and choose Remove Mark."
                    )
                }

                Section("Extracting") {
                    HelpRow(
                        symbol: "square.and.arrow.down",
                        title: "Save the frames",
                        detail: "Choose Extract to write every marked frame to your photo library at the video’s own resolution."
                    )
                    HelpRow(
                        symbol: "slider.horizontal.3",
                        title: "Playback options",
                        detail: "Change the speed or the size of the video from the toolbar menu."
                    )
                }

                Section("Tips") {
                    HelpRow(
                        symbol: "pause.circle",
                        title: "Pause before marking",
                        detail: "Frames are taken at the exact position of the playhead."
                    )
                    HelpRow(
                        symbol: "folder",
                        title: "Keep frames together",
                        detail: "Turn on Save to an Album in Settings to collect extracted frames in one place."
                    )
                }
            }
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HelpRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.lg) {
            Image(systemName: symbol)
                .font(AppTheme.Typography.body.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                Text(detail)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    FrameMarkingHelpView()
}
