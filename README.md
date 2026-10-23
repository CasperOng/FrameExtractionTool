<img width="110" height="110" alt="FrameExtractionTool-iOS-ClearDark-1024x1024@1x" src="https://github.com/user-attachments/assets/106a77c4-2cc5-4d6f-a226-9692e072935a" />

# Frame Extraction Tool

A powerful iOS app for extracting high-quality frames from videos with precision timing control.

## Features

🎬 **Video Selection** - Choose videos from your photo library  
📥 **Share & Open In** - Send a video to the app from Photos, Files, AirDrop or a link  
📍 **Frame Marking** - Mark specific frames during playback  
💾 **High-Quality Extraction** - Extract frames at original video quality  
📚 **Custom Album Support** - Save extracted frames to custom photo albums  
🗑️ **Smart Delete** - Remove frames from both app AND Photos library  
📱 **Long-Press & Multi-Select** - Advanced deletion with haptic feedback  
♿️ **Accessible** - Dynamic Type, VoiceOver labels, 44 pt hit targets and Reduce Motion support  
✨ **Modern UI** - Native SwiftUI navigation, forms and menus

## 🆕 What's New in v1.6.0

### 📥 **Send Videos Straight to the App**
- **Share sheet & “Open in”**: share a video with Frame Extractor from Photos, Files, Safari or any app — it opens ready to mark
- **AirDrop**: dropping a video on your device now offers Frame Extractor
- **`frameextractor://` links**: automations and Shortcuts can open a video with `frameextractor://open?video=<file URL>`

### ♿️ **Rebuilt to Apple's Guidelines**
- **Dynamic Type**: text scales with your system text size
- **VoiceOver**: labels and hints on every control, plus an adjustable timeline you can scrub with swipe up/down
- **44 pt hit targets** everywhere, including the timeline flags
- **Native navigation and forms**, system materials instead of decorative gradients, and menus in the toolbar
- **Reduce Motion** respected by every animation

### 🔧 **Reliability**
- **Cancelable extraction** — stop a long run and keep the frames already saved
- **Honest results** — the summary reports frames saved and frames that failed
- **Smaller memory use** — the library keeps thumbnails and loads full-resolution frames on demand
- **Fixed album saving** — custom albums need full photo library access and now fall back gracefully instead of failing
- **Fixed the playback time observer leak** and the speed control no longer starts playback on its own

## 🆕 What's New in v1.5.1

### 🗑️ **Complete Photo Library Integration**
- **Smart Delete**: Deleting frames now removes them from BOTH the app AND your Photos library
- **No More Clutter**: No orphaned photos left behind in your camera roll
- **Seamless Experience**: Automatic photo library cleanup with proper permissions

### 📱 **Enhanced Delete Features**
- **Long-Press Delete**: Hold any frame to delete it instantly (with confirmation)
- **Multi-Select Mode**: Tap "Select" to choose multiple frames for bulk deletion  
- **Visual Feedback**: Blue selection overlays and haptic feedback for all operations
- **Smart Controls**: Context-aware toolbar that adapts to your selection

### ⚡ **Performance & Reliability**
- **Background Deletion**: Photo library cleanup happens asynchronously
- **Error Handling**: Graceful handling of already-deleted or missing assets
- **Permission Management**: Automatic photo library write access requests

## ⚠️ Developer Account Status

**Important Notice**: This project is developed without an Apple Developer Program membership. This means:

- ❌ **No App Store Distribution** - The app cannot be published to the App Store
- ❌ **No Code Signing** - All builds are unsigned and for development/testing only
- ❌ **No TestFlight** - No distribution through Apple's beta testing platform
- ✅ **Open Source** - Full source code available for learning and contribution
- ✅ **Local Development** - Can be built and run locally using Xcode
- ✅ **CI/CD Builds** - Automated unsigned builds available through GitHub Actions and CodeMagic

If you want to use this app on your device, you'll need to build it yourself using Xcode or use the unsigned IPA files for development purposes.

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

**Note**: Since this project doesn't have an Apple Developer Program membership, the app is not available on the App Store and cannot be code signed for general distribution.

### Option 1: Build from Source (Recommended)
1. Clone this repository
2. Open `FrameExtractionTool.xcodeproj` in Xcode
3. Connect your iOS device or use the simulator
4. Build and run directly from Xcode

