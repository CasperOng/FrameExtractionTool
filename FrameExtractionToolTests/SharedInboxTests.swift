//
//  SharedInboxTests.swift
//  FrameExtractionToolTests
//

import Foundation
import Testing
@testable import FrameExtractionTool

@MainActor
@Suite("Share extension hand-off", .serialized)
struct SharedInboxTests {

    // MARK: - Fixtures

    private func makeInbox() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "SharedInboxTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @discardableResult
    private func file(named name: String, in directory: URL, modified: Date? = nil) throws -> URL {
        let url = directory.appending(path: name)
        try Data("movie".utf8).write(to: url)
        if let modified {
            try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path)
        }
        return url
    }

    // MARK: - Collecting

    @Test("A video the extension filed is imported under its original name and cleared")
    func importsFiledVideo() async throws {
        let inbox = try makeInbox()
        defer { try? FileManager.default.removeItem(at: inbox) }
        let filed = try file(named: "\(identifier())~Holiday Clip.mov", in: inbox)

        let handler = IncomingVideoHandler()
        let imported = try #require(await handler.importHandedOffVideos(from: [inbox]))
        defer { try? FileManager.default.removeItem(at: imported) }

        #expect(imported.deletingLastPathComponent().path == VideoStore.directory.path)
        #expect(imported.lastPathComponent.hasPrefix("Holiday Clip"))
        #expect(!FileManager.default.fileExists(atPath: filed.path))
        #expect(handler.readyVideoURL?.path == imported.path)
        #expect(handler.state == .idle)
    }

    @Test("The newest of several videos is the one that opens")
    func publishesNewestVideo() async throws {
        let inbox = try makeInbox()
        defer { try? FileManager.default.removeItem(at: inbox) }
        let older = try file(named: "1111~Older.mov", in: inbox, modified: Date().addingTimeInterval(-600))
        let newer = try file(named: "2222~Newer.mov", in: inbox)

        let handler = IncomingVideoHandler()
        let imported = try #require(await handler.importHandedOffVideos(from: [inbox]))
        defer { try? FileManager.default.removeItem(at: imported) }

        #expect(imported.lastPathComponent.hasPrefix("Newer"))
        #expect(handler.readyVideoURL?.path == imported.path)
        // Both are collected, so a batch share does not leave files behind.
        #expect(!FileManager.default.fileExists(atPath: older.path))
        #expect(!FileManager.default.fileExists(atPath: newer.path))
    }

    @Test("An empty inbox is not an error")
    func emptyInboxIsANoOp() async throws {
        let inbox = try makeInbox()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let handler = IncomingVideoHandler()
        #expect(await handler.importHandedOffVideos(from: [inbox]) == nil)
        #expect(handler.readyVideoURL == nil)
        #expect(handler.state == .idle)
    }

    @Test("Files the app cannot use are ignored, and left where they are")
    func ignoresOtherFiles() async throws {
        let inbox = try makeInbox()
        defer { try? FileManager.default.removeItem(at: inbox) }
        let document = try file(named: "3333~notes.txt", in: inbox)

        let handler = IncomingVideoHandler()
        #expect(await handler.importHandedOffVideos(from: [inbox]) == nil)
        #expect(FileManager.default.fileExists(atPath: document.path))
        #expect(handler.readyVideoURL == nil)
        #expect(handler.state == .idle)
    }

    @Test("A video dropped into the app's Documents folder is picked up too")
    func importsFromDocumentsFolder() async throws {
        let documents = try makeInbox()
        defer { try? FileManager.default.removeItem(at: documents) }
        let dropped = try file(named: "Dropped.mov", in: documents)

        let handler = IncomingVideoHandler()
        let imported = try #require(await handler.importHandedOffVideos(from: [documents]))
        defer { try? FileManager.default.removeItem(at: imported) }

        #expect(imported.lastPathComponent.hasPrefix("Dropped"))
        #expect(!FileManager.default.fileExists(atPath: dropped.path))
    }

    @Test("The display name drops the identifier the extension prefixes")
    func displayNameStripsIdentifier() {
        #expect(VideoInbox.displayName(for: URL(fileURLWithPath: "/tmp/1C9E1F0A4B5D~Holiday Clip.mov")) == "Holiday Clip.mov")
        #expect(VideoInbox.displayName(for: URL(fileURLWithPath: "/tmp/Holiday.mov")) == "Holiday.mov")
        // A name that contains the separator is left alone rather than cut short.
        #expect(VideoInbox.displayName(for: URL(fileURLWithPath: "/tmp/~Holiday.mov")) == "Holiday.mov")
    }

    /// The identifier the extension puts in front of the file name.
    private func identifier() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}
