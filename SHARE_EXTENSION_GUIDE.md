# Share Extension Troubleshooting Guide

## Overview

The Frame Extractor app includes a Share Extension that allows you to send videos directly from other apps (Photos, Files, Safari, etc.) to Frame Extractor for processing.

## How to Use the Share Sheet

### From Photos App
1. Open the **Photos** app
2. Select a video
3. Tap the **Share** button (square with arrow pointing up)
4. Scroll down in the share sheet
5. Look for **"Frame Extractor"** in the app actions list
6. Tap it - the main app will open with your video ready to mark frames

### From Files App
1. Open the **Files** app
2. Navigate to a video file
3. Long-press the video or tap the share button
4. Find **"Frame Extractor"** in the share sheet
5. Tap it to open in Frame Extractor

### From Safari or Other Apps
1. When viewing a video, tap the Share button
2. Look for **"Frame Extractor"** in the actions
3. Tap to send the video to the app

## Common Issues & Solutions

### Issue: "Frame Extractor" doesn't appear in share menu

**Solution 1: Edit Share Sheet Actions**
1. Open Photos app and select any video
2. Tap the Share button
3. Scroll to the bottom and tap **"Edit Actions"** or the **three dots (...)**
4. Find **"Frame Extractor"** in the list
5. Toggle it **ON** (green)
6. Drag it to the top for easy access
7. Tap **Done**

**Solution 2: Reinstall the App**
1. Delete Frame Extractor from your device
2. Rebuild and reinstall from Xcode
3. Open the app at least once
4. Try sharing a video again

**Solution 3: Reset Share Sheet (iOS)**
1. Go to **Settings** > **General** > **Transfer or Reset iPhone**
2. Tap **Reset** > **Reset Home Screen Layout**
3. This resets all share sheet customizations
4. Reinstall Frame Extractor
5. Configure share sheet again

**Solution 4: Check Extension is Included in Build**
1. In Xcode, select the **ShareExtension** target
2. Go to **Build Phases** > **Embed App Extensions**
3. Ensure **ShareExtension.appex** is listed
4. Clean build folder (⇧⌘K) and rebuild

### Issue: Share extension crashes or doesn't load

**Check Console Logs:**
```bash
# Open Console.app and filter by "Frame Extractor"
# Look for error messages when sharing a video
```

**Common causes:**
- App Group not properly configured
- Extension sandbox restrictions
- Memory limits exceeded (extensions have ~120MB limit)

### Issue: Video doesn't transfer to main app

This is the current issue you're experiencing. Here's what's happening:

**Current Flow:**
1. Share Extension receives video ✅
2. Video copied to App Group shared container ✅
3. URL saved to UserDefaults ✅
4. Main app opens via URL scheme ✅
5. Main app checks for pending video ❌ (Issue here)

**Possible causes:**
1. **Timing issue** - App opens before shared data is written
2. **File permissions** - Shared container not accessible
3. **URL becomes invalid** - Video URL expires after copy

## Debugging Steps

### 1. Check App Group Configuration

**In Xcode:**
1. Select **FrameExtractionTool** target > **Signing & Capabilities**
2. Verify **App Groups** capability is added
3. Ensure `group.caspernyong.FrameExtractionTool` is enabled (✓)
4. Select **ShareExtension** target
5. Verify same App Group is enabled

### 2. Check File Permissions

Run this in the main app to verify shared container access:

```swift
// Add to ContentView.onAppear temporarily
if let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.caspernyong.FrameExtractionTool"
) {
    print("✅ Shared container accessible: \(containerURL)")
    
    let sharedVideos = containerURL.appendingPathComponent("SharedVideos")
    if FileManager.default.fileExists(atPath: sharedVideos.path) {
        let contents = try? FileManager.default.contentsOfDirectory(at: sharedVideos, includingPropertiesForKeys: nil)
        print("📁 Shared videos: \(contents?.count ?? 0)")
    }
} else {
    print("❌ Cannot access shared container")
}
```

### 3. Add Debug Logging

