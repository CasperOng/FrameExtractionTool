# Share Extension Setup Guide

This guide walks you through the manual Xcode configuration needed to complete the Share Extension integration.

## Prerequisites

All code files have been created in your project directory:
- ✅ `ShareExtension/ShareViewController.swift` - Extension view controller
- ✅ `ShareExtension/Info.plist` - Extension configuration
- ✅ `ShareExtension/ShareExtension.entitlements` - Extension entitlements
- ✅ `Shared/SharedDataManager.swift` - Shared data manager
- ✅ `FrameExtractionTool/FrameExtractionTool.entitlements` - Main app entitlements
- ✅ Main app files updated (ContentView, VideoManager, FrameExtractionToolApp)

**Note:** These files exist in your file system but are NOT yet part of the Xcode project. The steps below will integrate them.

## Manual Xcode Configuration Steps

### Step 1: Add Share Extension Target

1. Open `FrameExtractionTool.xcodeproj` in Xcode
2. Click on the project in the navigator (top-level "FrameExtractionTool")
3. At the bottom of the targets list, click the **"+"** button
4. Select **"Share Extension"** template under iOS
5. Configure the new target:
   - **Product Name**: `ShareExtension`
   - **Team**: Select your team (or leave as-is for unsigned)
   - **Language**: Swift
   - **Bundle Identifier**: `caspernyong.FrameExtractionTool.ShareExtension`
