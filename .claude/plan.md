# Implementation Plan: Share Extension + Pre-Release CI/CD

## Overview
Add iOS Share Extension support to allow users to send videos directly to Frame Extraction Tool from the share menu (Photos, Files, Safari, etc.), and update CI/CD pipelines to publish builds as GitHub pre-releases.

## Current State Analysis

### App Architecture
- **Main App Bundle ID**: `caspernyong.FrameExtractionTool`
- **Current Version**: 1.2 (Build 1)
- **Deployment Target**: iOS 17.0+
- **State Management**: `VideoManager` (ObservableObject) manages video selection and frame extraction
- **Entry Point**: `ContentView` with `VideoPickerView` for video selection from photo library
- **No App Groups**: Currently not configured (needed for sharing data between main app and extension)

### CI/CD Current State
- **GitHub Actions**: `.github/workflows/build-ipa.yml`
  - Builds on push to main/develop and tags (v*)
  - Has a `release` job that creates GitHub releases for tags
  - Currently creates full releases (not pre-releases)
  
- **CodeMagic**: `codemagic.yaml`
  - Two workflows: `ios-unsigned-workflow` (dev) and `ios-release-workflow` (tags)
  - No GitHub release creation currently
  - Discord notifications configured

## Implementation Plan

### Phase 1: Create Share Extension Target

#### 1.1 Add App Group Entitlements
**Rationale**: Share extensions run in separate processes and need App Groups to share data with the main app.

**Files to create**:
- `FrameExtractionTool/FrameExtractionTool.entitlements` (main app)
- `ShareExtension/ShareExtension.entitlements` (extension)

**App Group ID**: `group.caspernyong.FrameExtractionTool`

**Actions**:
- Add entitlements files with App Groups capability
- Configure in Xcode project (manual step for user)

#### 1.2 Create Share Extension Target
**Files to create**:
- `ShareExtension/ShareViewController.swift` - Main extension view controller
- `ShareExtension/Info.plist` - Extension configuration

**Extension Configuration**:
- **Bundle ID**: `caspernyong.FrameExtractionTool.ShareExtension`
- **Supported Types**: `public.movie`, `public.video` (all video formats)
- **Presentation Style**: Full screen SwiftUI view
- **Deployment Target**: iOS 17.0+ (match main app)

**ShareViewController Implementation**:
- Present SwiftUI view using `UIHostingController`
- Accept video from `NSExtensionContext`
- Save video URL to shared UserDefaults in App Group
- Set flag to indicate pending video
- Dismiss extension and open main app via URL scheme

#### 1.3 Create Shared Data Manager
**File to create**: `Shared/SharedDataManager.swift`

**Purpose**: Manage communication between main app and share extension via App Group UserDefaults.

**Responsibilities**:
- Save/load pending video URL
- Clear pending video after processing
- Thread-safe access to shared storage

#### 1.4 Update Main App to Handle Shared Videos

**Files to modify**:
- `FrameExtractionToolApp.swift` - Add URL scheme handling
- `ContentView.swift` - Check for pending videos on appear
- `VideoManager.swift` - Add method to process shared videos

**Flow**:
1. App launches or comes to foreground
2. Check `SharedDataManager` for pending video URL
3. If found, copy video to app's temp directory (sandboxing)
4. Load video into `VideoManager`
5. Navigate to `VideoPlayerView` automatically
6. Clear pending video flag

#### 1.5 Add Custom URL Scheme
**URL Scheme**: `frameextractor://`

**Purpose**: Allow share extension to open main app after video is saved.

**Configuration**: Add to `Info.plist` keys via Xcode project settings:
- `CFBundleURLTypes` → `CFBundleURLSchemes` → `frameextractor`

### Phase 2: Update Xcode Project Configuration

**Note**: Some steps require manual Xcode configuration or programmatic pbxproj modification.

#### 2.1 Project File Modifications
**File to modify**: `FrameExtractionTool.xcodeproj/project.pbxproj`

**Changes needed**:
- Add new ShareExtension target
- Add new ShareExtension build phases (Sources, Frameworks, Resources)
- Add target dependency (main app depends on extension)
- Configure build settings for ShareExtension:
  - Bundle ID: `caspernyong.FrameExtractionTool.ShareExtension`
  - Deployment target: iOS 17.0
  - Code signing: Automatic (unsigned for CI)
  - App Groups entitlement
  
#### 2.2 Create Shared Framework (Optional, simpler alternative)
**Alternative approach**: Instead of modifying pbxproj directly, create a `Shared` folder with shared code and add it to both targets via file references.

**Recommended**: Use shared folder approach to avoid complex pbxproj editing.

