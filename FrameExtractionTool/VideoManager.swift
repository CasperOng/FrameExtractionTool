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
                
                // Save to Photos
                try await saveImageToPhotos(uiImage)
                
                // Add to extracted frames list
                let extractedFrame = ExtractedFrame(
                    id: UUID(),
                    originalMarkedFrame: markedFrame,
                    image: uiImage,
                    extractionDate: Date()
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
    
    private func saveImageToPhotos(_ image: UIImage) async throws {
        let useCustomAlbum = UserDefaults.standard.bool(forKey: "useCustomAlbum")
        let customAlbumName = UserDefaults.standard.string(forKey: "customAlbumName") ?? "Frame Extractor"
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized else {
                    continuation.resume(throwing: PhotoLibraryError.notAuthorized)
                    return
                }
                
                if useCustomAlbum {
                    // Save to custom album
                    self.saveToCustomAlbum(image: image, albumName: customAlbumName, continuation: continuation)
                } else {
                    // Save directly to photo library
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
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
    
    private func saveToCustomAlbum(image: UIImage, albumName: String, continuation: CheckedContinuation<Void, Error>) {
        // First, try to find existing album
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let album = collection.firstObject {
            // Album exists, add photo to it
            addPhotoToAlbum(image: image, album: album, continuation: continuation)
        } else {
            // Album doesn't exist, create it first
            var albumPlaceholder: PHObjectPlaceholder?
            
            PHPhotoLibrary.shared().performChanges {
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            } completionHandler: { success, error in
                if success, let placeholder = albumPlaceholder {
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                    if let album = fetchResult.firstObject {
                        self.addPhotoToAlbum(image: image, album: album, continuation: continuation)
                    } else {
                        continuation.resume(throwing: PhotoLibraryError.saveFailed)
                    }
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                }
            }
        }
    }
    
    private func addPhotoToAlbum(image: UIImage, album: PHAssetCollection, continuation: CheckedContinuation<Void, Error>) {
        var assetPlaceholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges {
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
            
            if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
               let placeholder = assetPlaceholder {
                albumChangeRequest.addAssets([placeholder] as NSArray)
            }
        } completionHandler: { success, error in
            if success {
                continuation.resume()
            } else {
                continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
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
    
    var imageURL: String {
        // For preview purposes - in a real app you might save thumbnails
        return "placeholder"
    }
}

enum PhotoLibraryError: Error {
    case notAuthorized
    case saveFailed
}
