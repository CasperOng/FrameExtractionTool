//
//  FrameMarkingHelpView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

struct FrameMarkingHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Mark Frames")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        InstructionRow(
                            icon: "play.circle",
                            title: "Play & Pause",
                            description: "Tap anywhere on the video or use the play button to control playback"
                        )
                        
                        InstructionRow(
                            icon: "plus.circle.fill",
                            title: "Mark Frame",
                            description: "Tap the blue plus button to mark the current frame for extraction"
                        )
                        
                        InstructionRow(
                            icon: "timeline.selection",
                            title: "Navigate Timeline",
                            description: "Drag on the timeline or tap marked frames to jump to specific moments"
                        )
                        
                        InstructionRow(
                            icon: "trash.circle",
                            title: "Remove Marks",
                            description: "Tap any blue marker on the timeline to remove that frame mark"
                        )
                        
                        InstructionRow(
                            icon: "square.and.arrow.down",
                            title: "Extract & Save",
                            description: "Tap 'Extract' to save all marked frames to your photo library"
                        )
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tips for Best Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        TipRow(
                            icon: "lightbulb",
                            tip: "Pause at key moments for precise frame selection"
                        )
                        
                        TipRow(
                            icon: "eye",
                            tip: "Use seek buttons to navigate frame by frame"
                        )
                        
                        TipRow(
                            icon: "photo",
                            tip: "Frames are saved at original video quality"
                        )
                        
                        TipRow(
                            icon: "clock",
                            tip: "Frame timestamps help you organize your captures"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.orange)
                .frame(width: 20)
            
            Text(tip)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
