//
//  FrameLibraryView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

struct FrameLibraryView: View {
    @ObservedObject var videoManager: VideoManager
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if videoManager.extractedFrames.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        
                        Text("No Frames Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Extract frames from videos to see them here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(videoManager.extractedFrames.reversed()) { frame in
                            FrameThumbnailView(frame: frame)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Extracted Frames")
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

struct FrameThumbnailView: View {
    let frame: ExtractedFrame
    @State private var showingFullScreen = false
    
    var body: some View {
        Button {
            showingFullScreen = true
        } label: {
            Image(uiImage: frame.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text(frame.originalMarkedFrame.timeString)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                        .padding(4)
                    }
                )
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenImageView(image: frame.image) {
                showingFullScreen = false
            }
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
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
                                scale = min(max(value, 0.5), 3.0)
                            },
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        scale = scale > 1 ? 1 : 2
                        offset = .zero
                    }
                }
            
            VStack {
                HStack {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.3)))
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}
