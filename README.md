# Frame Extraction Tool

A powerful iOS app for extracting high-quality frames from videos with precision timing control.

## Features

🎬 **Video Selection** - Choose videos from your photo library  
📍 **Frame Marking** - Mark specific frames during playback  
💾 **High-Quality Extraction** - Extract frames at original video quality  
📚 **Custom Album Support** - Save extracted frames to custom photo albums  
✨ **Modern UI** - Built with SwiftUI and iOS design guidelines  

## Screenshots

*Screenshots coming soon*

## Requirements

- iOS 17.0 or later
- iPhone or iPad
- Photo library access permission

## Installation

### Option 1: Build from Source
1. Clone this repository
2. Open `FrameExtractionTool.xcodeproj` in Xcode
3. Build and run on your device

### Option 2: IPA Installation
*For advanced users with developer tools or enterprise deployment*

## How to Use

1. **Launch the app** and complete the onboarding tutorial
2. **Select a video** from your photo library using the video picker
3. **Play the video** and use the timeline to navigate to desired frames
4. **Mark frames** by tapping the mark button during playback
5. **Review marked frames** in the timeline (red markers)
6. **Extract frames** to save high-quality images to your photo library
7. **Manage settings** including custom album names and haptic feedback

## Key Components

### Video Player
- Custom implementation using AVFoundation
- 16 scaling options (Fit, Fill, Stretch, etc.)
- Professional timeline with frame markers
- Gesture-based seeking and controls

### Frame Extraction
- Original video quality preservation
- Batch extraction with progress tracking
- Custom album organization
- Photo library integration

### User Experience
- SwiftUI-based modern interface
- iOS design language compliance
- Configurable haptic feedback
- Comprehensive help system

## Architecture

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - Video processing and playback
- **Photos/PhotosUI** - Photo library integration
- **Combine** - Reactive programming patterns
- **Swift Concurrency** - Modern async/await patterns

## Version History

### v1.2.0 (Current)
- Added custom album support with settings
- Implemented discard confirmation for unsaved changes
- Enhanced video player with 16 scaling options
- Improved timeline scrolling and positioning
- Professional video player without default Apple controls

### v1.1.0
- Video scaling feature with multiple options
- iOS SDK styling throughout the app
- Enhanced user interface polish

### v1.0.0
- Initial release with core frame extraction functionality
- Video selection and playback
- Frame marking and extraction
- Basic photo library saving

## Technical Details

- **Target:** iOS 17.0+
- **Architecture:** Universal (iPhone/iPad)
- **Language:** Swift 5.0 with modern concurrency
- **Frameworks:** SwiftUI, AVFoundation, Photos, Combine
- **Build System:** Xcode project with automatic Info.plist generation

## Privacy

This app requires photo library access to:
- Select videos for frame extraction
- Save extracted frames as images
- Create and manage custom photo albums

All processing happens locally on your device. No data is transmitted to external servers.

## License

*License information to be added*

## Contributing

*Contribution guidelines to be added*

## Support

For questions, issues, or feature requests, please open an issue in this repository.

---

Built with ❤️ by Casper N.Y. Ong using SwiftUI, GitHub Copilot and AVFoundation
