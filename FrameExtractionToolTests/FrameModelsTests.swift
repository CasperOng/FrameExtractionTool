//
//  FrameModelsTests.swift
//  FrameExtractionToolTests
//

import AVFoundation
import Testing
@testable import FrameExtractionTool

@Suite("Frame timing")
struct FrameModelsTests {

    @Test("Time codes use mm:ss.hh and add hours only when needed")
    func timeCodeFormatting() {
        #expect(MarkedFrame.timeString(fromSeconds: 0) == "00:00.00")
        #expect(MarkedFrame.timeString(fromSeconds: 5.2) == "00:05.20")
        #expect(MarkedFrame.timeString(fromSeconds: 65.5) == "01:05.50")
        #expect(MarkedFrame.timeString(fromSeconds: 9.999) == "00:10.00")
        #expect(MarkedFrame.timeString(fromSeconds: 3661.99) == "1:01:01.99")
    }

    @Test("Impossible times are clamped instead of rendering junk")
    func timeCodeClamping() {
        #expect(MarkedFrame.timeString(fromSeconds: -12) == "00:00.00")
        #expect(MarkedFrame.timeString(fromSeconds: .nan) == "00:00.00")
        #expect(MarkedFrame.timeString(fromSeconds: .infinity) == "00:00.00")
    }

    @Test("A marked frame reports the time it was taken at")
    func markedFrameTimeString() {
        let frame = MarkedFrame(
            timeStamp: CMTime(seconds: 12.34, preferredTimescale: 600),
            videoURL: URL(fileURLWithPath: "/tmp/clip.mov")
        )
        #expect(frame.timeString == "00:12.34")
        #expect(abs(frame.seconds - 12.34) < 0.001)
    }

    @Test("VoiceOver gets words, not a clock")
    func spokenTimeString() {
        let short = MarkedFrame(timeStamp: .zero, videoURL: URL(fileURLWithPath: "/tmp/a.mov"))
        #expect(short.accessibilityTimeString == "0 seconds")

        let minute = MarkedFrame(
            timeStamp: CMTime(seconds: 65, preferredTimescale: 600),
            videoURL: URL(fileURLWithPath: "/tmp/a.mov")
        )
        #expect(minute.accessibilityTimeString == "1 minute 5 seconds")

        let twoMinutes = MarkedFrame(
            timeStamp: CMTime(seconds: 120, preferredTimescale: 600),
            videoURL: URL(fileURLWithPath: "/tmp/a.mov")
        )
        #expect(twoMinutes.accessibilityTimeString == "2 minutes 0 seconds")
    }
}
