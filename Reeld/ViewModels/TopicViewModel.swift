//
//  TopicViewModel.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import Foundation
import Observation

@Observable
final class TopicViewModel {
    var topic: String = ""
    var reels: [Reel] = []
    var isLoading: Bool = false
    var error: String?
    var recentTopics: [String] = []

    private let service = OpenRouterService()
    private var streamBuffer = ""
    private var chapterCount = 0

    private static let recentTopicsKey = "recentTopics"
    private static let maxRecentTopics = 5

    init() {
        recentTopics = UserDefaults.standard.stringArray(forKey: Self.recentTopicsKey) ?? []
    }

    func generateContent() async {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return }

        let apiKey = UserDefaults.standard.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add your OpenRouter API key in Settings before generating."
            return
        }

        saveRecentTopic(trimmedTopic)

        reels = []
        error = nil
        isLoading = true
        streamBuffer = ""
        chapterCount = 0

        let systemPrompt = """
        You are a concise educational assistant. Break the topic into many chapters.
        Format your ENTIRE response exactly like this template with no preamble or extra text:

        CHAPTER: Chapter Title Here
        - Key concept explained in 50 words or less
        - Another key concept in 50 words or less
        - Third key concept in 50 words or less

        CHAPTER: Second Chapter Title
        - First point in 50 words or less
        - Second point in 50 words or less
        - Third point in 50 words or less

        Every chapter must have exactly 10 bullet points starting with "- ".
        Do not include any other text outside this format.
        """

        do {
            let stream = service.stream(prompt: trimmedTopic, systemPrompt: systemPrompt, apiKey: apiKey)
            for try await token in stream {
                streamBuffer += token
                processBuffer()
            }
            flushBuffer()
        } catch {
            self.error = "Failed to generate content: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func processBuffer() {
        let lines = streamBuffer.components(separatedBy: "\n")
        guard lines.count > 1 else { return }
        for line in lines.dropLast() {
            processLine(line)
        }
        streamBuffer = lines.last ?? ""
    }

    private func flushBuffer() {
        guard !streamBuffer.isEmpty else { return }
        processLine(streamBuffer)
        streamBuffer = ""
    }

    private func saveRecentTopic(_ topic: String) {
        var updated = recentTopics.filter { $0.lowercased() != topic.lowercased() }
        updated.insert(topic, at: 0)
        recentTopics = Array(updated.prefix(Self.maxRecentTopics))
        UserDefaults.standard.set(recentTopics, forKey: Self.recentTopicsKey)
    }

    private func processLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix("CHAPTER:") {
            let title = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return }
            chapterCount += 1
            reels.append(Reel(content: .chapterTitle(index: chapterCount, title: title)))
        } else if trimmed.hasPrefix("- ") {
            let text = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            reels.append(Reel(content: .content(chapterIndex: chapterCount, text: text)))
        }
    }
}
