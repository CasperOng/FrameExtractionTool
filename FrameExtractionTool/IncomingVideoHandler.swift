//
//  IncomingVideoHandler.swift
//  FrameExtractionTool
//
//  Videos reach the app from outside it in several ways: the share sheet's
//  "Open in" row, Files, AirDrop, a `frameextractor://` link, or a Shortcut.
//  They all arrive as a URL, and this type turns that URL into a video the app
//  has imported and can hand to the player.
//

import Foundation
import Observation
import OSLog

@Observable
final class IncomingVideoHandler {

    /// What the app is doing with an incoming video right now.
    enum State: Equatable {
        case idle
        case importing(name: String)
        case failed(message: String)

        var isImporting: Bool {
            if case .importing = self { return true }
            return false
        }
    }

    static let shared = IncomingVideoHandler()
    static let scheme = "frameextractor"

    private let logger = Logger(subsystem: "caspernyong.FrameExtractionTool", category: "incoming-video")

    private(set) var state: State = .idle
    /// Set once a hand-off has been imported; the UI opens it and clears it again.
    private(set) var readyVideoURL: URL?

    /// Name of the video being handed over, for the progress message.
    var pendingName: String? {
        if case .importing(let name) = state { return name }
        return nil
    }

    /// UIKit and SwiftUI can both report the same URL, and SwiftUI can resend a
    /// URL when the scene becomes active again, so identical hand-offs that land
    /// within a second of each other are treated as one.
    private var lastHandled: (url: URL, date: Date)?

    init() {}

    // MARK: - Entry point

    /// Handles a URL delivered by the system.
    /// - Returns: `true` when the URL belonged to this app.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        if url.isFileURL {
            accept(url)
            return true
        }

        guard url.scheme?.caseInsensitiveCompare(Self.scheme) == .orderedSame else { return false }

        if let fileURL = Self.videoFileURL(in: url) {
            accept(fileURL)
        } else {
            // frameextractor:// on its own is a valid "open the app" link.
            logger.info("Opened by URL scheme without a video to import")
        }
        return true
    }

    /// `frameextractor://open?video=<percent-encoded file URL>`
    static func videoFileURL(in url: URL) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let raw = components.queryItems?.first(where: { $0.name == "video" })?.value,
              let fileURL = URL(string: raw),
              fileURL.isFileURL
        else { return nil }
        return fileURL
    }

    private func accept(_ fileURL: URL) {
        guard VideoStore.isSupportedVideo(fileURL) else {
            state = .failed(message: VideoStore.StoreError.unsupportedType(fileURL.lastPathComponent).localizedDescription)
            return
        }

        if let lastHandled, lastHandled.url == fileURL, Date().timeIntervalSince(lastHandled.date) < 1 {
            logger.debug("Ignoring duplicate hand-off for \(fileURL.lastPathComponent, privacy: .public)")
            return
        }
        lastHandled = (fileURL, Date())

        logger.info("Received \(fileURL.lastPathComponent, privacy: .public)")
        Task { await importVideo(at: fileURL) }
    }

    // MARK: - Importing

    /// Copies the video into the app's own storage and publishes it for the UI.
    func importVideo(at url: URL, displayName: String? = nil) async {
        let name = displayName ?? url.lastPathComponent
        state = .importing(name: name)
        do {
            let imported = try await Task.detached(priority: .userInitiated) {
                try VideoStore.importVideo(from: url, originalName: name)
            }.value
            readyVideoURL = imported
            state = .idle
        } catch {
            logger.error("Import failed: \(error.localizedDescription, privacy: .public)")
            state = .failed(message: error.localizedDescription)
        }
    }

    func consumeReadyVideo() {
        readyVideoURL = nil
    }

    // MARK: - Share extension hand-off

    /// Collects videos handed over while the app was closed or in the background
    /// and publishes the newest one for the player.
    ///
    /// Two places are watched: the share extension's App Group container (only
    /// usable when the build is signed with an App Group) and the app's own
    /// Documents folder, which is visible in Files as "On My iPhone → Frame
    /// Extraction Tool" and needs no entitlement.
    ///
    /// - Returns: the most recently imported video, if there was one.
    @discardableResult
    func importHandedOffVideos(from directories: [URL] = VideoInbox.handOffDirectories) async -> URL? {
        // Only videos are taken; anything else in those folders belongs to the user.
        let pending = directories
            .flatMap { VideoInbox.pendingVideos(in: $0) }
            .filter { VideoStore.isSupportedVideo($0) }
        guard !pending.isEmpty else { return nil }

        logger.info("Collecting \(pending.count, privacy: .public) handed-off video(s)")
        var newest: URL?

        for file in pending {
            let displayName = VideoInbox.displayName(for: file)
            do {
                let imported = try await Task.detached(priority: .userInitiated) {
                    try VideoStore.importVideo(from: file, originalName: displayName)
                }.value
                VideoInbox.remove(file)
                newest = imported
            } catch {
                logger.error("Could not collect a handed-off video: \(error.localizedDescription, privacy: .public)")
                // Something the app can never use would be retried on every launch.
                if let storeError = error as? VideoStore.StoreError, case .unsupportedType = storeError {
                    VideoInbox.remove(file)
                }
                if let failure = error as? LocalizedError, let message = failure.errorDescription {
                    state = .failed(message: message)
                }
            }
        }

        if let newest {
            state = .idle
            readyVideoURL = newest
        }
        return newest
    }

    /// Reports a problem from any other way a video can enter the app, so all
    /// hand-offs surface the same alert.
    func reportFailure(_ message: String) {
        state = .failed(message: message)
    }

    func dismissFailure() {
        if case .failed = state { state = .idle }
    }
}
