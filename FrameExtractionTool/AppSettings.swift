//
//  AppSettings.swift
//  FrameExtractionTool
//

import Foundation

/// User defaults the app reads from several places.
///
/// Defaults are registered with the system rather than written into the store, so
/// "not configured yet" is indistinguishable from "left at the default value"
/// and no defaults are written on first launch.
enum AppSettings {

    enum Key {
        static let hapticsEnabled = "hapticFeedback"
        static let usesCustomAlbum = "useCustomAlbum"
        static let albumName = "customAlbumName"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    static let defaultAlbumName = "Frame Extractor"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.hapticsEnabled: true,
            Key.usesCustomAlbum: false,
            Key.albumName: defaultAlbumName,
            Key.hasSeenOnboarding: false,
        ])
    }

    /// Whether the app adds a light tap to marking, deleting and extracting.
    static var hapticsEnabled: Bool {
        UserDefaults.standard.bool(forKey: Key.hapticsEnabled)
    }

    /// Whether extracted frames are also collected in the user's own album.
    static var usesCustomAlbum: Bool {
        UserDefaults.standard.bool(forKey: Key.usesCustomAlbum)
    }

    /// Name of the custom album, never empty.
    static var albumName: String {
        let name = UserDefaults.standard.string(forKey: Key.albumName) ?? defaultAlbumName
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultAlbumName : trimmed
    }
}

/// Version information for the About section, read from the bundle so it always
/// matches the build that is running.
enum AppVersion {
    static var marketing: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    /// e.g. "1.6.0 (42)"
    static var full: String {
        let build = self.build
        return build.isEmpty || build == "—" ? marketing : "\(marketing) (\(build))"
    }
}
