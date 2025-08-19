//
//  VideoManager.swift
//  FrameExtractionTool
//
//  Created by Casper Ong on 14/8/2025.
//

import SwiftUI
import AVFoundation
import Photos
import CoreImage
import Combine

@MainActor
final class VideoManager: ObservableObject {
    @Published var selectedVideoURL: URL?
    @Published var markedFrames: [MarkedFrame] = []
    @Published var extractedFrames: [ExtractedFrame] = []
    @Published var isExtracting = false
    @Published var extractionProgress: Double = 0.0
    
    private let photoLibrary = PHPhotoLibrary.shared()
    
    init() {
        // Set default haptic feedback preference if not set
        if UserDefaults.standard.object(forKey: "hapticFeedback") == nil {
            UserDefaults.standard.set(true, forKey: "hapticFeedback")
        }
    }
    
    func selectVideo(url: URL) {
        selectedVideoURL = url
    }
    
    func markFrame(at time: CMTime, player: AVPlayer) {
        guard let videoURL = selectedVideoURL else { return }
        
        let newFrame = MarkedFrame(
            id: UUID(),
            timeStamp: time,
            videoURL: videoURL
        )
        
        markedFrames.append(newFrame)
        
        // Provide haptic feedback if enabled
        if UserDefaults.standard.bool(forKey: "hapticFeedback") {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    func unmarkFrame(frameId: UUID) {
        markedFrames.removeAll { $0.id == frameId }
        
        // Provide haptic feedback if enabled
        if UserDefaults.standard.bool(forKey: "hapticFeedback") {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    func clearMarkedFrames() {
        markedFrames.removeAll()
        
        // Provide haptic feedback if enabled
        if UserDefaults.standard.bool(forKey: "hapticFeedback") {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    func deleteExtractedFrame(_ frame: ExtractedFrame) {
        // Remove from app
        extractedFrames.removeAll { $0.id == frame.id }
        
        // Delete from photo library if we have the asset identifier
        if let assetIdentifier = frame.photoAssetIdentifier {
            Task {
                try? await deleteFromPhotoLibrary(assetIdentifier: assetIdentifier)
            }
        }
        
        // Provide haptic feedback if enabled
        if UserDefaults.standard.bool(forKey: "hapticFeedback") {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    func deleteExtractedFrames(_ framesToDelete: [ExtractedFrame]) {
        let idsToDelete = Set(framesToDelete.map { $0.id })
        
        // Remove from app
        extractedFrames.removeAll { idsToDelete.contains($0.id) }
        
        // Delete from photo library
        Task {
            for frame in framesToDelete {
                if let assetIdentifier = frame.photoAssetIdentifier {
                    try? await deleteFromPhotoLibrary(assetIdentifier: assetIdentifier)
                }
            }
        }
        
        // Provide haptic feedback if enabled
        if UserDefaults.standard.bool(forKey: "hapticFeedback") {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    func clearAllExtractedFrames() {
        let framesToDelete = extractedFrames
        
        // Remove from app
        extractedFrames.removeAll()
        
        // Delete from photo library
        Task {
            for frame in framesToDelete {
                if let assetIdentifier = frame.photoAssetIdentifier {
                    try? await deleteFromPhotoLibrary(assetIdentifier: assetIdentifier)
                }
            }
        }
        
        // Provide haptic feedback if enabled
        if UserDefaults.standard.bool(forKey: "hapticFeedback") {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
    
    func extractAllMarkedFrames() async throws {
        guard !markedFrames.isEmpty else { return }
        
        isExtracting = true
        extractionProgress = 0.0
        
        let asset = AVAsset(url: selectedVideoURL!)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        // Set maximum size to maintain original quality
        let tracks = try await asset.loadTracks(withMediaType: .video)
        if let track = tracks.first {
            let naturalSize = try await track.load(.naturalSize)
            imageGenerator.maximumSize = naturalSize
        }
        
        for (index, markedFrame) in markedFrames.enumerated() {
            do {
                let cgImage = try await imageGenerator.image(at: markedFrame.timeStamp).image
                let uiImage = UIImage(cgImage: cgImage)
                
                // Save to Photos and get asset identifier
                let assetIdentifier = try await saveImageToPhotos(uiImage)
                
                // Add to extracted frames list
                let extractedFrame = ExtractedFrame(
                    id: UUID(),
                    originalMarkedFrame: markedFrame,
                    image: uiImage,
                    extractionDate: Date(),
                    photoAssetIdentifier: assetIdentifier
                )
                
                extractedFrames.append(extractedFrame)
                
                // Update progress
                extractionProgress = Double(index + 1) / Double(markedFrames.count)
                
            } catch {
                print("Failed to extract frame: \(error)")
            }
        }
        
        // Clear marked frames after successful extraction
        markedFrames.removeAll()
        isExtracting = false
        extractionProgress = 0.0
        
        // Success haptic feedback if enabled
        if UserDefaults.standard.bool(forKey: "hapticFeedback") {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
    
    private func saveImageToPhotos(_ image: UIImage) async throws -> String? {
        let useCustomAlbum = UserDefaults.standard.bool(forKey: "useCustomAlbum")
        let customAlbumName = UserDefaults.standard.string(forKey: "customAlbumName") ?? "Frame Extractor"
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized else {
                    continuation.resume(throwing: PhotoLibraryError.notAuthorized)
                    return
                }
                
                var assetIdentifier: String?
                
                PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    assetIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
                    
                    if useCustomAlbum {
                        // Also add to custom album
                        self.addToCustomAlbumHelper(creationRequest: creationRequest, albumName: customAlbumName)
                    }
                } completionHandler: { success, error in
                    if success {
                        continuation.resume(returning: assetIdentifier)
                    } else {
                        continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                    }
                }
            }
        }
    }
    
    private func addToCustomAlbumHelper(creationRequest: PHAssetChangeRequest, albumName: String) {
        // First, try to find existing album
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let album = collection.firstObject {
            // Album exists, add asset to it
            if let placeholder = creationRequest.placeholderForCreatedAsset {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([placeholder] as NSArray)
            }
        } else {
            // Create new album and add asset
            let albumCreationRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            if let placeholder = creationRequest.placeholderForCreatedAsset {
                albumCreationRequest.addAssets([placeholder] as NSArray)
            }
        }
    }
    
    private func deleteFromPhotoLibrary(assetIdentifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                guard status == .authorized else {
                    continuation.resume(throwing: PhotoLibraryError.notAuthorized)
                    return
                }
                
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                guard let asset = fetchResult.firstObject else {
                    continuation.resume() // Asset already deleted or not found
                    return
                }
                
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets([asset] as NSArray)
                } completionHandler: { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                    }
                }
            }
        }
    }
}

struct MarkedFrame: Identifiable, Equatable {
    let id: UUID
    let timeStamp: CMTime
    let videoURL: URL
    
    var timeString: String {
        let seconds = CMTimeGetSeconds(timeStamp)
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        let milliseconds = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, remainingSeconds, milliseconds)
    }
}

struct ExtractedFrame: Identifiable {
    let id: UUID
    let originalMarkedFrame: MarkedFrame
    let image: UIImage
    let extractionDate: Date
    let photoAssetIdentifier: String? // Store the asset identifier for deletion
    
    var imageURL: String {
        // For preview purposes - in a real app you might save thumbnails
        return "placeholder"
    }
}

enum PhotoLibraryError: Error {
    case notAuthorized
    case saveFailed
}
