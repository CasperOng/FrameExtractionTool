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
    @State private var isSelecting = false
    @State private var selectedFrames: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    @State private var frameToDelete: ExtractedFrame?
    
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
                            FrameThumbnailView(
                                frame: frame,
                                isSelecting: isSelecting,
                                isSelected: selectedFrames.contains(frame.id),
                                onSelect: { toggleSelection(for: frame) },
                                onDelete: { deleteFrame(frame) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Extracted Frames")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelecting {
                        Button("Cancel") {
                            cancelSelection()
                        }
                    } else {
                        EmptyView()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !videoManager.extractedFrames.isEmpty {
                            Button(isSelecting ? "Delete" : "Select") {
                                if isSelecting {
                                    deleteSelectedFrames()
                                } else {
                                    startSelection()
                                }
                            }
                            .disabled(isSelecting && selectedFrames.isEmpty)
                        }
                        
                        if !isSelecting {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .alert("Delete Frame", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let frame = frameToDelete {
                        videoManager.deleteExtractedFrame(frame)
                        frameToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    frameToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this extracted frame?")
            }
        }
    }
    
    private func toggleSelection(for frame: ExtractedFrame) {
        if selectedFrames.contains(frame.id) {
            selectedFrames.remove(frame.id)
        } else {
            selectedFrames.insert(frame.id)
        }
    }
    
    private func startSelection() {
        isSelecting = true
        selectedFrames.removeAll()
    }
    
    private func cancelSelection() {
        isSelecting = false
        selectedFrames.removeAll()
    }
    
    private func deleteFrame(_ frame: ExtractedFrame) {
        frameToDelete = frame
        showingDeleteConfirmation = true
    }
    
    private func deleteSelectedFrames() {
        let framesToDelete = videoManager.extractedFrames.filter { selectedFrames.contains($0.id) }
        videoManager.deleteExtractedFrames(framesToDelete)
        cancelSelection()
    }
}

struct FrameThumbnailView: View {
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
                    .overlay(
                        // Selection overlay
                        isSelecting ? RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? .blue : .gray, lineWidth: 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? .blue.opacity(0.2) : .clear)
                            ) : nil
                    )
                
                // Selection checkmark
                if isSelecting {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(isSelected ? .blue : .gray)
                                .background(Circle().fill(.white))
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .onLongPressGesture {
            if !isSelecting {
                onDelete()
            }
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
