//
//  ReeldTests.swift
//  ReeldTests
//
//  Created by Amit Shinde on 2026-03-04.
//

import Testing
@testable import Reeld

struct ReeldTests {
    @Test func parserCreatesChapterAndContentReelsFromValidLines() {
        var parser = ReelContentParser()
        let input = [
            "CHAPTER: Intro to Quantum Computing",
            "- Qubits can represent superposition states unlike binary bits. This enables richer state encoding and potentially more efficient problem-solving for specific algorithms.",
            "- Measurement collapses state probabilities into a classical outcome."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 3)
        assertChapter(reels[0], index: 1, title: "Intro to Quantum Computing")
        assertContent(
            reels[1],
            chapterIndex: 1,
            textContains: "Qubits can represent superposition states"
        )
        assertContent(
            reels[2],
            chapterIndex: 1,
            textContains: "Measurement collapses state probabilities"
        )
    }

    @Test func parserSupportsMultipleBulletPrefixes() {
        var parser = ReelContentParser()
        let input = [
            "CHAPTER: Networking Basics",
            "* TCP ensures ordered delivery by tracking sequence numbers and retransmissions when packets are lost.",
            "• UDP favors low latency over reliability, useful for streaming and real-time communication.",
            "1. HTTP defines a request-response protocol for transferring web resources across clients and servers.",
            "2) TLS adds encryption and authentication to protect data in transit."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 5)
        for reel in reels.dropFirst() {
            assertContent(reel, chapterIndex: 1, textContains: "")
        }
    }

    @Test func parserIgnoresBulletsBeforeFirstChapter() {
        var parser = ReelContentParser()
        let input = [
            "- This should be ignored because no chapter exists yet.",
            "CHAPTER: First Real Chapter",
            "- This should be included."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 2)
        assertChapter(reels[0], index: 1, title: "First Real Chapter")
        assertContent(reels[1], chapterIndex: 1, textContains: "This should be included")
    }

    @Test func parserIncrementsChapterIndexAcrossChapters() {
        var parser = ReelContentParser()
        let input = [
            "CHAPTER: Foundations",
            "- A first bullet for chapter one.",
            "CHAPTER: Advanced Concepts",
            "- A first bullet for chapter two."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 4)
        assertChapter(reels[0], index: 1, title: "Foundations")
        assertContent(reels[1], chapterIndex: 1, textContains: "chapter one")
        assertChapter(reels[2], index: 2, title: "Advanced Concepts")
        assertContent(reels[3], chapterIndex: 2, textContains: "chapter two")
    }

    @Test func parserResetClearsChapterState() {
        var parser = ReelContentParser()
        _ = parser.parseLine("CHAPTER: Temporary")
        parser.reset()
        let reel = parser.parseLine("CHAPTER: Fresh Start")

        #expect(reel != nil)
        if let reel {
            assertChapter(reel, index: 1, title: "Fresh Start")
        }
    }

    @Test func systemPromptContainsCriticalFormattingRules() {
        let prompt = TopicViewModel.systemPrompt
        #expect(prompt.contains("exactly 10 bullet points"))
        #expect(prompt.contains("Every bullet must be on its own line and start with \"- \""))
        #expect(prompt.contains("Do not include any text outside this format."))
    }

    private func assertChapter(_ reel: Reel, index: Int, title: String) {
        switch reel.content {
        case .chapterTitle(let actualIndex, let actualTitle):
            #expect(actualIndex == index)
            #expect(actualTitle == title)
        default:
            Issue.record("Expected chapterTitle, got content reel.")
        }
    }

    private func assertContent(_ reel: Reel, chapterIndex: Int, textContains: String) {
        switch reel.content {
        case .content(let actualChapterIndex, let text):
            #expect(actualChapterIndex == chapterIndex)
            if !textContains.isEmpty {
                #expect(text.contains(textContains))
            }
        default:
            Issue.record("Expected content reel, got chapterTitle reel.")
        }
    }
}
