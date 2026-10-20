# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Frame Extraction Tool** is a SwiftUI-based iOS app (iOS 17.0+) that extracts high-quality frames from videos with precision timing control. The app allows users to mark specific frames during playback, then extract and save them to a custom photo album. Videos can also be handed to the app from other apps (share sheet, "Open in", AirDrop, `frameextractor://` links).

The app is developed without an Apple Developer Program membership, so builds are unsigned and intended for development/testing.

## Build, Test & CI/CD

**Do not build or test on the development machine.** GitHub Actions is the source of truth for building and testing; run work through CI and read the results there.

| Workflow | What it does |
| --- | --- |
| `.github/workflows/build-ipa.yml` | Unsigned IPA on push to `main`/`develop`, PRs, tags; creates pre-releases for `v*` tags and refreshes the rolling `latest` release that the Feather feed reads |
| `.github/workflows/build-ipa-ios27.yml` | Same build against the newest iOS SDK |
| `.github/workflows/tests.yml` | Unit tests (`FrameExtractionToolTests`) and UI smoke tests (`FrameExtractionToolUITests`) on a simulator picked at runtime |

Sideloading: `CasperOng/frame-extraction-tool-feather` is a public Feather source that commits the newest unsigned IPA and its `apps.json`. Its `refresh.yml` pulls the IPA from the `latest` release every six hours; a `FEED_DISPATCH_TOKEN` secret in this repository makes it immediate.

Useful commands:

```bash
gh run list --limit 5                     # recent runs
gh run watch                              # follow the run for the current commit
gh run view --log-failed                  # what broke
gh workflow run tests.yml                 # re-run tests for a branch
```

For reference, the equivalent local commands are:

```bash
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool -destination 'platform=iOS Simulator,name=iPhone 17' test
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool -configuration Release -destination 'generic/platform=iOS' -archivePath build/FrameExtractionTool.xcarchive archive CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Architecture & Structure

### Core Layers

**VideoManager** (`VideoManager.swift`): `@Observable` source of truth for the loaded video, marked frames, extracted frames and extraction progress. Owns photo library access (authorization, saving, album handling, deletion) and the `AVAssetImageGenerator` pipeline.

**IncomingVideoHandler** (`IncomingVideoHandler.swift`): turns a URL delivered by the system — a file hand-off or a `frameextractor://` link — into an imported video and publishes it for the UI. Reachable as `.shared` and injectable for tests.

**VideoStore** (`VideoStore.swift`): file storage for imported videos (`Application Support/ImportedVideos`). Validates the file type with `UTType`, copies videos out of the sender's sandbox, keeps names unique, and clears out stale imports and `Documents/Inbox` leftovers at launch.

**ShareExtension** (`ShareExtension/`): a share extension for apps whose share sheet only lists extensions (Photos, Messages). A share extension cannot open its containing app, so `VideoInbox.swift` files the video in the shared App Group container and the app collects it when it becomes active. `ShareViewController.swift` holds the receiver and its short confirmation sheet.

**AppSettings** (`AppSettings.swift`): defaults keys, default registration, and bundle version helpers.

### UI Views

- `FrameExtractionToolApp.swift` — app entry point: `WindowGroup`, environment objects, `UIApplicationDelegateAdaptor`, `onOpenURL`
- `ContentView.swift` — root `NavigationStack`; empty state or library summary, photo picker, player and tutorial presentation
- `VideoImport.swift` — `MovieFile` `Transferable` (imports the picked video off the main actor) and `VideoImporter`
- `VideoPlayerView.swift` — video surface without system controls, mark button, transport controls, playback options menu
- `VideoTimelineView.swift` — scrub bar with marked-frame flags and a marked-frame strip
- `FrameLibraryView.swift` — grid of extracted frames, selection, deletion, full-screen detail with zoom and share
- `ExtractionProgressView.swift` — progress, cancel, and the result summary
- `SettingsView.swift` — grouped `Form` with haptics, album, tutorial and version
- `DeveloperCreditView.swift` — signature, name and credit line linking to casperong.is-a.dev, shown on the home screen and in Settings
- `OnboardingView.swift` — first-run tour (also shown from Settings)
- `FrameMarkingHelpView.swift` — short instructions inside the player
- `DesignSystem.swift` — `AppTheme` tokens (semantic typography, spacing, motion), press states, haptics

### Data Models

