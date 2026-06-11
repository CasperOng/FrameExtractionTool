# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Frame Extraction Tool** is a SwiftUI-based iOS app (iOS 17.0+) that extracts high-quality frames from videos with precision timing control. The app allows users to mark specific frames during playback, then extract and save them to a custom photo album. The app is developed without an Apple Developer Program membership, so builds are unsigned and intended for development/testing.

## Build & Development Commands

### Building the app
```bash
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool build
```

### Building for simulator
```bash
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool -destination 'platform=iOS Simulator,name=iPhone 14 Pro' build
```

### Running unit tests
```bash
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool test
```

### Running UI tests
```bash
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionToolUITests test
```

### Building unsigned archive for release
```bash
xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool -configuration Release -destination 'generic/platform=iOS' -archivePath build/FrameExtractionTool.xcarchive archive CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### Preferred: Use Xcode directly
For most development work, open the project in Xcode and build/run from the IDE, especially when testing UI or debugging:
```bash
open FrameExtractionTool.xcodeproj
```

## Architecture & Structure

### Core Layers

**VideoManager** (VideoManager.swift): The central state container (ObservableObject) managing video selection, frame marking, and frame extraction. This is the main ViewModel that UI views observe. Key responsibilities:
- Managing marked frames and extracted frames state
- Coordinating video playback and frame extraction logic
- Handling haptic feedback based on user preferences
- Managing photo library integration (reading and writing)

**UI Views**: SwiftUI view hierarchy organized by feature:
- `FrameExtractionToolApp.swift` - App entry point, single WindowGroup with ContentView
- `ContentView.swift` - Main tab/navigation controller for the app
- `VideoPickerView.swift` - Video selection from photo library
- `VideoPlayerView.swift` - Video playback with AVPlayer, handles frame marking UI
- `VideoTimelineView.swift` - Visual timeline showing marked frames and playback position
- `FrameLibraryView.swift` - Gallery of extracted frames, supports selection and deletion
- `ExtractionProgressView.swift` - Progress indicator during frame extraction
- `SettingsView.swift` - User preferences (album name, haptic feedback, etc.)
- `OnboardingView.swift` - Tutorial/intro screen on first launch
- `FrameMarkingHelpView.swift` - Help documentation for frame marking

### Data Models

Key model types (inferred from VideoManager usage):
- `MarkedFrame` - Represents a frame marked for extraction, contains timestamp and video URL
- `ExtractedFrame` - Represents an extracted frame saved to photo library, includes photo asset identifier for deletion

### Framework Dependencies

- **SwiftUI** - Declarative UI framework
- **AVFoundation** - Video playback (AVPlayer), frame extraction, timing (CMTime)
- **Photos/PhotosUI** - Photo library access, custom album management
- **CoreImage** - Image processing (likely for frame conversion)
- **Combine** - Reactive publishers for ObservableObject
- **Swift Concurrency** - async/await patterns for async operations (photo library writes/deletes)

### Key Design Patterns

- **MVVM**: Views observe VideoManager (ViewModel)
- **State Management**: Single source of truth in VideoManager via @Published properties
- **MainActor**: VideoManager marked with @MainActor to ensure UI updates on main thread
- **Photo Library Integration**: Uses Photos framework with PHPhotoLibrary for read/write access and custom albums

## CI/CD

### GitHub Actions
- **File**: `.github/workflows/build-ipa.yml`
- **Trigger**: Push to main or pull requests, Git tags (v*)
- **Output**: Unsigned IPA files for testing
- **Releases**: Creates GitHub pre-releases for tagged versions with auto-generated changelogs
- Automatically detects latest iOS SDK

### CodeMagic
- **File**: `codemagic.yaml`
- **Workflows**: 
  - `ios-unsigned-workflow` - Standard builds for development
  - `ios-release-workflow` - Release builds triggered by Git tags (v1.0.0 format), creates GitHub pre-releases
- **Build Environment**: M1 Mac mini instance
- **Output**: Unsigned IPA files
- **Notifications**: Discord webhook notifications (requires WEBHOOK_URL in discord_credentials group)
- **GitHub Releases**: Requires GITHUB_TOKEN in environment to create pre-releases (optional)

Note: Both CI systems build with code signing disabled (`CODE_SIGNING_REQUIRED=NO`) and create **pre-releases** on GitHub for tagged versions.

## Important Notes

- **No Code Signing**: This project cannot be code-signed or distributed via App Store. All builds are unsigned for development/testing only.
- **Haptic Feedback**: Stored in UserDefaults under key "hapticFeedback", defaults to enabled
- **Photo Library Permissions**: App requires photo library read/write permissions
- **Swift Concurrency**: Photo library operations use async/await; always wrap in Task when called from sync contexts
- **Custom Albums**: Users can customize the photo album name where frames are saved (stored in UserDefaults)
- **App Groups**: Uses `group.caspernyong.FrameExtractionTool` for sharing data between main app and share extension

## Share Extension

The app includes a Share Extension that allows users to send videos directly from other apps (Photos, Files, Safari, etc.).

### How to Use
1. Open Photos, Files, or any app with videos
2. Select a video and tap the Share button
3. Choose "Frame Extractor" from the share sheet
4. The main app will open with the video ready for frame marking

### Technical Details
- **Extension Bundle ID**: `caspernyong.FrameExtractionTool.ShareExtension`
- **App Group**: `group.caspernyong.FrameExtractionTool`
- **Supported Types**: All video formats (public.movie, public.video)
- **Data Sharing**: Uses App Group UserDefaults for inter-process communication
- **URL Scheme**: `frameextractor://` for opening main app from extension

### Architecture
- `ShareViewController.swift` - Extension entry point with SwiftUI view
- `SharedDataManager.swift` - Manages data exchange between app and extension
- Videos are copied to main app's temp directory for processing
- Main app checks for pending videos on launch/foreground

### Development Notes
- Share extension runs in separate process with limited memory (~120MB)
- Videos are passed via URL, not loaded in extension memory
- Shared data is automatically cleared after successful import
- Extension must be added as a target in Xcode project

## Testing Notes

- Unit tests are minimal; UI testing is the primary verification method
- Test the golden path: select video → play → mark frames → extract → verify in photo album
- When modifying photo library integration, verify both app-side deletion and actual Photos app cleanup work correctly
- Haptic feedback should be tested on physical device (simulator has limited haptic support)
- **Share Extension Testing**: Test sharing videos from Photos, Files, and Safari to verify the extension appears and works correctly
