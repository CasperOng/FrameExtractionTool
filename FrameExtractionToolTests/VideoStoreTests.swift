//
//  VideoStoreTests.swift
//  FrameExtractionToolTests
//

import Foundation
import Testing
@testable import FrameExtractionTool

@Suite("Video store", .serialized)
struct VideoStoreTests {

    // MARK: - Fixtures

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "VideoStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @discardableResult
    private func makeFile(named name: String, in directory: URL, contents: String = "not really a movie") throws -> URL {
        let url = directory.appending(path: name)
        try Data(contents.utf8).write(to: url)
        return url
    }

    // MARK: - Type checks

    @Test("Movie containers are accepted")
    func acceptsMovies() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        for name in ["clip.mov", "clip.mp4", "clip.m4v", "clip.MOV"] {
            let url = try makeFile(named: name, in: directory)
            #expect(VideoStore.isSupportedVideo(url), "\(name) should be accepted")
        }
    }

    @Test("Everything else is refused")
    func refusesOtherFiles() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        for name in ["notes.txt", "report.pdf", "song.mp3", "archive.zip"] {
            let url = try makeFile(named: name, in: directory)
            #expect(!VideoStore.isSupportedVideo(url), "\(name) should be refused")
        }
    }

    // MARK: - Importing

    @Test("Importing copies the video into app storage")
    func importCopiesFile() throws {
        let source = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: source) }
        let original = try makeFile(named: "Sunset Clip.mov", in: source, contents: "frame data")

        let imported = try VideoStore.importVideo(from: original)
        defer { try? FileManager.default.removeItem(at: imported) }

        #expect(imported.deletingLastPathComponent().path == VideoStore.directory.path)
        #expect(imported.lastPathComponent == "Sunset Clip.mov")
        #expect(try Data(contentsOf: imported) == Data("frame data".utf8))
        // The original is left where it was.
        #expect(FileManager.default.fileExists(atPath: original.path))
    }

    @Test("A second import of the same name does not overwrite the first")
    func importAvoidsNameCollisions() throws {
        let source = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: source) }
        let original = try makeFile(named: "Take 2.mp4", in: source)

        let first = try VideoStore.importVideo(from: original)
        let second = try VideoStore.importVideo(from: original)
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }

        #expect(first != second)
        #expect(first.lastPathComponent == "Take 2.mp4")
        #expect(second.lastPathComponent == "Take 2-2.mp4")
    }

    @Test("A file that is not a video is refused with a readable message")
    func importRefusesNonVideo() throws {
        let source = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: source) }
        let document = try makeFile(named: "budget.numbers", in: source)

        #expect(throws: VideoStore.StoreError.unsupportedType("budget.numbers")) {
            try VideoStore.importVideo(from: document)
        }
    }

    @Test("Awkward file names are made safe")
    func importSanitizesNames() throws {
        let source = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: source) }
        let original = try makeFile(named: "source.mov", in: source)

        // Names as they arrive from other apps can hold path separators and
        // characters that are not welcome in a file name.
        let imported = try VideoStore.importVideo(from: original, originalName: "vacation:2024/paris?.mov")
        defer { try? FileManager.default.removeItem(at: imported) }

        #expect(imported.lastPathComponent.hasSuffix(".mov"))
        #expect(!imported.lastPathComponent.contains(":"))
        #expect(!imported.lastPathComponent.contains("/"))
        #expect(!imported.lastPathComponent.contains("?"))
        #expect(imported.deletingLastPathComponent().path == VideoStore.directory.path)
    }

    // MARK: - Housekeeping

    @Test("Old imports are cleared out, recent ones are kept")
    func expiresOldImports() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let old = try makeFile(named: "old.mov", in: directory)
        let recent = try makeFile(named: "recent.mov", in: directory)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-VideoStore.retentionInterval - 60)],
            ofItemAtPath: old.path
        )

        let removed = VideoStore.removeExpiredImports(in: directory)

        #expect(removed.contains(old))
        #expect(!FileManager.default.fileExists(atPath: old.path))
        #expect(FileManager.default.fileExists(atPath: recent.path))
    }

    @Test("A missing directory is not an error")
    func handlesMissingDirectory() {
        let missing = FileManager.default.temporaryDirectory.appending(path: "does-not-exist-\(UUID().uuidString)")
        #expect(VideoStore.removeExpiredImports(in: missing).isEmpty)
    }
}
