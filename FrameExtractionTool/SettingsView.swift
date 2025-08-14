//
//  SettingsView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingOnboarding = false
    @State private var hapticFeedback = UserDefaults.standard.object(forKey: "hapticFeedback") == nil ? true : UserDefaults.standard.bool(forKey: "hapticFeedback")
    @State private var useCustomAlbum = UserDefaults.standard.bool(forKey: "useCustomAlbum")
    @State private var customAlbumName = UserDefaults.standard.string(forKey: "customAlbumName") ?? "Frame Extractor"
    @State private var showingAlbumNameAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "video.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text("Frame Extractor")
                                .font(.headline)
                            Text("Version 1.2.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Preferences") {
                    Toggle(isOn: $hapticFeedback) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: hapticFeedback) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "hapticFeedback")
                    }
                }
                
                Section {
                    Toggle(isOn: $useCustomAlbum) {
                        Label("Save to Custom Album", systemImage: "folder")
                    }
                    .onChange(of: useCustomAlbum) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "useCustomAlbum")
                    }
                    
                    if useCustomAlbum {
                        Button {
                            showingAlbumNameAlert = true
                        } label: {
                            HStack {
                                Label("Album Name", systemImage: "textformat")
                                Spacer()
                                Text(customAlbumName)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Photo Library")
                } footer: {
                    if useCustomAlbum {
                        Text("Extracted frames will be saved to a custom album named '\(customAlbumName)'. If the album doesn't exist, it will be created automatically.")
                    } else {
                        Text("Extracted frames will be saved directly to your photo library.")
                    }
                }
                
                Section("Help & Support") {
                    Button {
                        showingOnboarding = true
                    } label: {
                        Label("Show Tutorial", systemImage: "questionmark.circle")
                    }
                    .foregroundColor(.primary)
                    
                    Link(destination: URL(string: "https://developer.apple.com/documentation/avfoundation")!) {
                        Label("About Video Processing", systemImage: "info.circle")
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("Made with ❤️ by Casper N.Y. ONG using SwiftUI and following Apple's Human Interface Guidelines.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(showOnboarding: $showingOnboarding)
        }
        .alert("Album Name", isPresented: $showingAlbumNameAlert) {
            TextField("Album Name", text: $customAlbumName)
            Button("Save") {
                if !customAlbumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    UserDefaults.standard.set(customAlbumName, forKey: "customAlbumName")
                } else {
                    customAlbumName = "Frame Extractor"
                    UserDefaults.standard.set(customAlbumName, forKey: "customAlbumName")
                }
            }
            Button("Cancel", role: .cancel) {
                customAlbumName = UserDefaults.standard.string(forKey: "customAlbumName") ?? "Frame Extractor"
            }
        } message: {
            Text("Enter a name for the custom album where extracted frames will be saved.")
        }
    }
}