In `FrameModels.swift`:
- `MarkedFrame` — a frame marked for extraction (time and source video), with formatted and spoken time strings
- `ExtractedFrame` — a saved frame: an in-memory thumbnail, the photo library identifier, and the source mark
- `ExtractionSummary` / `ExtractionError` — result reporting

### Framework Dependencies

SwiftUI, AVFoundation, Photos/PhotosUI, UniformTypeIdentifiers, Observation, OSLog

### Key Design Patterns

- **`@Observable` models** injected with `.environment(...)`, read with `@Environment(Type.self)`
- **MainActor by default** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`); file I/O is marked `nonisolated` and run in `Task.detached`
- **One modal at a time** — the player and the tutorial are full-screen covers, everything else is a push or a sheet
- **Accessibility is part of the design**: semantic text styles, VoiceOver labels/hints, 44 pt hit targets, Reduce Motion

## Bringing Videos Into the App

`FrameExtractionTool/Info.plist` is a *partial* Info.plist: Xcode generates the rest from the target's `INFOPLIST_KEY_*` build settings and merges them with this file, so only keys with no build setting belong in it.

It declares:

- `CFBundleDocumentTypes` for the movie UTIs, with `LSHandlerRank = Alternate` so the app offers to open videos without becoming the system default
- `LSSupportsOpeningDocumentsInPlace = false`, so iOS copies handed-over files into `Documents/Inbox`
- `CFBundleURLTypes` with the `frameextractor` scheme

Delivery paths:

- **Open in / Files / share sheet of apps that share documents**: `application(_:open:options:)` on `AppDelegate` (SwiftUI's `onOpenURL` is only documented for universal links and custom schemes, so the delegate is the reliable path for files) — `onOpenURL` is also wired up and duplicates are filtered in `IncomingVideoHandler`
- **Apps whose share sheet only lists extensions (Photos, Messages)**: the `ShareExtension` target. A share extension cannot open its containing app — `NSExtensionContext.open(_:completionHandler:)` is documented as supported by the Today and iMessage extension points only — so it copies the video into the shared App Group container (`VideoInbox`), says so in a short confirmation sheet, and the app collects it when it becomes active (`ContentView` scene phase → `IncomingVideoHandler.importSharedVideos`)
- **Photo library**: `PhotosPicker` in `ContentView`, imported through `MovieFile`
- Everything ends up in `VideoStore`, and `IncomingVideoHandler.readyVideoURL` opens the player

Notes:

- The file hand-off is asynchronous: the UI shows a "Preparing Video" overlay while a large video is copied
- Unsuitable files (a PDF opened with the app, for example) surface a readable alert instead of failing silently
- `VideoInbox.swift` exists in both targets on purpose — they are separate containers and cannot share code without extra target membership. The App Group identifier and folder name must match, and the group must be in both entitlements files
- The App Group needs a provisioning profile that authorises it; without one the extension reports the problem instead of failing silently
- Tests for the hand-off live in `FrameExtractionToolTests/SharedInboxTests.swift` and drive the inbox directly, so they need no extension or device

## Important Notes

- **No Code Signing**: this project cannot be code-signed or distributed via the App Store. All builds are unsigned for development/testing only.
- **Haptic Feedback**: stored in UserDefaults under key `hapticFeedback` (default `true`, registered in `AppSettings.registerDefaults()`)
- **Photo Library Permissions**: adding frames needs add-only access; albums and deletion need read-write access. The app degrades gracefully when only add-only access is granted.
- **Custom Albums**: name stored under `customAlbumName`
- **Memory**: extracted frames are held as thumbnails (`ExtractedFrame.thumbnail`); full-resolution images are fetched from the photo library on demand with `PHImageManager`
- **Entitlements**: there is no entitlements file — the App Group from the removed share extension is gone

## Testing Notes

- Unit tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`), UI tests use XCTest
- Prefer unit tests for logic (formatting, importing, URL handling); the UI tests are smoke tests for launch, the empty state, Settings and the tutorial
- Test the golden path manually when a change touches them: choose a video → play → mark frames → extract → verify in the photo album
- Share/open-in paths can be exercised by opening a file URL from another app, AirDropping a video, or opening `frameextractor://open?video=…`
- When modifying photo library integration, verify both app-side deletion and actual Photos app cleanup
- Haptic feedback should be tested on a physical device (simulator has limited haptic support)
