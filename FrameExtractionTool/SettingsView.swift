//
//  SettingsView.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

/// A standard grouped settings screen: people already know how to read one.
struct SettingsView: View {

    @AppStorage(AppSettings.Key.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(AppSettings.Key.usesCustomAlbum) private var usesCustomAlbum = false
    @AppStorage(AppSettings.Key.albumName) private var albumName = AppSettings.defaultAlbumName

    @State private var isShowingTutorial = false
    @State private var editedAlbumName = ""
    @State private var isNamingAlbum = false

    private static let repositoryURL = URL(string: "https://github.com/CasperOng/FrameExtractionTool")!

    var body: some View {
        Form {
            Section {
                Toggle("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right", isOn: $hapticsEnabled)
            } header: {
                Text("Marking")
            } footer: {
                Text("A light tap when you mark a frame, remove one, or finish extracting.")
            }

            Section {
                Toggle("Save to an Album", systemImage: "folder", isOn: $usesCustomAlbum)

                if usesCustomAlbum {
                    Button {
                        editedAlbumName = albumName
                        isNamingAlbum = true
                    } label: {
                        LabeledContent("Album Name") {
                            Text(albumName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Photo Library")
            } footer: {
                if usesCustomAlbum {
                    Text("Frames are added to “\(albumName)”, which is created if it does not exist. Albums need full photo library access; if it is not granted, frames are saved to your library instead.")
                } else {
                    Text("Frames are saved to your photo library.")
                }
            }

            Section("Help") {
                Button {
                    isShowingTutorial = true
                } label: {
                    Label("Show Tutorial", systemImage: "sparkles")
                }

                Link(destination: Self.repositoryURL) {
                    Label("Source Code and Feedback", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }

            Section {
                LabeledContent("Version", value: AppVersion.full)
            } header: {
                Text("About")
            } footer: {
                Text("Frame Extractor reads frames straight from the video with AVFoundation, so every frame keeps the resolution of the original file. Processing happens on this device.")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingTutorial) {
            OnboardingView { isShowingTutorial = false }
        }
        .alert("Album Name", isPresented: $isNamingAlbum) {
            TextField("Album Name", text: $editedAlbumName)
                .textInputAutocapitalization(.words)
            Button("Save") { commitAlbumName() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Extracted frames are added to an album with this name.")
        }
    }

    private func commitAlbumName() {
        let trimmed = editedAlbumName.trimmingCharacters(in: .whitespacesAndNewlines)
        albumName = trimmed.isEmpty ? AppSettings.defaultAlbumName : trimmed
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
