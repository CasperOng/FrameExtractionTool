# Changelog

All notable changes to the Frame Extraction Tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.1] - 2025-08-20

### 🗑️ Enhanced Delete Functionality
- **BREAKING ENHANCEMENT**: Delete button now removes frames from BOTH app AND Photos library
- Long-press delete removes frames from Photos library automatically
- Multi-select delete removes all selected frames from Photos library
- No more orphaned photos cluttering your library!

### 🔧 Technical Improvements
- Store photo asset identifiers when saving frames for proper deletion tracking
- Enhanced `saveImageToPhotos()` method to return asset identifiers
- Added `deleteFromPhotoLibrary()` method with proper authorization handling
- Improved delete methods to handle both app memory and photo library deletion
- Support for both regular photos and custom album deletion
- Added comprehensive error handling for photo library operations

### 📱 User Experience
- Seamless deletion experience - users don't need manual photo cleanup
- Automatic photo library permission requests for write access
- Maintains haptic feedback for all delete operations
- Graceful handling when photo assets are already deleted or unavailable

### ⚡ Performance
- Asynchronous photo library deletion prevents UI blocking
- Background deletion tasks for smooth bulk operations
- Proper async/await implementation with continuation-based error handling

## [1.5.0] - 2025-08-19

### ✨ Major New Feature: Advanced Delete Controls
- **Long-press to delete**: Long-press any extracted frame for instant deletion with confirmation
- **Multi-select mode**: Tap "Select" button to enter bulk selection mode
- **Visual selection indicators**: Blue checkmarks and overlays show selected frames
- **Smart toolbar**: Dynamic buttons that adapt based on selection state

### 🎨 UI/UX Enhancements
- Enhanced FrameLibraryView with comprehensive selection state management
- Blue selection overlay with rounded corners for selected frames
- Checkmark circles in top-right corner of selected frames
- "Cancel" button appears during selection mode for easy exit
- "Delete" button only enabled when frames are selected
- Confirmation dialogs prevent accidental single-frame deletion

### 🔧 Technical Architecture
- Added `deleteExtractedFrame()` method to VideoManager
- Added `deleteExtractedFrames()` for efficient bulk deletion
- Added `clearAllExtractedFrames()` method for future use
- Enhanced FrameThumbnailView with selection state support
- Comprehensive state management with `Set<UUID>` for efficient lookups

### 🎯 Haptic Feedback
- Contextual haptic feedback for all delete operations
- Light feedback for single deletion
- Medium feedback for bulk deletion  
- Heavy feedback for clear all operations
- Respects user's haptic feedback preference settings

## [1.4.2] - 2025-08-18

### 🛠️ Build System Improvements
- Fixed app icon configuration for CodeMagic CI/CD builds
- Changed `ASSETCATALOG_COMPILER_APPICON_NAME` from 'FrameExtractionTool' to 'AppIcon'
- Updated AppIcon.appiconset with proper icon sizes for all iOS devices
- Added complete icon assets (20x20 to 1024x1024) for iPhone, iPad, and App Store
- Resolved CodeMagic build failures related to missing app icon assets

### 📱 App Icon Support
- Generated all required app icon sizes using automated tools
- Support for iPhone, iPad, and marketing icons
- Proper asset catalog structure for consistent builds across platforms

## [1.4.1] - 2025-08-18

### 🔧 CI/CD Configuration
- Removed email notifications from CodeMagic builds to prevent delivery issues
- Simplified build artifact workflow for better reliability
- Updated bundle identifier for CodeMagic builds: `caspernyong.FrameExtractionTool.CMTest`
- Removed Slack integration from CI/CD workflows

## [1.4.0] - 2025-08-14

### 🎨 iOS Design Language Update
- Comprehensive UI refresh using iOS SDK design patterns
- Updated all buttons to use `.borderedProminent` style
- Enhanced material design with proper system colors
- Improved accessibility and visual consistency
- Modern iOS 17+ design language throughout the app

### 🎯 Video Player Enhancements  
- **16 video scaling options**: From 0.25x to 4.0x zoom levels
- Custom video player without default Apple controls for professional look
- Enhanced timeline controls with better touch targets
- Improved video player overlay UI with floating controls
- Better gesture handling for seek operations

### 🏠 Custom Album Feature
- **Save to custom photo albums**: Create and organize extracted frames
- Settings integration for custom album name configuration  
- Album creation and management through Photos framework
- User preference persistence for album settings

### ⚠️ Discard Changes Protection
- **Unsaved changes detection**: Warns users before leaving video player
- Smart detection of marked frames that haven't been extracted
- Confirmation dialog prevents accidental loss of work
- Seamless integration with navigation flow

### 🎛️ Settings & Configuration
- Enhanced SettingsView with custom album controls
- Haptic feedback toggle for user preference
- Album name configuration with validation
- App version display and developer information

## [1.3.0] - 2025-08-14

### 📱 Core App Foundation
- Initial SwiftUI-based iOS application
- Video selection from photo library using PhotosPicker
- Custom video player with AVKit integration
- Frame marking during video playback
- High-quality frame extraction using AVFoundation
- Photo library integration for saving extracted frames

### 🎯 Key Features
- Video timeline with visual frame markers
- Extraction progress tracking with animated UI
- Frame library for viewing extracted images
- Full-screen image viewing with zoom and pan
- Onboarding tutorial for new users
- Comprehensive help system

### 🛠️ Technical Foundation
- Modern Swift concurrency with async/await
- MainActor isolation for UI operations
- ObservableObject pattern for state management
- Photos framework integration
- Core Image processing pipeline
- Haptic feedback system

### 📖 Documentation & Setup
- Comprehensive README with screenshots
- GitHub Actions CI/CD pipeline
- Developer documentation
- Project roadmap and contribution guidelines

---

## Development Information

### 🏗️ Architecture
- **Framework**: SwiftUI for modern iOS development
- **Video Processing**: AVFoundation for high-quality frame extraction  
- **Photo Integration**: Photos/PhotosUI for library access
- **State Management**: Combine with ObservableObject pattern
- **Concurrency**: Modern Swift async/await patterns

### 🚀 CI/CD Platforms
- **GitHub Actions**: Automated builds on push/PR with iOS 26 SDK support
- **CodeMagic**: Professional CI/CD with unsigned build artifacts
- **Build Outputs**: Unsigned IPA files for development and testing

### 📄 Developer Account Status
- **No Apple Developer Program membership**: All builds are unsigned
- **Open Source**: Full source code available for learning and contribution
- **Educational Focus**: Designed for development learning and exploration

### 🎯 Project Goals
- Demonstrate modern iOS development practices
- Showcase SwiftUI and AVFoundation capabilities
- Provide practical video frame extraction utility
- Maintain clean, documented, and teachable codebase

---

## Links
- **Repository**: [GitHub - FrameExtractionTool](https://github.com/CasperOng/FrameExtractionTool)
- **Issues**: [Report bugs or request features](https://github.com/CasperOng/FrameExtractionTool/issues)
- **Developer**: Built with ❤️ by Casper N.Y. Ong using SwiftUI and GitHub Copilot