### Phase 3: Update CI/CD for Pre-Releases

#### 3.1 Update GitHub Actions Workflow
**File to modify**: `.github/workflows/build-ipa.yml`

**Changes in `release` job (lines 191-270)**:

1. **Change release type to pre-release**:
   - Line 269: Change `prerelease: false` → `prerelease: true`
   
2. **Update release body text**:
   - Add "Pre-Release" badge/indicator
   - Update installation instructions to mention pre-release status
   - Add disclaimer about testing/development builds

3. **Add release notes generation**:
   - Generate changelog from commits since last tag
   - Use `git log --oneline $PREVIOUS_TAG..$CURRENT_TAG`

#### 3.2 Update CodeMagic Workflow
**File to modify**: `codemagic.yaml`

**Changes in `ios-release-workflow` (lines 111-236)**:

1. **Add GitHub Release Publishing**:
   - Add new publishing script after Discord notification
   - Use GitHub CLI (`gh`) or API to create pre-release
   - Upload IPA as release asset
   - Generate release notes from git commits

2. **Script to add** (after line 235):
```yaml
- name: Create GitHub Pre-Release
  script: |
    VERSION=${CM_TAG#v}
    
    # Install GitHub CLI if not present
    if ! command -v gh &> /dev/null; then
      brew install gh
    fi
    
    # Authenticate with GitHub (requires GITHUB_TOKEN in env)
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    
    # Generate release notes
    CHANGELOG=$(git log --oneline $(git describe --tags --abbrev=0 @^)..@ 2>/dev/null || echo "Initial release")
    
    # Create pre-release
    gh release create "$CM_TAG" \
      "build/FrameExtractionTool-$VERSION-unsigned.ipa" \
      --repo "$CM_REPO_SLUG" \
      --title "FrameExtractionTool $CM_TAG (Pre-Release)" \
      --notes "## Pre-Release Build

This is an automated pre-release build for testing.

### Changes
$CHANGELOG

### Build Info
- Version: $VERSION
- Build: ${CM_BUILD_NUMBER}
- Commit: ${CM_COMMIT:0:7}

⚠️ This is an unsigned build intended for testing only." \
      --prerelease
```

3. **Add Environment Variables**:
   - Add `GITHUB_TOKEN` to environment groups (requires GitHub Personal Access Token)
   - Add repository slug configuration

#### 3.3 Add Pre-Release Automation for Regular Pushes
**Optional enhancement**: Create pre-releases for every push to main (not just tags).

**New job in GitHub Actions** (after line 190):
```yaml
  pre-release-snapshot:
    name: Create Pre-Release Snapshot
    runs-on: macos-15
    needs: build
    if: github.ref == 'refs/heads/main' && !startsWith(github.ref, 'refs/tags/')
    
    steps:
      # Download artifact
      # Create pre-release with tag like 'snapshot-$GITHUB_SHA'
      # Mark as pre-release and latest=false
```

### Phase 4: Build & CI Updates

#### 4.1 Update Build Commands in CLAUDE.md
**File to modify**: `CLAUDE.md`

Add new build commands for Share Extension:
```bash
# Building with Share Extension
xcodebuild -project FrameExtractionTool.xcodeproj \
  -scheme FrameExtractionTool \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  build

# Building unsigned archive with extension (for CI)
xcodebuild -project FrameExtractionTool.xcodeproj \
  -scheme FrameExtractionTool \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/FrameExtractionTool.xcarchive \
  archive \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

#### 4.2 Update CI Build Scripts
Both GitHub Actions and CodeMagic build scripts remain the same - they'll automatically build the extension once it's added to the project as a dependency.

### Phase 5: Testing & Documentation

#### 5.1 Testing Checklist
- [ ] Share extension appears in share menu when sharing videos
- [ ] Video successfully passes from share extension to main app
- [ ] Main app opens and loads shared video automatically
- [ ] Frame marking and extraction work with shared videos
- [ ] App Group data clears after processing
- [ ] Extension handles cancellation gracefully
- [ ] Works with videos from Photos, Files, Safari, etc.

#### 5.2 Documentation Updates
**File to update**: `CLAUDE.md`

Add section:
```markdown
## Share Extension

The app includes a Share Extension that allows users to send videos directly from other apps:

### How to Use
1. Open Photos, Files, or any app with videos
2. Select a video and tap the Share button
3. Choose "Frame Extraction Tool" from the share sheet
4. The app will open with the video ready for frame marking

