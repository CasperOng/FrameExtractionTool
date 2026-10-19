//
//  VideoManager.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import AVFoundation
import Observation
import Photos
import UIKit

/// The app's source of truth: which video is loaded, which frames are marked,
/// and which frames have been extracted.
@Observable
final class VideoManager {

    // MARK: - State

    private(set) var selectedVideoURL: URL?
    private(set) var markedFrames: [MarkedFrame] = []
    private(set) var extractedFrames: [ExtractedFrame] = []

    private(set) var isExtracting = false
    private(set) var extractionProgress: Double = 0
    /// Number of frames in the run that is currently in progress.
    private(set) var extractionTotal = 0
    /// Set when an extraction run ends, so the UI can report what happened.
    private(set) var lastSummary: ExtractionSummary?

    /// A problem the user needs to know about; setting it presents an alert.
    var errorMessage: String?

    // MARK: - Video selection

    func selectVideo(url: URL) {
        guard url != selectedVideoURL else { return }
        selectedVideoURL = url
        markedFrames.removeAll()
    }

    // MARK: - Marking

    func markFrame(at time: CMTime) {
        guard let videoURL = selectedVideoURL else { return }
        guard time.isNumeric else { return }

        markedFrames.append(MarkedFrame(timeStamp: time, videoURL: videoURL))
        Haptics.impact(.medium)
    }

    func unmarkFrame(id: UUID) {
        guard markedFrames.contains(where: { $0.id == id }) else { return }
        markedFrames.removeAll { $0.id == id }
        Haptics.impact(.light)
    }

    func clearMarkedFrames() {
        guard !markedFrames.isEmpty else { return }
        markedFrames.removeAll()
        Haptics.impact(.light)
    }

    // MARK: - Extraction

    /// Extracts every marked frame, saves it to the photo library and keeps a
    /// thumbnail in the library.
    ///
    /// Safe to cancel: frames already saved stay saved, and the run ends with a
    /// summary of what was written.
    func extractMarkedFrames() async {
        guard let videoURL = selectedVideoURL else {
            errorMessage = ExtractionError.noVideoSelected.localizedDescription
            return
        }
        guard !markedFrames.isEmpty else {
            errorMessage = ExtractionError.noFramesMarked.localizedDescription
            return
        }

        let access = await requestPhotoAccess()
        guard access.canAdd else {
            errorMessage = ExtractionError.photoAccessDenied.localizedDescription
            return
        }

        isExtracting = true
        extractionProgress = 0
        extractionTotal = markedFrames.count
        lastSummary = nil
        defer {
            isExtracting = false
            extractionProgress = 0
            extractionTotal = 0
        }

        // Saving into an album needs read-write access; without it, frames still
        // go to the library and the summary explains the difference.
        let wantsAlbum = AppSettings.usesCustomAlbum
        let albumName = access.canReadWrite && wantsAlbum ? AppSettings.albumName : nil
        var note: String?
        if wantsAlbum && !access.canReadWrite {
            note = ExtractionError.photoAccessDeniedForAlbum.localizedDescription
        }

        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let frames = markedFrames
        var savedIDs: Set<UUID> = []
        var failed = 0
        var firstFailure: String?

        for (index, frame) in frames.enumerated() {
            if Task.isCancelled { break }

            do {
                let image = UIImage(cgImage: try await generator.image(at: frame.timeStamp).image)
                let identifier: String?
                do {
                    identifier = try await saveImageToPhotos(image, albumName: albumName)
                } catch {
                    // Writing to an album needs read-write access. Save to the
                    // library instead of losing the frame, and say why.
                    guard albumName != nil else { throw error }
                    identifier = try await saveImageToPhotos(image, albumName: nil)
                    note = note ?? ExtractionError.photoAccessDeniedForAlbum.localizedDescription
                }
                extractedFrames.append(ExtractedFrame(
                    originalMarkedFrame: frame,
                    thumbnail: image.thumbnail(maxDimension: ExtractedFrame.thumbnailMaxDimension),
                    photoAssetIdentifier: identifier
                ))
                savedIDs.insert(frame.id)
            } catch {
                // A cancellation surfaces as an error here; it is not a failure.
                if Task.isCancelled { break }
                failed += 1
                firstFailure = firstFailure ?? error.localizedDescription
                print("Failed to extract frame at \(frame.timeString): \(error)")
            }

            extractionProgress = Double(index + 1) / Double(frames.count)
        }

        if failed > 0 && note == nil {
            note = firstFailure
        }
        lastSummary = ExtractionSummary(savedCount: savedIDs.count, failedCount: failed, note: note)

        if !savedIDs.isEmpty {
            // Only the marks that made it are cleared, so an interrupted run
            // can be finished by extracting again.
            markedFrames.removeAll { savedIDs.contains($0.id) }
            Haptics.notify(failed == 0 ? .success : .warning)
        }
    }

