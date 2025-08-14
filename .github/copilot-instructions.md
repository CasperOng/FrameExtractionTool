# Copilot Instructions for FrameExtractionTool

## Project Overview
FrameExtractionTool is a SwiftUI-based iOS application for extracting frames from video content. Users can select videos from their photo library, play them back, mark specific frames during playback, and extract those frames as high-quality images saved to their photo library.

## Architecture & Structure

### Project Layout
- **`FrameExtractionTool/`** - Main app source code directory (flat structure)
  - `FrameExtractionToolApp.swift` - App entry point with `@main` annotation
  - `ContentView.swift` - Main app interface with navigation to core features
  - `VideoManager.swift` - Core business logic for video processing and frame extraction
  - `VideoPickerView.swift` - PhotosPicker integration for video selection
  - `VideoPlayerView.swift` - AVKit-based video player with frame marking controls
  - `VideoTimelineView.swift` - Custom timeline with frame markers and seeking
  - `ExtractionProgressView.swift` - Progress tracking during frame extraction
  - `FrameLibraryView.swift` - Gallery view for extracted frames
  - `OnboardingView.swift` - First-time user tutorial
  - `SettingsView.swift` - User preferences and app information
  - `FrameMarkingHelpView.swift` - In-app help and instructions
  - `Assets.xcassets/` - Asset catalog for images, colors, and app icons
  - `Info.plist` - Privacy permissions for photo library access
- **`FrameExtractionToolTests/`** - Unit tests using Swift Testing framework
- **`FrameExtractionToolUITests/`** - UI tests using XCTest and XCUIApplication

### Key Technical Decisions
- **Swift 5.0** with modern concurrency enabled (`SWIFT_APPROACHABLE_CONCURRENCY = YES`)
- **MainActor isolation by default** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- **iOS 26.0+ deployment target** for latest iOS features and frameworks
- **Universal app** supporting both iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`)
- **No external dependencies** - uses only system frameworks and Xcode's build system

## Development Conventions

### Core Video Processing (VideoManager.swift)
- **ObservableObject pattern**: Uses `@MainActor` class with `@Published` properties for UI state
- **AVFoundation integration**: `AVAssetImageGenerator` for high-quality frame extraction
- **Photo library access**: PHPhotoLibrary for saving extracted frames with proper permissions
- **Async operations**: Frame extraction uses `async/await` with progress tracking
- **Haptic feedback**: Configurable user feedback for interactions

### SwiftUI Architecture Patterns
- **Navigation**: NavigationStack with sheet/fullScreenCover presentations
- **State management**: `@StateObject` for managers, `@State` for local UI state
- **Custom components**: Reusable views like VideoTimelineView, OnboardingView
- **Preview macros**: Use `#Preview` for all views instead of legacy PreviewProvider

### Video Player Implementation (VideoPlayerView.swift)
- **AVPlayer integration**: Direct AVPlayer usage with SwiftUI VideoPlayer wrapper
- **Timeline controls**: Custom gesture handling for seek operations
- **Frame marking**: Real-time CMTime tracking with visual timeline markers
- **Overlay UI**: Floating controls over video content using ZStack

### User Experience Patterns
- **Onboarding flow**: First-time user tutorial with UserDefaults persistence
- **Progressive disclosure**: Help systems and contextual guidance
- **Haptic feedback**: Optional tactile responses for user actions
- **Error handling**: Graceful photo library permission and extraction error handling

## Development Workflow
1. **Build**: `xcodebuild -project FrameExtractionTool.xcodeproj -scheme FrameExtractionTool build`
2. **Testing**: Use Xcode Test Navigator or `xcodebuild test` command
3. **SwiftUI Previews**: Available in Xcode for rapid UI iteration on all views
4. **Permissions**: Test photo library access in Simulator or device
5. **Video Testing**: Use sample videos from Simulator's photo library

## Data Flow Architecture
- **VideoManager**: Central state management for video selection, frame marking, and extraction
- **MarkedFrame**: Value type containing CMTime timestamps and video references  
- **ExtractedFrame**: Contains original UIImage and metadata for library display
- **UserDefaults**: Stores user preferences (haptic feedback, onboarding completion)

## Integration Points
- **AVFoundation**: Video asset loading, playback control, and frame extraction
- **Photos/PhotosUI**: Video selection picker and photo library saving
- **Core Image**: Image processing pipeline for frame quality preservation
- **SwiftUI + AVKit**: VideoPlayer integration with custom overlay controls
- **System permissions**: Photo library access with proper Info.plist declarations
