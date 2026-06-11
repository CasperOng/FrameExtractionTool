//
//  FrameExtractionToolApp.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI

@main
struct FrameExtractionToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // Handle custom URL scheme from share extension
        guard url.scheme == "frameextractor" else { return }

        // The ContentView will check for pending videos on appear
        // No additional action needed here
        print("✅ App opened from share extension with URL: \(url)")
    }
}
