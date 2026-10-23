//
//  ShareViewController.swift
//  ShareExtension
//

import Observation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Takes a video from the share sheet and gets it to the app.
///
/// The extension deliberately does not try to launch Frame Extractor: iOS only
/// supports `NSExtensionContext.open(_:completionHandler:)` in the Today and
/// iMessage extension points, and working around that is what makes a share
/// extension feel unreliable.
///
/// There are two hand-off routes, tried in order:
///
/// 1. the shared App Group container, which is automatic but only exists when the
///    build is signed with a profile that authorises the group (Xcode builds with
///    a team that has the App Groups capability);
/// 2. the app's Documents folder through Files, which needs no entitlement and
///    therefore also works on self-signed builds. The app picks the video up from
///    there the next time it becomes active.
final class ShareViewController: UIViewController {

    private let receiver = ShareReceiver()

    override func viewDidLoad() {
        super.viewDidLoad()

        let host = UIHostingController(rootView: ShareConfirmView(receiver: receiver))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)

        receiver.onFinish = { [weak self] completed in
            self?.finish(completed: completed)
        }
        receiver.onSaveToFiles = { [weak self] file in
            self?.presentExportPicker(for: file)
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

    private func presentExportPicker(for file: URL) {
        let picker = UIDocumentPickerViewController(forExporting: [file], asCopy: true)
        picker.delegate = self
        picker.shouldShowFileExtensions = true
        present(picker, animated: true)
    }
}

extension ShareViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Saved into the folder the user chose; the app collects it from its own
        // Documents folder when it opens.
        extensionContext?.completeRequest(returningItems: nil)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // Stay put: the sheet still explains what to do and offers Done.
    }
}

// MARK: - Receiver

@MainActor
@Observable
final class ShareReceiver {

    struct Cancellation: Error {}

    enum Phase: Equatable {
        case working
        /// Filed for the app; the associated value is the file name.
        case ready(String)
        /// No shared container: the video has to be saved through Files.
        case saveToFiles(String)
        case failed(String)

        var isFinished: Bool {
            if case .working = self { return false }
            return true
        }
    }

    private(set) var phase: Phase = .working
    /// The file to export when the shared container is unavailable.
    private(set) var pendingFileURL: URL?

    /// Called when the sheet can be dismissed; `completed` is false when nothing
    /// was handed over.
    var onFinish: ((Bool) -> Void)?
    /// Called when the user asks to save the video through Files.
    var onSaveToFiles: ((URL) -> Void)?

    func receive(from context: NSExtensionContext?) async {
        guard let provider = videoProvider(in: context) else {
            phase = .failed("There is no video to send to Frame Extractor.")
            return
        }

        do {
            let filed = try await withSourceFile(of: provider) { url, suggestedName in
                try VideoInbox.file(url, displayName: suggestedName.isEmpty ? url.lastPathComponent : suggestedName)
            }
            phase = .ready(filed.lastPathComponent)
        } catch VideoInbox.InboxError.unavailable {
            // Signed without the App Group: fall back to the app's Files folder.
            do {
                let copy = try await withSourceFile(of: provider) { url, suggestedName in
                    try copyToTemporaryFile(url, named: suggestedName.isEmpty ? url.lastPathComponent : suggestedName)
                }
                pendingFileURL = copy
                phase = .saveToFiles(copy.lastPathComponent)
            } catch {
                phase = .failed(error.localizedDescription)
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func saveToFiles() {
        guard let pendingFileURL else { return }
        onSaveToFiles?(pendingFileURL)
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

    /// Runs `work` while the item provider's file is still on disk — it only
    /// exists for the lifetime of the load handler.
    private func withSourceFile<T>(
        of provider: NSItemProvider,
        _ work: @escaping (URL, String) throws -> T
    ) async throws -> T {
        let identifier = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            ? UTType.movie.identifier
            : (provider.registeredTypeIdentifiers.first ?? UTType.movie.identifier)
        let suggestedName = provider.suggestedName ?? ""

        return try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: identifier) { url, error in
                guard let url else {
                    continuation.resume(throwing: error ?? VideoInbox.InboxError.copyFailed)
                    return
                }
                do {
                    continuation.resume(returning: try work(url, suggestedName))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func copyToTemporaryFile(_ source: URL, named name: String) throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appending(path: "\(UUID().uuidString.prefix(8))~\(VideoInbox.safeName(name))")
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
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

            switch receiver.phase {
            case .working:
                ProgressView()
                    .padding(.top, 4)

            case .ready:
                Button {
                    receiver.finish()
                } label: {
                    Text("Done")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)

            case .saveToFiles:
                VStack(spacing: 8) {
                    Button {
                        receiver.saveToFiles()
                    } label: {
                        Text("Save to Frame Extractor…")
                            .frame(minWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Not Now") {
                        receiver.finish()
                    }
                    .font(.footnote)
                }
                .padding(.top, 4)

            case .failed:
                Button {
                    receiver.finish()
                } label: {
                    Text("Done")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
        case .saveToFiles: "folder.badge.plus"
        case .failed: "exclamationmark.triangle"
        }
    }

    private var tint: Color {
        switch receiver.phase {
        case .working, .ready, .saveToFiles: .accentColor
        case .failed: .orange
        }
    }

    private var title: String {
        switch receiver.phase {
        case .working: "Preparing Video"
        case .ready: "Ready in Frame Extractor"
        case .saveToFiles: "Save the Video to Frame Extractor"
        case .failed: "Couldn’t Send Video"
        }
    }

    private var message: String {
        switch receiver.phase {
        case .working:
            "Copying the video so Frame Extractor can read it."
        case .ready:
            "Open Frame Extractor to mark frames — the video is waiting there."
        case .saveToFiles:
            "This build was signed without the shared folder the extension usually uses. Save the video into Frame Extractor’s folder in Files, then open the app — it picks the video up from there."
        case .failed(let reason):
            reason
        }
    }
}
