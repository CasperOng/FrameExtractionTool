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

    private var videoURL: URL?
    private var isProcessing = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the view immediately
        view.backgroundColor = .systemBackground

        // Process the shared video
        processSharedVideo()
    }

    private func processSharedVideo() {
        guard !isProcessing else { return }
        isProcessing = true

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            showError("No video found")
            return
        }

        // Find video attachment
        let videoAttachment = attachments.first { attachment in
            attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
            attachment.hasItemConformingToTypeIdentifier(UTType.video.identifier)
        }

        guard let videoAttachment = videoAttachment else {
            showError("Selected item is not a video")
            return
        }

        // Determine type identifier
        let typeIdentifier = videoAttachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            ? UTType.movie.identifier
            : UTType.video.identifier

        // Show loading UI
        showLoading()

        // Load the video
        videoAttachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (item, error) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.showError("Failed to load video: \(error.localizedDescription)")
                    return
                }

                guard let videoURL = item as? URL else {
                    self.showError("Invalid video format")
                    return
                }

                self.handleVideo(url: videoURL)
            }
        }
    }

    private func handleVideo(url: URL) {
        // Start accessing security-scoped resource
        let isAccessing = url.startAccessingSecurityScopedResource()

        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Copy to shared container
            let copiedURL = try SharedDataManager.shared.copyVideoToSharedContainer(from: url)

            // Save pending video
            SharedDataManager.shared.savePendingVideo(url: copiedURL)

            // Open main app
            openMainApp()

        } catch {
            showError("Failed to process video: \(error.localizedDescription)")
        }
    }

    private func openMainApp() {
        let urlString = "frameextractor://open?source=share"
        guard let url = URL(string: urlString) else {
            completeRequest()
            return
        }

        // Try to open the main app
        var responder: UIResponder? = self
        let selector = NSSelectorFromString("openURL:")

        while responder != nil {
            if responder?.responds(to: selector) == true {
                responder?.perform(selector, with: url)
                break
            }
            responder = responder?.next
        }

        // Also try the extension context method
        self.extensionContext?.open(url, completionHandler: { success in
            print(success ? "✅ App opened successfully" : "❌ Failed to open app")
        })

        // Complete the request after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.completeRequest()
        }
    }

    private func showLoading() {
        DispatchQueue.main.async {
            // Clear existing views
            self.view.subviews.forEach { $0.removeFromSuperview() }

            let loadingView = LoadingView()
            let hostingController = UIHostingController(rootView: loadingView)

            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            hostingController.view.frame = self.view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            // Clear existing views
            self.view.subviews.forEach { $0.removeFromSuperview() }

            let errorView = ErrorView(message: message) { [weak self] in
                self?.cancelRequest()
            }
            let hostingController = UIHostingController(rootView: errorView)

            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            hostingController.view.frame = self.view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func cancelRequest() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        extensionContext?.cancelRequest(withError: error)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)

            Text("Opening Frame Extractor...")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Please wait")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text("Error")
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LoadingView()
}
