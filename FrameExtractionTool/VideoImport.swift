//
//  VideoImport.swift
//  FrameExtractionTool
//
//  Brings videos from the photo picker into app storage.
//

import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// A video the user picked in the photo library, already copied into a file the
/// app owns. The copy happens off the main actor: videos are large enough to
/// stall the interface if they are written on it.
struct MovieFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let imported = try await Task.detached(priority: .userInitiated) {
                try VideoStore.importVideo(from: received.file, originalName: received.file.lastPathComponent)
            }.value
            return MovieFile(url: imported)
        }
    }
}

enum VideoImporter {

    enum ImportError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "That video could not be opened. It may still be downloading from iCloud — try again in a moment."
            }
        }
    }

    /// Loads a picked video and returns the imported file.
    static func importPicked(_ item: PhotosPickerItem) async throws -> URL {
        guard let movie = try await item.loadTransferable(type: MovieFile.self) else {
            throw ImportError.unavailable
        }
        return movie.url
    }
}
