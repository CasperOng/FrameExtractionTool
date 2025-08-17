<img width="110" height="110" alt="FrameExtractionTool-iOS-ClearDark-1024x1024@1x" src="https://github.com/user-attachments/assets/106a77c4-2cc5-4d6f-a226-9692e072935a" />

# Frame Extraction Tool

A powerful iOS app for extracting high-quality frames from videos with precision timing control.

## Features

🎬 **Video Selection** - Choose videos from your photo library  
📍 **Frame Marking** - Mark specific frames during playback  
💾 **High-Quality Extraction** - Extract frames at original video quality  
📚 **Custom Album Support** - Save extracted frames to custom photo albums  
✨ **Modern UI** - Built with SwiftUI and iOS design guidelines  

## Screenshots
##### Introduction Screen
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 16 18" src="https://github.com/user-attachments/assets/ea1d14c1-40a3-492f-b828-087863a829c1" />
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 16 24" src="https://github.com/user-attachments/assets/6f30dc3f-249d-4d76-b666-55ddfecf2f8f" />
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 16 29" src="https://github.com/user-attachments/assets/d2b33aa8-1b94-412a-a642-210eaf83cf9a" />
<br></br>

##### Working Screen
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 16 36" src="https://github.com/user-attachments/assets/93e679fb-df55-43a6-82be-7b48051c87a4" />
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 16 41" src="https://github.com/user-attachments/assets/0654c714-08db-444e-aee9-1286d4701976" />
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 42 04" src="https://github.com/user-attachments/assets/2ee22adf-afa8-4cf3-81fd-9630d57f787e" />
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 42 59" src="https://github.com/user-attachments/assets/54abc9f5-ae45-4f3d-9b0f-72599b2c3465" />
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 45 22" src="https://github.com/user-attachments/assets/5fd9de52-d3aa-41bd-a1a5-d2df571de886" />
<img width="117.9" height="255.6" alt="Simulator Screenshot - iPhone 14 Pro - 2025-08-14 at 22 45 26" src="https://github.com/user-attachments/assets/2c61380a-3496-4f59-8eb8-82cc6bd2f2f7" />

## Words from the Developer 
This is a very barebone app as a side project of mine. The main goal of this app is to let me know how AI makes app, play around with the SwiftUI, and play with the Icon Composer. This app is very heavily developed using AI. Bugs are expected. Feel free to open a pull request and help me fix :D 

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

## Architecture

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - Video processing and playback
- **Photos/PhotosUI** - Photo library integration
- **Combine** - Reactive programming patterns
- **Swift Concurrency** - Modern async/await patterns

## CI/CD Workflows

This project includes two CI/CD platforms for automated building and testing:

### GitHub Actions
- **Build Trigger**: Push to main branch or pull requests
- **Output**: Unsigned IPA files for development and testing
- **iOS SDK**: Automatically detects and uses latest iOS SDK (iOS 26+)
- **Configuration**: `.github/workflows/build-ipa.yml`

### CodeMagic CI/CD
- **ios-unsigned-workflow**: Standard unsigned builds for development
- **ios-release-workflow**: Release builds triggered by Git tags (v1.0.0, etc.)
- **Output**: Unsigned IPA files suitable for development and testing
- **Configuration**: `codemagic.yaml`

Both platforms produce unsigned IPA files that can be installed on development devices or simulators. No Apple Developer account is required.

## Privacy

This app requires photo library access to:
- Select videos for frame extraction
- Save extracted frames as images
- Create and manage custom photo albums

All processing happens locally on your device. No data is transmitted to external servers.

## Contributing

*Contribution guidelines to be added*

## Support

For questions, issues, or feature requests, please open an issue in this repository.

---

Built with ❤️ by Casper N.Y. Ong using SwiftUI, GitHub Copilot and AVFoundation
