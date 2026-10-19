//
//  FrameModels.swift
//  FrameExtractionTool
//

import AVFoundation
import UIKit

/// A frame the user marked for extraction.
struct MarkedFrame: Identifiable, Equatable {
    let id: UUID
    let timeStamp: CMTime
    let videoURL: URL

    init(id: UUID = UUID(), timeStamp: CMTime, videoURL: URL) {
        self.id = id
        self.timeStamp = timeStamp
        self.videoURL = videoURL
    }

    var seconds: Double {
        let value = CMTimeGetSeconds(timeStamp)
        return value.isFinite ? max(0, value) : 0
    }

    /// `mm:ss.hh`, with hours when the video is longer than an hour.
    var timeString: String {
        Self.timeString(fromSeconds: seconds)
    }

    static func timeString(fromSeconds value: Double) -> String {
        let safe = value.isFinite ? max(0, value) : 0
        let totalHundredths = Int((safe * 100).rounded())
        let hundredths = totalHundredths % 100
        let totalSeconds = totalHundredths / 100
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600

        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, hundredths)
        }
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }

    /// Spoken form for VoiceOver: "1 minute 5 seconds".
    var accessibilityTimeString: String {
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let remainder = total % 60
        var parts: [String] = []
        if minutes > 0 { parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
        parts.append("\(remainder) second\(remainder == 1 ? "" : "s")")
        return parts.joined(separator: " ")
    }
}

/// A frame that was extracted and saved to the photo library.
///
/// Only a small thumbnail is kept in memory — a library of full-resolution
/// stills quickly runs into hundreds of megabytes — and the original is fetched
/// back from Photos on demand through `VideoManager.fullImage(for:)`.
struct ExtractedFrame: Identifiable, Equatable {
    let id: UUID
    let originalMarkedFrame: MarkedFrame
    let thumbnail: UIImage
    let extractionDate: Date
    /// Identifier of the saved photo, used to delete it again.
    let photoAssetIdentifier: String?

    init(
        id: UUID = UUID(),
        originalMarkedFrame: MarkedFrame,
        thumbnail: UIImage,
        extractionDate: Date = Date(),
        photoAssetIdentifier: String?
    ) {
        self.id = id
        self.originalMarkedFrame = originalMarkedFrame
        self.thumbnail = thumbnail
        self.extractionDate = extractionDate
        self.photoAssetIdentifier = photoAssetIdentifier
    }

    var timeString: String { originalMarkedFrame.timeString }

    static func == (lhs: ExtractedFrame, rhs: ExtractedFrame) -> Bool {
        lhs.id == rhs.id
    }

    /// Longest edge of the thumbnail kept for the grid.
    static let thumbnailMaxDimension: CGFloat = 480
}

/// Outcome of an extraction run, shown when it finishes.
struct ExtractionSummary: Equatable {
    var savedCount: Int
    var failedCount: Int
    /// Explains a partial failure, e.g. that the album needed more access.
    var note: String?

    var isComplete: Bool { failedCount == 0 }
}

enum ExtractionError: LocalizedError {
    case noVideoSelected
    case noFramesMarked
    case photoAccessDenied
    case photoAccessDeniedForAlbum

    var errorDescription: String? {
        switch self {
        case .noVideoSelected:
            return "Choose a video before extracting frames."
        case .noFramesMarked:
            return "Mark at least one frame first — tap the plus button while the video plays."
        case .photoAccessDenied:
            return "Frame Extractor needs permission to add photos. You can turn it on in Settings › Privacy & Security › Photos."
        case .photoAccessDeniedForAlbum:
            return "Adding frames to an album needs full photo library access. Frames will be saved to your library instead."
        }
    }
}
