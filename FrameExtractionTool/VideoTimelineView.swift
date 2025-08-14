//
//  VideoTimelineView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI
import AVFoundation

struct VideoTimelineView: View {
    let currentTime: CMTime
    let duration: CMTime
    let markedFrames: [MarkedFrame]
    let onSeek: (CMTime) -> Void
    let onRemoveFrame: (UUID) -> Void
    
    @State private var isDragging = false
    
    private var progress: Double {
        guard duration.seconds > 0 else { return 0 }
        return currentTime.seconds / duration.seconds
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Time labels
            HStack {
                Text(timeString(from: currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                Spacer()
                
                Text(timeString(from: duration))
                    .font(.caption)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            
            // Timeline
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress track
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                    
                    // Marked frames indicators
                    ForEach(markedFrames) { frame in
                        let frameProgress = frame.timeStamp.seconds / duration.seconds
                        let xPosition = geometry.size.width * frameProgress
                        
                        Button {
                            onRemoveFrame(frame.id)
                        } label: {
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: 2)
                                    )
                                
                                Rectangle()
                                    .fill(.blue)
                                    .frame(width: 2, height: 8)
                            }
                        }
                        .buttonStyle(.plain)
                        .position(x: xPosition, y: geometry.size.height / 2)
                    }
                    
                    // Current time indicator
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(radius: 2)
                        .position(x: geometry.size.width * progress, y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let progress = min(max(value.location.x / geometry.size.width, 0), 1)
                            let newTime = CMTimeMultiplyByFloat64(duration, multiplier: Float64(progress))
                            onSeek(newTime)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .onTapGesture { location in
                    let progress = min(max(location.x / geometry.size.width, 0), 1)
                    let newTime = CMTimeMultiplyByFloat64(duration, multiplier: Float64(progress))
                    onSeek(newTime)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 4)
            
            // Marked frames list
            if !markedFrames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(markedFrames) { frame in
                            Button {
                                onSeek(frame.timeStamp)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "photo.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text(frame.timeString)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func timeString(from time: CMTime) -> String {
        let seconds = Int(time.seconds)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
