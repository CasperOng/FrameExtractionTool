//
//  ContentView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()
    @State private var showingVideoPicker = false
    @State private var showingVideoPlayer = false
    @State private var showingFrameLibrary = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Select frames from your videos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Main Action Button
                Button {
                    showingVideoPicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose Video")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                
                // Frame Library Button
                if !videoManager.extractedFrames.isEmpty {
                    Button {
                        showingFrameLibrary = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("View Extracted Frames (\(videoManager.extractedFrames.count))")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
                
                // Recent Activity (if any frames exist)
                if !videoManager.extractedFrames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recently Extracted")
                                .font(.headline)
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(videoManager.extractedFrames.suffix(5), id: \.id) { frame in
                                    Image(uiImage: frame.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Frame Extractor")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView(videoManager: videoManager) {
                showingVideoPicker = false
                showingVideoPlayer = true
            }
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let videoURL = videoManager.selectedVideoURL {
                VideoPlayerView(videoURL: videoURL, videoManager: videoManager) {
                    showingVideoPlayer = false
                }
            }
        }
        .sheet(isPresented: $showingFrameLibrary) {
            FrameLibraryView(videoManager: videoManager)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
}
