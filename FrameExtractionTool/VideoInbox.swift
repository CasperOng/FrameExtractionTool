//
//  VideoInbox.swift
//  FrameExtractionTool
//

import Foundation

/// Collects the videos the app's share extension filed.
///
/// The extension cannot open this app (`NSExtensionContext.open` is documented as
/// supported only by the Today and iMessage extension points), so it leaves the
/// video in the App Group container and this side moves it into `VideoStore` as
/// soon as the app becomes active.
///
/// The identifiers here must match `VideoInbox.swift` in the ShareExtension
/// target, and the App Group must be in both entitlements files.
enum VideoInbox {

    nonisolated static let appGroupIdentifier = "group.caspernyong.FrameExtractionTool"
    nonisolated static let folderName = "SharedInbox"

    nonisolated static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appending(path: folderName, directoryHint: .isDirectory)
    }

    /// Videos the share extension left behind, oldest first.
    nonisolated static func pendingVideos(in directory: URL? = VideoInbox.directory) -> [URL] {
        guard let directory,
              let entries = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
              )
        else { return [] }

        return entries
            .filter { !$0.hasDirectoryPath }
            .sorted { first, second in
                let firstDate = (try? first.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let secondDate = (try? second.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return firstDate < secondDate
            }
    }

    nonisolated static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Filed videos are named `<identifier>-<original name>`.
    nonisolated static func displayName(for url: URL) -> String {
        let name = url.lastPathComponent
        guard let separator = name.firstIndex(of: "-") else { return name }
        let remainder = name[name.index(after: separator)...]
        return remainder.isEmpty ? name : String(remainder)
    }
}