### Technical Details
- **Extension Bundle ID**: `caspernyong.FrameExtractionTool.ShareExtension`
- **App Group**: `group.caspernyong.FrameExtractionTool`
- **Supported Types**: All video formats (public.movie, public.video)
- **Data Sharing**: Uses App Group UserDefaults for IPC

### Development Notes
- Share extension runs in separate process with limited memory
- Videos are copied to main app's temp directory for processing
- Shared data is cleared after successful import
```

## Implementation Order

### Step-by-Step Execution

1. **Create shared data infrastructure**:
   - Create `Shared/SharedDataManager.swift`
   - Create entitlements files
   
2. **Create Share Extension**:
   - Create `ShareExtension/` directory
   - Create `ShareViewController.swift`
   - Create `Info.plist` with extension configuration
   
3. **Update main app**:
   - Modify `FrameExtractionToolApp.swift` for URL scheme handling
   - Modify `ContentView.swift` to check for shared videos
   - Modify `VideoManager.swift` to process shared videos
   
4. **Manual Xcode configuration** (user must do):
   - Add Share Extension target in Xcode
   - Add App Groups capability to both targets
   - Configure URL scheme in main app target
   - Add Shared files to both target memberships
   
5. **Update CI/CD**:
   - Modify `.github/workflows/build-ipa.yml`
   - Modify `codemagic.yaml`
   - Add GitHub token to CodeMagic environment
   
6. **Update documentation**:
   - Update `CLAUDE.md` with share extension info

## Challenges & Considerations

### Challenge 1: Xcode Project Modification
**Issue**: Adding a new target requires modifying the complex `project.pbxproj` file.

**Solution**: Provide user with manual steps to add target in Xcode, OR use Ruby gem `xcodeproj` to programmatically add target.

**Recommended**: Manual Xcode steps (more reliable, less error-prone).

### Challenge 2: App Group Sandboxing
**Issue**: Videos shared via extension are in different sandbox than main app.

**Solution**: Copy video file to main app's temp directory before processing. Use file coordination for safe access.

### Challenge 3: Extension Memory Limits
**Issue**: Share extensions have strict memory limits (~120MB).

**Solution**: Don't process video in extension - just pass URL to main app. Main app does all the heavy lifting.

### Challenge 4: Code Signing in CI
**Issue**: Extensions require code signing even when main app is unsigned.

**Solution**: Use `CODE_SIGNING_REQUIRED=NO` and `CODE_SIGNING_ALLOWED=NO` for the entire project, including extensions.

### Challenge 5: GitHub Token for CodeMagic
**Issue**: CodeMagic needs GitHub Personal Access Token to create releases.

**Solution**: User must create token with `repo` scope and add to CodeMagic environment group.

## Files to Create

### New Files
1. `Shared/SharedDataManager.swift` - Shared data communication
2. `ShareExtension/ShareViewController.swift` - Extension UI
3. `ShareExtension/Info.plist` - Extension configuration
4. `FrameExtractionTool/FrameExtractionTool.entitlements` - Main app entitlements
5. `ShareExtension/ShareExtension.entitlements` - Extension entitlements

### Files to Modify
1. `.github/workflows/build-ipa.yml` - Pre-release configuration
2. `codemagic.yaml` - Pre-release + GitHub release creation
3. `CLAUDE.md` - Documentation updates
4. `FrameExtractionToolApp.swift` - URL scheme handling
5. `ContentView.swift` - Shared video processing
6. `VideoManager.swift` - Shared video import

### Files to Manually Configure (Xcode)
1. `FrameExtractionTool.xcodeproj/project.pbxproj` - Add Share Extension target

## Success Criteria

✅ Share Extension:
- Extension appears in system share sheet for videos
- Videos successfully transfer from extension to main app
- Main app opens automatically with shared video loaded
- No data leaks or leftover files in App Group storage

✅ CI/CD Pre-Releases:
- GitHub Actions creates pre-releases for tagged versions
- CodeMagic creates GitHub pre-releases with IPAs attached
- Pre-releases are marked as "pre-release" (not latest stable)
- Release notes auto-generated from git commits
- Discord notifications continue to work

## Estimated Complexity

- **Share Extension**: Medium complexity (App Groups, IPC, extension lifecycle)
- **CI/CD Updates**: Low complexity (configuration changes only)
- **Manual Xcode Steps**: Low complexity (standard Xcode workflow)

**Total Effort**: 2-3 hours of implementation + testing

## Next Steps After Approval

1. Create all new Swift files and entitlements
2. Update existing Swift files for shared video handling
3. Update CI/CD configuration files
4. Update documentation
5. Provide user with manual Xcode configuration steps
6. Test share extension functionality
7. Test CI/CD pre-release creation
8. Commit and push changes
