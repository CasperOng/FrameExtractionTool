//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Claude on 11/6/2026.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers
import MobileCoreServices

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Present SwiftUI view
        let shareView = ShareExtensionView(extensionContext: self.extensionContext)
        let hostingController = UIHostingController(rootView: shareView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
}

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing video...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Opening Frame Extractor...")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else if let success = successMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        Text("Ready!")
                            .font(.title2.bold())
                        Text(success)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        Text("Error")
                            .font(.title2.bold())
                        Text(error)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Cancel") {
                            cancelExtension()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle.on.rectangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        Text("Frame Extractor")
                            .font(.title2.bold())
                        Text("Extract frames from this video")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .navigationTitle("Frame Extractor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isProcessing {
                        Button("Cancel") {
                            cancelExtension()
                        }
                    }
                }
            }
        }
        .onAppear {
            processSharedVideo()
        }
    }

    private func processSharedVideo() {
        guard let extensionContext = extensionContext else {
            errorMessage = "Failed to access shared content"
            return
        }

        isProcessing = true

        // Get the first input item
        guard let item = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            errorMessage = "No video found to share"
            isProcessing = false
            return
        }

        // Find the video attachment
        let videoAttachment = attachments.first { attachment in
            attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
            attachment.hasItemConformingToTypeIdentifier(UTType.video.identifier)
        }

        guard let videoAttachment = videoAttachment else {
            errorMessage = "Selected item is not a video"
            isProcessing = false
            return
        }

        // Try movie first, then video
        let typeIdentifier = videoAttachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            ? UTType.movie.identifier
            : UTType.video.identifier

        // Load the video URL
        videoAttachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { (item, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to load video: \(error.localizedDescription)"
                    self.isProcessing = false
                    return
                }

                guard let videoURL = item as? URL else {
                    self.errorMessage = "Invalid video format"
                    self.isProcessing = false
                    return
                }

                // Start accessing security-scoped resource
                let isAccessing = videoURL.startAccessingSecurityScopedResource()

                defer {
                    if isAccessing {
                        videoURL.stopAccessingSecurityScopedResource()
                    }
                }

                // Copy video to shared container
                do {
                    let copiedURL = try SharedDataManager.shared.copyVideoToSharedContainer(from: videoURL)
                    SharedDataManager.shared.savePendingVideo(url: copiedURL)

                    self.successMessage = "Launching Frame Extractor..."

                    // Give UI time to update before opening app
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.openMainApp()
                    }
                } catch {
                    self.errorMessage = "Failed to copy video: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }

    private func openMainApp() {
        // Open the main app using custom URL scheme
        let urlString = "frameextractor://open?source=share"
        if let url = URL(string: urlString) {
            self.extensionContext?.open(url, completionHandler: { success in
                if success {
                    print("✅ Successfully opened main app")
                } else {
                    print("❌ Failed to open main app")
                }
            })
        }

        // Close the extension after delay to allow app to open
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.completeExtension()
        }
    }

    private func completeExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func cancelExtension() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        extensionContext?.cancelRequest(withError: error)
    }
}

#Preview {
    ShareExtensionView(extensionContext: nil)
}
