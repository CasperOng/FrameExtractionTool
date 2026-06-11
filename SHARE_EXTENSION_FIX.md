# Share Extension Video Transfer Fix

## 问题 (Problem)
分享扩展出现在分享菜单中，但视频没有传递到主应用。

The share extension appeared in the share menu, but videos were not being transferred to the main app.

## 根本原因 (Root Cause)
1. **安全范围资源访问**: 分享扩展接收的视频 URL 是安全范围的，需要调用 `startAccessingSecurityScopedResource()`
2. **文件访问权限**: 直接保存 URL 字符串不够，因为主应用无法访问分享扩展沙盒中的文件
3. **后台恢复检测**: 当应用已打开并从后台返回时，不会触发 `onAppear`，导致无法检测待处理视频

1. **Security-scoped resource access**: Video URLs received by the share extension are security-scoped and require `startAccessingSecurityScopedResource()`
2. **File access permissions**: Saving just the URL string wasn't enough because the main app can't access files in the share extension's sandbox
3. **Background resume detection**: When the app is already open and returns from background, `onAppear` doesn't trigger, so pending videos weren't detected

## 修复方案 (Solution)

### 1. ShareViewController.swift
- 添加安全范围资源访问
- 先尝试 `UTType.movie.identifier`，如果失败再尝试 `UTType.video.identifier`
- 将视频复制到 App Group 共享容器，而不是只保存 URL

- Added security-scoped resource access
- Try `UTType.movie.identifier` first, fallback to `UTType.video.identifier`
- Copy video to App Group shared container instead of just saving URL

```swift
// Start accessing security-scoped resource
let isAccessing = videoURL.startAccessingSecurityScopedResource()

defer {
    if isAccessing {
        videoURL.stopAccessingSecurityScopedResource()
    }
}

// Copy video to shared container
let copiedURL = try SharedDataManager.shared.copyVideoToSharedContainer(from: videoURL)
SharedDataManager.shared.savePendingVideo(url: copiedURL)
```

### 2. SharedDataManager.swift
添加新方法 `copyVideoToSharedContainer()`:
- 使用 App Group 容器 URL (`FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`)
- 在共享容器中创建 `SharedVideos` 目录
- 生成唯一文件名（带时间戳）
- 将视频复制到共享容器

Added new method `copyVideoToSharedContainer()`:
- Use App Group container URL (`FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`)
- Create `SharedVideos` directory in shared container
- Generate unique filename with timestamp
- Copy video to shared container

添加 `cleanupSharedVideos()` 方法：
- 自动删除 24 小时前的旧视频文件
- 防止共享容器占用过多空间

Added `cleanupSharedVideos()` method:
- Automatically delete video files older than 24 hours
- Prevent shared container from consuming too much space

### 3. ContentView.swift
添加场景阶段监听:
- 导入 `@Environment(\.scenePhase)` 
- 使用 `.onChange(of: scenePhase)` 监听应用状态变化
- 当应用变为活动状态时重新检查待处理视频
- 添加 `isProcessingSharedVideo` 检查以防止重复处理

Added scene phase monitoring:
- Import `@Environment(\.scenePhase)`
- Use `.onChange(of: scenePhase)` to monitor app state changes
- Re-check for pending videos when app becomes active
- Added `isProcessingSharedVideo` check to prevent duplicate processing

```swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { oldPhase, newPhase in
    if newPhase == .active {
        checkForSharedVideo()
    }
}
```

## 数据流 (Data Flow)

### 之前 (Before):
1. Share Extension 接收视频 URL
2. 保存 URL 字符串到 UserDefaults
3. 打开主应用
4. ❌ 主应用无法访问 Share Extension 沙盒中的文件

1. Share Extension receives video URL
2. Save URL string to UserDefaults
3. Open main app
4. ❌ Main app can't access files in Share Extension sandbox

### 现在 (Now):
1. Share Extension 接收视频 URL
2. 启用安全范围资源访问
3. **复制视频到 App Group 共享容器**
4. 保存共享容器中的 URL 到 UserDefaults
5. 打开主应用
6. ✅ 主应用从共享容器读取视频
7. 复制到主应用的临时目录
8. 清理共享容器中的旧文件

1. Share Extension receives video URL
2. Enable security-scoped resource access
3. **Copy video to App Group shared container**
4. Save shared container URL to UserDefaults
5. Open main app
6. ✅ Main app reads video from shared container
7. Copy to main app's temp directory
8. Clean up old files in shared container

## 文件位置 (File Locations)

### App Group 共享容器 (Shared Container):
```
group.caspernyong.FrameExtractionTool/
└── SharedVideos/
    ├── 1234567890.123_video1.mov
    └── 1234567891.456_video2.mp4
```

### 主应用临时目录 (Main App Temp):
```
/tmp/
└── 1234567890.123_video1.mov  (用于播放和提取帧)
```

## 测试步骤 (Testing Steps)

1. **首次分享** (First Share):
   - 在照片应用中选择一个视频
   - 点击分享按钮
   - 选择 "Frame Extractor"
   - 验证主应用打开并显示视频播放器

2. **应用已打开时分享** (Share When App Already Open):
   - 打开 Frame Extractor 应用
   - 切换到照片应用
   - 分享一个视频到 Frame Extractor
   - 验证应用切换回来并自动加载视频

3. **多个视频** (Multiple Videos):
   - 连续分享多个视频
   - 验证每个视频都能正确加载
   - 验证旧视频文件会被清理

## 构建结果 (Build Result)
✅ 构建成功 (Build succeeded)

只有一个警告：Share Extension 的版本号 (1.0) 与主应用 (1.2) 不匹配。这不影响功能，但建议同步版本号。

Only one warning: Share Extension version (1.0) doesn't match main app version (1.2). This doesn't affect functionality, but versions should be synced.

## 下一步 (Next Steps)

如果问题仍然存在，请检查：
1. 在 Xcode 中验证两个 target 都启用了 App Group: `group.caspernyong.FrameExtractionTool`
2. 在真机或模拟器上重新安装应用（卸载后重新安装）
3. 检查控制台日志以获取更多错误信息

If the issue persists, check:
1. Verify in Xcode that both targets have App Group enabled: `group.caspernyong.FrameExtractionTool`
2. Reinstall the app on device or simulator (uninstall then reinstall)
3. Check Console logs for more error messages