6. Click **"Finish"**
7. When prompted "Activate 'ShareExtension' scheme?", click **"Cancel"** (we'll use the main scheme)

### Step 2: Replace Generated Files with Our Custom Implementation

Xcode creates default Share Extension files. We need to use our custom implementation instead:

1. In Finder, navigate to your project folder
2. You'll see two `ShareExtension` folders:
   - One we created with our custom files (in the project root)
   - One Xcode just created (inside the Xcode project structure)

3. **In Xcode's Project Navigator:**
   - Find the `ShareExtension` folder Xcode created
   - **Delete** it completely (select and press Delete → "Move to Trash")

4. **Drag our ShareExtension folder into Xcode:**
   - In Finder, locate the `ShareExtension` folder (with our custom files)
   - Drag the entire folder into Xcode's Project Navigator
   - In the dialog that appears:
     - ✅ Check "Copy items if needed"
     - ✅ Select "Create groups"
     - ✅ Check the **ShareExtension** target only (uncheck FrameExtractionTool)
     - Click "Finish"

5. **Verify the files are in the ShareExtension target:**
   - Select `ShareViewController.swift`
   - In File Inspector (right panel), verify **ShareExtension** target is checked

### Step 3: Add Shared Files to Both Targets

The `SharedDataManager` needs to be accessible by both the main app and extension:

1. Select `Shared/SharedDataManager.swift` in the Project Navigator
2. In the File Inspector (right panel), under **"Target Membership"**:
   - ✅ Check **FrameExtractionTool**
   - ✅ Check **ShareExtension**

### Step 4: Configure App Groups

**For the Main App Target:**

1. Select the **FrameExtractionTool** target
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"** → Select **"App Groups"**
4. Click **"+"** under App Groups → Enter: `group.caspernyong.FrameExtractionTool`
5. Ensure the entitlements file is set to `FrameExtractionTool/FrameExtractionTool.entitlements`

**For the Share Extension Target:**

1. Select the **ShareExtension** target
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"** → Select **"App Groups"**
4. Click **"+"** under App Groups → Enter: `group.caspernyong.FrameExtractionTool`
5. Ensure the entitlements file is set to `ShareExtension/ShareExtension.entitlements`

### Step 5: Configure Custom URL Scheme

1. Select the **FrameExtractionTool** target
2. Go to **"Info"** tab
3. Expand **"URL Types"** (or add it if not present)
4. Click **"+"** to add a URL Type:
   - **Identifier**: `caspernyong.FrameExtractionTool`
   - **URL Schemes**: `frameextractor`
   - **Role**: Editor

### Step 6: Configure ShareExtension Build Settings

1. Select the **ShareExtension** target
2. Go to **"Build Settings"** tab
3. Search for "Deployment" and set:
   - **iOS Deployment Target**: `17.0` (match main app)
4. Search for "Product Bundle Identifier" and verify:
   - Should be: `caspernyong.FrameExtractionTool.ShareExtension`
5. Search for "Code Signing" and set (for unsigned builds):
   - **Code Signing Identity**: Leave as "Apple Development" or "Sign to Run Locally"
   - For CI builds, the build scripts already disable signing

### Step 7: Update Info.plist for ShareExtension

Verify the `ShareExtension/Info.plist` has correct configuration (should already be set from our file):

- `NSExtensionPointIdentifier`: `com.apple.share-services`
- `NSExtensionPrincipalClass`: `$(PRODUCT_MODULE_NAME).ShareViewController`
- `NSExtensionActivationRule`: Supports 1 movie/video file

### Step 8: Test the Configuration

1. Build the project: **⌘B**
2. Fix any build errors (usually related to target membership or missing files)
3. Run on simulator or device
4. Open Photos app, select a video, tap Share → look for "Frame Extractor"

## Verification Checklist

- [ ] ShareExtension target added to project
- [ ] Custom ShareViewController.swift in ShareExtension target
- [ ] SharedDataManager.swift in both targets (FrameExtractionTool + ShareExtension)
- [ ] App Groups capability added to both targets with same group ID
- [ ] Custom URL scheme `frameextractor://` configured for main app
- [ ] Both targets have iOS 17.0 deployment target
- [ ] Project builds without errors
- [ ] Share extension appears in share sheet for videos
- [ ] Tapping share extension opens main app with video

## Troubleshooting

### "No such module" errors
- Ensure SharedDataManager.swift is added to both target memberships
- Clean build folder: **⌘⇧K**

### Share extension doesn't appear in share sheet
- Verify Info.plist has correct NSExtensionActivationRule
- Check that extension target is being built (not just the main app)
- Uninstall app completely and reinstall

### App doesn't open from share extension
- Verify URL scheme is configured correctly in main app Info
- Check that scheme is `frameextractor` (no typos)
- Ensure LSApplicationQueriesSchemes is not blocking it

### App Groups not working
- Both targets must have exact same App Group ID
- Check entitlements files are properly linked in Build Settings
- For physical devices, may need proper provisioning profiles with App Groups enabled

## CI/CD Notes

The CI/CD pipelines (GitHub Actions and CodeMagic) will automatically build the ShareExtension target once it's added to the project. No changes to build scripts are needed - they build all targets in the scheme.

However, for **unsigned builds**, ensure:
- `CODE_SIGNING_REQUIRED=NO`
- `CODE_SIGNING_ALLOWED=NO`

These are already set in both CI workflows.

## Pre-Release Configuration

### GitHub Actions
- ✅ Configured to create pre-releases for tagged versions (v*)
- ✅ Auto-generates changelog from git commits
- ✅ Marks releases as "pre-release" automatically

### CodeMagic
- ✅ Configured to create GitHub pre-releases via GitHub CLI
- ⚠️ **Requires GITHUB_TOKEN** environment variable
  - Create a Personal Access Token at: https://github.com/settings/tokens
  - Scope needed: `repo` (full control of private repositories)
  - Add to CodeMagic: App Settings → Environment variables → `GITHUB_TOKEN`

Without GITHUB_TOKEN, CodeMagic will skip release creation (with warning) but Discord notifications will still work.

## Next Steps

After completing the Xcode configuration:

1. Test locally on simulator/device
2. Commit changes to the Xcode project file
3. Push to GitHub
4. Create a git tag for release: `git tag v1.3.0 && git push origin v1.3.0`
5. CI/CD will automatically build and create a pre-release on GitHub

## Support

If you encounter issues:
- Check that all files are in the correct locations
- Verify target memberships in File Inspector
- Clean and rebuild the project
- Check the implementation plan in `.claude/plan.md` for additional details
