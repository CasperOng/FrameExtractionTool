//
//  SharedDataManager.swift
//  FrameExtractionTool
//
//  Created by Claude on 11/6/2026.
//

import Foundation

/// Manages shared data between the main app and share extension via App Groups
final class SharedDataManager {
    static let shared = SharedDataManager()

    private let appGroupIdentifier = "group.caspernyong.FrameExtractionTool"
    private let pendingVideoURLKey = "pendingVideoURL"
    private let pendingVideoProcessedKey = "pendingVideoProcessed"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Share Extension Methods

    /// Save a video URL from the share extension
    func savePendingVideo(url: URL) {
        sharedDefaults?.set(url.absoluteString, forKey: pendingVideoURLKey)
        sharedDefaults?.set(false, forKey: pendingVideoProcessedKey)
        sharedDefaults?.synchronize()
    }

    // MARK: - Main App Methods

    /// Check if there's a pending video to process
    func hasPendingVideo() -> Bool {
        guard let processed = sharedDefaults?.bool(forKey: pendingVideoProcessedKey) else {
            return false
        }
        return !processed && sharedDefaults?.string(forKey: pendingVideoURLKey) != nil
    }

    /// Get the pending video URL
    func getPendingVideoURL() -> URL? {
        guard let urlString = sharedDefaults?.string(forKey: pendingVideoURLKey),
              let url = URL(string: urlString) else {
            return nil
        }
        return url
    }

    /// Mark the pending video as processed
    func markVideoAsProcessed() {
        sharedDefaults?.set(true, forKey: pendingVideoProcessedKey)
        sharedDefaults?.synchronize()
    }

    /// Clear all pending video data
    func clearPendingVideo() {
        sharedDefaults?.removeObject(forKey: pendingVideoURLKey)
        sharedDefaults?.removeObject(forKey: pendingVideoProcessedKey)
        sharedDefaults?.synchronize()
    }

    // MARK: - File Copying

    /// Copy video from share extension sandbox to main app's temp directory
    func copyVideoToAppContainer(from sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = sourceURL.lastPathComponent
        let destinationURL = tempDirectory.appendingPathComponent(fileName)

        // Remove existing file if it exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        // Copy the file
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        return destinationURL
    }
}
