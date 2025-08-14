//
//  VideoPickerView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI
import PhotosUI

struct VideoPickerView: View {
    @ObservedObject var videoManager: VideoManager
    let onVideoSelected: () -> Void
    
    @State private var selectedItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Select a Video")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose a video from your photo library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Photo Picker
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .videos
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        
                        Text("Browse Videos")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 2, dash: [10]))
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Choose Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: VideoFile.self) {
                    videoManager.selectVideo(url: data.url)
                    onVideoSelected()
                }
            }
        }
    }
}

struct VideoFile: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let copiedURL = documentsDirectory.appendingPathComponent(received.file.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: copiedURL.path) {
                try FileManager.default.removeItem(at: copiedURL)
            }
            
            try FileManager.default.copyItem(at: received.file, to: copiedURL)
            return VideoFile(url: copiedURL)
        }
    }
}