### Option 2: Unsigned IPA Installation
*For advanced users with development tools*
- Download unsigned IPA files from GitHub Actions or CodeMagic CI/CD builds
- Install using development tools like Xcode, iOS App Installer, or enterprise deployment methods
- **Note**: Unsigned apps have limitations and may require re-installation periodically

### Option 3: Fork and Sign Yourself
If you have an Apple Developer Program membership:
1. Fork this repository
2. Update the bundle identifier in the project settings
3. Configure code signing with your developer certificate
4. Build and distribute as needed

### Option 4: Feather / AltStore Source
Every build of `main` is published as an unsigned IPA, and a separate repository turns it into a sideloading source:

1. Open [Feather](https://github.com/khcrysalis/Feather) → **Sources** → **+**
2. Add `https://raw.githubusercontent.com/CasperOng/frame-extraction-tool-feather/main/apps.json`
3. Install **Frame Extractor** and let Feather sign it with your own certificate

The feed updates itself from the newest build, so this is the quickest way to run the current code on a device. See [frame-extraction-tool-feather](https://github.com/CasperOng/frame-extraction-tool-feather) for details.

## How to Use

1. **Launch the app** and complete the onboarding tutorial
2. **Select a video** from your photo library using the video picker
3. **Play the video** and use the timeline to navigate to desired frames
4. **Mark frames** by tapping the plus button during playback
5. **Review marked frames** on the timeline and along the bottom of the player
6. **Extract frames** to save high-quality images to your photo library
7. **Manage settings** including custom album names and haptic feedback

### Starting from another app

You do not have to pick a video inside the app first — Frame Extractor can be handed a video:

- **Share sheet** — in Photos, Messages, Files, Safari or any other app, tap Share and choose **Frame Extractor**.
  - If the build was signed with the App Group the extension uses, the video is handed over automatically: open the app and the player is already showing it.
  - Otherwise (self-signed builds, including Feather) the sheet offers **Save to Frame Extractor…**. Save the video into **On My iPhone → Frame Extraction Tool**, then open the app — it imports the video the moment it comes to the foreground.
- **Open in / Open with** — in Files, share a video and choose **Frame Extractor**, or double-click it on a device with a keyboard. This route launches the app straight into the player.
- **Drop it in the app's folder** — with file sharing on, any video saved to **On My iPhone → Frame Extraction Tool** (in Files) is picked up next time the app opens.
- **Links and Shortcuts** — open `frameextractor://` to launch the app, or `frameextractor://open?video=<percent-encoded file URL>` to open a specific video. In Shortcuts, use **Open URLs** with that link.

> **Why the share extension can't jump straight into the app:** iOS only supports a share extension opening its containing app through the Today and iMessage extension points, so the extension has to hand the file over through a container and the app collects it when it becomes active. The confirmation sheet says which route is being used.

> **Signing note:** the automatic hand-off relies on the App Group `group.caspernyong.FrameExtractionTool`, which must be authorised by the provisioning profile that signs the app and its extension. Xcode's automatic signing with a team that has the App Groups capability does this for you; personal teams cannot, which is why the Files route exists.

## Architecture

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - Video processing and playback
- **Photos/PhotosUI** - Photo library integration
- **Swift Observation** - `@Observable` models driving SwiftUI
- **Swift Concurrency** - Modern async/await patterns
- **UniformTypeIdentifiers** - Deciding which files the app can open

## CI/CD Workflows

This project includes two CI/CD platforms for automated building and testing:

### GitHub Actions
- **Build Trigger**: Push to main branch or pull requests
- **Output**: Unsigned IPA files for development and testing
- **iOS SDK**: Automatically detects and uses latest iOS SDK (iOS 26+)
- **Configuration**: `.github/workflows/build-ipa.yml`

### GitHub Actions: Tests
- **Unit tests** (`FrameExtractionToolTests`) and **UI smoke tests** (`FrameExtractionToolUITests`)
- **Configuration**: `.github/workflows/tests.yml`
- Runs on a simulator chosen at runtime, so it works on any runner image

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

Built with ❤️ by **Casper N.Y. Ong** using SwiftUI, GitHub Copilot and AVFoundation — [casperong.is-a.dev](https://casperong.is-a.dev)

The same credit, signature and all, closes the app's home screen and Settings screen.
