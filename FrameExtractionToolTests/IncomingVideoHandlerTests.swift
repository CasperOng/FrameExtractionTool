//
//  IncomingVideoHandlerTests.swift
//  FrameExtractionToolTests
//

import Foundation
import Testing
@testable import FrameExtractionTool

@MainActor
@Suite("Incoming videos", .serialized)
struct IncomingVideoHandlerTests {

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "IncomingTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeVideo(named name: String = "shared.mov", in directory: URL) throws -> URL {
        let url = directory.appending(path: name)
        try Data("movie".utf8).write(to: url)
        return url
    }

    @Test("URLs that belong to other apps are left alone")
    func ignoresForeignURLs() {
        let handler = IncomingVideoHandler()
        #expect(handler.handle(URL(string: "https://example.com/clip.mov")!) == false)
        #expect(handler.handle(URL(string: "shortcuts://run-shortcut")!) == false)
        #expect(handler.state == .idle)
    }

    @Test("The app's own scheme is accepted, with or without a video")
    func acceptsOwnScheme() {
        let handler = IncomingVideoHandler()
        #expect(handler.handle(URL(string: "frameextractor://")!) == true)
        #expect(handler.handle(URL(string: "frameextractor://open")!) == true)
    }

    @Test("A video URL in the scheme is understood")
    func parsesVideoParameter() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let video = try makeVideo(in: directory)

        let encoded = video.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let link = URL(string: "frameextractor://open?video=\(encoded)")!

        #expect(IncomingVideoHandler.videoFileURL(in: link)?.path == video.path)
        #expect(IncomingVideoHandler.videoFileURL(in: URL(string: "frameextractor://open")!) == nil)
    }

    @Test("Importing a shared video makes it ready for the player")
    func importsSharedVideo() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let video = try makeVideo(named: "Holiday.mov", in: directory)

        let handler = IncomingVideoHandler()
        await handler.importVideo(at: video)
        let ready = try #require(handler.readyVideoURL)
        defer { try? FileManager.default.removeItem(at: ready) }

        #expect(handler.state == .idle)
        #expect(ready.deletingLastPathComponent().path == VideoStore.directory.path)
        #expect(FileManager.default.fileExists(atPath: ready.path))

        handler.consumeReadyVideo()
        #expect(handler.readyVideoURL == nil)
    }

    @Test("A file that is not a video fails with an explanation")
    func reportsUnsupportedFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let document = directory.appending(path: "notes.txt")
        try Data("hello".utf8).write(to: document)

        let handler = IncomingVideoHandler()
        await handler.importVideo(at: document)

        guard case .failed(let message) = handler.state else {
            Issue.record("Expected a failure state, got \(handler.state)")
            return
        }
        #expect(message.contains("notes.txt"))
        #expect(handler.readyVideoURL == nil)

        handler.dismissFailure()
        #expect(handler.state == .idle)
    }
}
