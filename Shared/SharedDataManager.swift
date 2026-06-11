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

    /// Copy video from share extension to shared container
    func copyVideoToSharedContainer(from sourceURL: URL) throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw NSError(domain: "SharedDataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access App Group container"])
        }

        let fileManager = FileManager.default
        let sharedVideosDirectory = containerURL.appendingPathComponent("SharedVideos", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: sharedVideosDirectory.path) {
            try fileManager.createDirectory(at: sharedVideosDirectory, withIntermediateDirectories: true)
        }

        // Generate unique filename
        let timestamp = Date().timeIntervalSince1970
        let fileName = "\(timestamp)_\(sourceURL.lastPathComponent)"
        let destinationURL = sharedVideosDirectory.appendingPathComponent(fileName)

        // Remove existing file if it exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        // Copy the file
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        return destinationURL
    }

    /// Copy video from shared container to main app's temp directory
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

    /// Clean up old videos in shared container (call periodically)
    func cleanupSharedVideos() throws {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return
        }

        let sharedVideosDirectory = containerURL.appendingPathComponent("SharedVideos", isDirectory: true)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: sharedVideosDirectory.path) else {
            return
        }

        let contents = try fileManager.contentsOfDirectory(at: sharedVideosDirectory, includingPropertiesForKeys: [.creationDateKey])

        // Delete files older than 24 hours
        let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60)

        for fileURL in contents {
            if let creationDate = try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
}
