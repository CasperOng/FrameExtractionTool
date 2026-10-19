//
//  VideoStore.swift
//  FrameExtractionTool
//
//  Videos that come from outside the app — the photo picker, the share sheet,
//  "Open in", AirDrop or a `frameextractor://` link — are copied here first.
//

import Foundation
import UniformTypeIdentifiers

/// Owns the files the app works with.
///
/// Frame extraction reads the source video again for every marked frame and for
/// as long as an editing session lasts, so the video has to be a plain file
/// inside the app's container. A URL handed over by another process (a
/// security-scoped URL, or one that lives in the sender's temporary directory)
/// can stop being readable at any moment, which is why `importVideo(from:)`
/// makes a copy instead of using it directly.
enum VideoStore {

    enum StoreError: LocalizedError, Equatable {
        case unsupportedType(String)
        case unreadable(String)
        case copyFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedType(let name):
                return "“\(name)” isn’t a video this app can open."
            case .unreadable(let name):
                return "“\(name)” couldn’t be read. It may have been moved or deleted."
            case .copyFailed(let name):
                return "“\(name)” couldn’t be prepared for editing. Check that the device has enough free space."
            }
        }
    }

    /// Videos imported from other apps, newest last. Kept out of iCloud backups
    /// because they are copies of files the user already has.
    nonisolated static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "ImportedVideos", directoryHint: .isDirectory)
    }

    /// How long an untouched import is kept before it is cleaned up.
    nonisolated static let retentionInterval: TimeInterval = 7 * 24 * 60 * 60

    // MARK: - Validation

    /// Whether the app can extract frames from this file.
    nonisolated static func isSupportedVideo(_ url: URL) -> Bool {
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type.conforms(to: .movie) || type.conforms(to: .video)
        }
        return UTType(filenameExtension: url.pathExtension)?.conforms(to: .movie) ?? false
    }

    // MARK: - Importing

    /// Copies `url` into the app's own storage and returns the new location.
    ///
    /// Performs blocking file I/O and file reads of possibly several gigabytes,
    /// so call it off the main actor.
    nonisolated static func importVideo(from url: URL, originalName: String? = nil) throws -> URL {
        let name = originalName ?? url.lastPathComponent

        // Files handed over by another app arrive security-scoped: take access
        // before reading anything, including the file's type.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard isSupportedVideo(url) else { throw StoreError.unsupportedType(name) }
        guard FileManager.default.isReadableFile(atPath: url.path) else { throw StoreError.unreadable(name) }

        let destination = try uniqueDestination(for: name)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
        } catch {
            throw StoreError.copyFailed(name)
        }

        excludeFromBackup(destination)
        removeInboxCopy(of: url)
        return destination
    }

    /// A free file name inside `directory`, keeping the original name readable.
    nonisolated static func uniqueDestination(for name: String) throws -> URL {
        try createDirectoryIfNeeded()
        let base = sanitizedBaseName(name)
        let ext = (name as NSString).pathExtension
        let suffix = ext.isEmpty ? "" : ".\(ext)"

        var candidate = directory.appending(path: "\(base)\(suffix)")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appending(path: "\(base)-\(counter)\(suffix)")
            counter += 1
        }
        return candidate
    }

    nonisolated private static func sanitizedBaseName(_ name: String) -> String {
        let stem = (name as NSString).deletingPathExtension
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let cleaned = stem.unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
            .prefix(60)
        let result = String(cleaned).trimmingCharacters(in: .whitespaces)
        return result.isEmpty ? "Video" : result
    }

    // MARK: - Housekeeping

    nonisolated static func createDirectoryIfNeeded() throws {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Deletes imports that have not been touched for `retentionInterval`.
    @discardableResult
    nonisolated static func removeExpiredImports(
        in directory: URL = VideoStore.directory,
        now: Date = Date()
    ) -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var removed: [URL] = []
        for url in urls {
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            if now.timeIntervalSince(modified) > retentionInterval {
                do {
                    try FileManager.default.removeItem(at: url)
                    removed.append(url)
                } catch {
                    // A locked or in-use file is simply retried next launch.
                }
            }
        }
        return removed
    }

    /// `Documents/Inbox` is where iOS drops files for "Open in" when the app does
    /// not open documents in place. The import moves the file out of it, so
    /// anything still sitting there is left over from an interrupted hand-off.
    @discardableResult
    nonisolated static func removeStaleInboxFiles(olderThan interval: TimeInterval = 60 * 60, now: Date = Date()) -> [URL] {
        guard let inbox = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appending(path: "Inbox", directoryHint: .isDirectory) else { return [] }
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: inbox,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var removed: [URL] = []
        for url in urls {
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            guard now.timeIntervalSince(modified) > interval else { continue }
            do {
                try FileManager.default.removeItem(at: url)
                removed.append(url)
            } catch {
                // Nothing to do; it will be retried on the next launch.
            }
        }
        return removed
    }

    nonisolated private static func removeInboxCopy(of source: URL) {
        guard source.path.contains("/Documents/Inbox/") else { return }
        try? FileManager.default.removeItem(at: source)
    }

    nonisolated private static func excludeFromBackup(_ url: URL) {
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }
}
