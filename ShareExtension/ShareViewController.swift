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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Processing video...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else if let error = errorMessage {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    Text("Error")
                        .font(.title2.bold())
                    Text(error)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button("Cancel") {
                        cancelExtension()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Image(systemName: "video.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    Text("Opening in Frame Extractor")
                        .font(.title2.bold())
                    Text("Your video will be ready for frame extraction")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Frame Extractor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelExtension()
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

        // Load the video URL
        videoAttachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to load video: \(error.localizedDescription)"
                    self?.isProcessing = false
                    return
                }

                guard let videoURL = item as? URL else {
                    self?.errorMessage = "Invalid video format"
                    self?.isProcessing = false
                    return
                }

                // Save the video URL to shared storage
                SharedDataManager.shared.savePendingVideo(url: videoURL)

                // Open the main app
                self?.openMainApp()
            }
        }
    }

    private func openMainApp() {
        // Open the main app using custom URL scheme
        let urlString = "frameextractor://open?source=share"
        if let url = URL(string: urlString) {
            var responder: UIResponder? = self.extensionContext as? UIResponder
            let selector = sel_registerName("openURL:")

            while responder != nil {
                if responder?.responds(to: selector) == true {
                    responder?.perform(selector, with: url)
                    break
                }
                responder = responder?.next
            }
        }

        // Close the extension after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
