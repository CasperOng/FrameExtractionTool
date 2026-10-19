//
//  FrameExtractionToolApp.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

@main
struct FrameExtractionToolApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var videoManager = VideoManager()
    private let incomingVideos = IncomingVideoHandler.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(videoManager)
                .environment(incomingVideos)
                .tint(.accentColor)
                .onOpenURL { url in
                    // Covers custom-scheme links; file hand-offs are delivered to
                    // the app delegate below.
                    incomingVideos.handle(url)
                }
        }
    }
}

/// Videos shared to the app, opened from Files, AirDropped or linked with
/// `frameextractor://` arrive through the app delegate.
///
/// UIKit documents `application(_:open:options:)` as the entry point for both
/// file and custom-scheme URLs; SwiftUI's `onOpenURL` is only documented for
/// universal links and custom schemes, so the delegate is the reliable path.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppSettings.registerDefaults()
        VideoStore.removeExpiredImports()
        VideoStore.removeStaleInboxFiles()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        IncomingVideoHandler.shared.handle(url)
    }
}
