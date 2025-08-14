//
//  ExtractionProgressView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

struct ExtractionProgressView: View {
    @ObservedObject var videoManager: VideoManager
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Progress Icon
                ZStack {
                    Circle()
                        .stroke(.blue.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: videoManager.extractionProgress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: videoManager.extractionProgress)
                    
                    if videoManager.isExtracting {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                    }
                }
                
                // Status Text
                VStack(spacing: 8) {
                    Text(videoManager.isExtracting ? "Extracting Frames" : "Extraction Complete!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if videoManager.isExtracting {
                        Text("Processing \(Int(videoManager.extractionProgress * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("All frames have been saved to your photo library")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Progress Bar
                if videoManager.isExtracting {
                    ProgressView(value: videoManager.extractionProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 2)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Action Button
                if !videoManager.isExtracting {
                    Button {
                        onComplete()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Done")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Extracting Frames")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(videoManager.isExtracting)
        }
    }
}
