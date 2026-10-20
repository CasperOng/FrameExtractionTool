//
//  ShareViewController.swift
//  ShareExtension
//

import Observation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Takes a video from the share sheet and leaves it in the App Group for the app.
///
/// The extension deliberately does not try to launch Frame Extractor: iOS only
/// supports `NSExtensionContext.open(_:completionHandler:)` in the Today and
/// iMessage extension points, and attempts to work around that are what makes a
/// share extension feel unreliable. Instead the video is filed, the extension
/// says where it went, and the app collects it as soon as it becomes active.
final class ShareViewController: UIViewController {

    private let receiver = ShareReceiver()
    private var hostingController: UIHostingController<ShareConfirmView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let host = UIHostingController(rootView: ShareConfirmView(receiver: receiver))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        hostingController = host

        receiver.onFinish = { [weak self] completed in
            self?.finish(completed: completed)
        }

        Task {
            await receiver.receive(from: extensionContext)
        }
    }

    private func finish(completed: Bool) {
        if completed {
            extensionContext?.completeRequest(returningItems: nil)
        } else {
            extensionContext?.cancelRequest(withError: ShareReceiver.Cancellation())
        }
    }
}

// MARK: - Receiver

@MainActor
@Observable
final class ShareReceiver {

    struct Cancellation: Error {}

    enum Phase: Equatable {
        case working
        case ready(String)
        case failed(String)

        var isFinished: Bool {
            if case .working = self { return false }
            return true
        }
    }

    private(set) var phase: Phase = .working

    /// Called when the sheet can be dismissed; `completed` is false when nothing
    /// was handed over.
    var onFinish: ((Bool) -> Void)?

    func receive(from context: NSExtensionContext?) async {
        guard let provider = videoProvider(in: context) else {
            phase = .failed("There is no video to send to Frame Extractor.")
            return
        }

        do {
            let filed = try await file(from: provider)
            phase = .ready(filed.lastPathComponent)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func finish() {
        onFinish?(phase.isFinished && !isFailure)
    }

    private var isFailure: Bool {
        if case .failed = phase { return true }
        return false
    }

    /// The first video among the shared items, or whatever single item was sent.
    private func videoProvider(in context: NSExtensionContext?) -> NSItemProvider? {
        let providers = (context?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        return providers.first { $0.hasItemConformingToTypeIdentifier(UTType.movie.identifier) }
            ?? (providers.count == 1 ? providers.first : nil)
    }

    private func file(from provider: NSItemProvider) async throws -> URL {
        let identifier = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            ? UTType.movie.identifier
            : (provider.registeredTypeIdentifiers.first ?? UTType.movie.identifier)
        let suggestedName = provider.suggestedName ?? ""

        return try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: identifier) { url, error in
                // The file only exists for the length of this handler.
                guard let url else {
                    continuation.resume(throwing: error ?? VideoInbox.InboxError.copyFailed)
                    return
                }
                do {
                    let filed = try VideoInbox.file(url, displayName: suggestedName.isEmpty ? url.lastPathComponent : suggestedName)
                    continuation.resume(returning: filed)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - UI

/// A short confirmation: what happened, and what to do next.
struct ShareConfirmView: View {

    let receiver: ShareReceiver

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if receiver.phase.isFinished {
                Button {
                    receiver.finish()
                } label: {
                    Text("Done")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            } else {
                ProgressView()
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var symbol: String {
        switch receiver.phase {
        case .working: "video.badge.plus"
        case .ready: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }

    private var tint: Color {
        switch receiver.phase {
        case .working, .ready: .accentColor
        case .failed: .orange
        }
    }

    private var title: String {
        switch receiver.phase {
        case .working: "Preparing Video"
        case .ready: "Ready in Frame Extractor"
        case .failed: "Couldn’t Send Video"
        }
    }

    private var message: String {
        switch receiver.phase {
        case .working:
            "Copying the video so Frame Extractor can read it."
        case .ready:
            "Open Frame Extractor to mark frames — the video is waiting there."
        case .failed(let reason):
            reason
        }
    }
}