Update `SharedDataManager.swift`:

```swift
func savePendingVideo(url: URL) {
    print("🔵 [ShareExtension] Saving video URL: \(url)")
    sharedDefaults?.set(url.absoluteString, forKey: pendingVideoURLKey)
    sharedDefaults?.set(false, forKey: pendingVideoProcessedKey)
    sharedDefaults?.synchronize()
    print("🔵 [ShareExtension] Saved successfully")
}

func hasPendingVideo() -> Bool {
    let processed = sharedDefaults?.bool(forKey: pendingVideoProcessedKey) ?? false
    let hasURL = sharedDefaults?.string(forKey: pendingVideoURLKey) != nil
    print("🟢 [MainApp] Checking pending video - processed: \(processed), hasURL: \(hasURL)")
    return !processed && hasURL
}
```

### 4. Test Sequence

1. Share a video from Photos
2. Watch Xcode console for logs
3. Check if you see:
   - `🔵 [ShareExtension] Saving video URL`
   - `🟢 [MainApp] Checking pending video`
4. If main app check happens before extension save, add a delay:

```swift
// In ShareViewController, after saving:
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    self.openMainApp()
}
```

## Alternative: Use Document Picker

If the share extension continues to have issues, you can use the built-in document picker:

1. Open Frame Extractor
2. Tap **"Choose Video"**
3. In the photo picker, you can access:
   - Photos library
   - Files app
   - iCloud Drive
   - Other locations

This bypasses the share extension entirely and works reliably.

## Technical Details

### Share Extension Configuration

**Info.plist Settings:**
- `NSExtensionPointIdentifier`: `com.apple.share-services`
- `NSExtensionActivationSupportsMovieWithMaxCount`: 1
- `NSExtensionActivationSupportsVideoWithMaxCount`: 1

**Supported Video Types:**
- `public.movie`
- `public.video`

**App Group:**
- Identifier: `group.caspernyong.FrameExtractionTool`
- Used for: Sharing video files and metadata between extension and main app

### Data Flow

```
Share Extension                  Main App
┌──────────────┐                ┌──────────┐
│ Receive URL  │                │          │
└──────┬───────┘                │          │
       │                        │          │
┌──────▼───────────────────┐   │          │
│ startAccessingSecurity   │   │          │
│ ScopedResource()         │   │          │
└──────┬───────────────────┘   │          │
       │                        │          │
┌──────▼───────────────────┐   │          │
│ Copy to App Group        │   │          │
│ SharedVideos/            │   │          │
└──────┬───────────────────┘   │          │
       │                        │          │
┌──────▼───────────────────┐   │          │
│ Save URL to UserDefaults │   │          │
└──────┬───────────────────┘   │          │
       │                        │          │
┌──────▼───────────────────┐   │          │
│ Open via URL Scheme      │───┼──────────┤
│ frameextractor://open    │   │          │
└──────────────────────────┘   │          │
                                │          │
                          ┌─────▼─────────┐
                          │ checkFor      │
                          │ SharedVideo() │
                          └─────┬─────────┘
                                │          
                          ┌─────▼─────────┐
                          │ Copy to Temp  │
                          └─────┬─────────┘
                                │          
                          ┌─────▼─────────┐
                          │ Play Video    │
                          └───────────────┘
```

## Build Information

- **Version**: 1.2 (synchronized between main app and extension)
- **iOS Target**: 17.0+
- **SDK**: iOS 27.0
- **Code Signing**: Unsigned (development only)

## Next Steps

1. ✅ Glow effects removed
2. ✅ Share extension version synchronized (1.2)
3. 🔄 Test share flow with debug logging
4. 🔄 If issues persist, consider alternative approaches:
   - Use Shortcuts app integration
   - Use document picker only
   - Simplify share extension to just open app with notification

## Support

If you continue to experience issues:
1. Check Console.app for crash logs
2. Enable debug logging in SharedDataManager
3. Test on a physical device (simulators can have share sheet issues)
4. Verify App Groups are properly provisioned in your Apple Developer account