    // MARK: - Library

    /// Removes frames from the app and from the photo library.
    func deleteFrames(_ frames: [ExtractedFrame]) {
        guard !frames.isEmpty else { return }
        let ids = Set(frames.map(\.id))
        extractedFrames.removeAll { ids.contains($0.id) }
        Haptics.impact(.medium)

        let identifiers = frames.compactMap(\.photoAssetIdentifier)
        guard !identifiers.isEmpty else { return }

        Task {
            let access = await requestPhotoAccess()
            guard access.canReadWrite else {
                errorMessage = ExtractionError.photoAccessDenied.localizedDescription
                return
            }
            do {
                try await deleteAssets(identifiers: identifiers)
            } catch {
                errorMessage = "Those frames were removed from the app, but Photos could not delete the copies: \(error.localizedDescription)"
            }
        }
    }

    func deleteFrame(_ frame: ExtractedFrame) {
        deleteFrames([frame])
    }

    /// Fetches the full-resolution image again, on demand.
    func fullImage(for frame: ExtractedFrame) async -> UIImage? {
        guard let identifier = frame.photoAssetIdentifier else { return nil }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none
            // `requestImageDataAndOrientation` reports exactly once, unlike
            // `requestImage`, which can call back again with a better result.
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data.flatMap(UIImage.init(data:)))
            }
        }
    }

    // MARK: - Photo library

    private struct PhotoAccess {
        /// Enough access to add new assets.
        var canAdd: Bool
        /// Full access, needed to work with albums and to delete.
        var canReadWrite: Bool
    }

    private func requestPhotoAccess() async -> PhotoAccess {
        let readWrite = await requestAuthorization(for: .readWrite)
        var access = PhotoAccess(
            canAdd: readWrite == .authorized || readWrite == .limited,
            canReadWrite: readWrite == .authorized || readWrite == .limited
        )
        if !access.canAdd {
            let addOnly = await requestAuthorization(for: .addOnly)
            access.canAdd = addOnly == .authorized || addOnly == .limited
        }
        return access
    }

    private func requestAuthorization(for level: PHAccessLevel) async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: level)
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: level) { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func saveImageToPhotos(_ image: UIImage, albumName: String?) async throws -> String? {
        // Fetch the album before the change block: photo library reads belong
        // outside `performChanges`.
        let album = albumName.flatMap(existingAlbum(named:))

        return try await withCheckedThrowingContinuation { continuation in
            var identifier: String?
            PHPhotoLibrary.shared().performChanges {
                let creation = PHAssetChangeRequest.creationRequestForAsset(from: image)
                identifier = creation.placeholderForCreatedAsset?.localIdentifier

                guard let placeholder = creation.placeholderForCreatedAsset, let albumName else { return }
                if let album {
                    PHAssetCollectionChangeRequest(for: album)?.addAssets([placeholder] as NSArray)
                } else {
                    PHAssetCollectionChangeRequest
                        .creationRequestForAssetCollection(withTitle: albumName)
                        .addAssets([placeholder] as NSArray)
                }
            } completionHandler: { success, error in
                if success {
                    continuation.resume(returning: identifier)
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                }
            }
        }
    }

    private func existingAlbum(named title: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", title)
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options).firstObject
    }

    private func deleteAssets(identifiers: [String]) async throws {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        guard assets.count > 0 else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.deleteFailed)
                }
            }
        }
    }
}

enum PhotoLibraryError: Error, LocalizedError {
    case notAuthorized
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Frame Extractor does not have permission to use the photo library."
        case .saveFailed: return "The frame could not be saved to the photo library."
        case .deleteFailed: return "The frame could not be deleted from the photo library."
        }
    }
}

private extension UIImage {
    /// A small copy for the library grid, so a long session does not keep
    /// full-resolution stills in memory.
    func thumbnail(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        return preparingThumbnail(of: target) ?? self
    }
}
