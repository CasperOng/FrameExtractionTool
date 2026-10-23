//
//  VideoInbox.swift
//  ShareExtension
//

import Foundation

/// The hand-off between the share extension and the app.
///
/// The two targets are separate containers, so the only way for the extension to
/// give the app a file is a shared App Group. A share extension cannot open the
/// app that contains it: `NSExtensionContext.open(_:completionHandler:)` is
/// documented as supported by the Today and iMessage extension points only.
///
/// The identifiers here must match `VideoInbox.swift` in the FrameExtractionTool
/// target, and the App Group must be in both entitlements files.
enum VideoInbox {

    static let appGroupIdentifier = "group.caspernyong.FrameExtractionTool"
    static let folderName = "SharedInbox"

    /// Extensions the app can extract frames from.
    static let supportedExtensions: Set<String> = ["mov", "mp4", "m4v", "avi", "qt"]

    enum InboxError: LocalizedError {
        case unavailable
        case unsupported(String)
        case copyFailed

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "This build of Frame Extractor cannot receive shared videos. Open the app and add the video from inside it instead."
            case .unsupported(let name):
                return "“\(name)” isn’t a video Frame Extractor can open."
            case .copyFailed:
                return "The video could not be prepared. There may not be enough free space."
            }
        }
    }

    /// Where the extension files videos for the app to collect.
    static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appending(path: folderName, directoryHint: .isDirectory)
    }

    static func isSupportedVideo(_ name: String) -> Bool {
        supportedExtensions.contains((name as NSString).pathExtension.lowercased())
    }

    /// Copies a video into the shared inbox.
    ///
    /// Call this while the source URL is still valid — `loadFileRepresentation`
    /// only keeps its file for the lifetime of its completion handler.
    ///
    /// Filed as `<identifier>~<name>`: the separator is a character `safeName`
    /// never leaves in a name, so the app can split the two reliably.
    @discardableResult
    static func file(_ source: URL, displayName: String) throws -> URL {
        guard let directory else { throw InboxError.unavailable }
        let name = displayName.isEmpty ? source.lastPathComponent : displayName
        guard isSupportedVideo(name) || isSupportedVideo(source.lastPathComponent) else {
            throw InboxError.unsupported(name)
        }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let identifier = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let destination = directory.appending(path: "\(identifier)~\(safeName(name))")
            try FileManager.default.copyItem(at: source, to: destination)
            return destination
        } catch let error as InboxError {
            throw error
        } catch {
            throw InboxError.copyFailed
        }
    }

    /// File names arrive from other apps, so keep them to characters that are
    /// welcome on disk.
    static func safeName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_. "))
        let cleaned = name.unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
            .prefix(80)
        let result = String(cleaned).trimmingCharacters(in: .whitespaces)
        return result.isEmpty ? "Video.mov" : result
    }
}
