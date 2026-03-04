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
    var contentMode: ContentMode = .learn
    var reels: [Reel] = []
    var isLoading: Bool = false
    var error: String?
    var recentItems: [RecentContentSnapshot] = []

    private let service = OpenRouterService()
    private var streamBuffer = ""
    private var parser = ReelContentParser()

    private static let recentSnapshotsKey = "recentContentSnapshots"
    private static let maxRecentItems = 10

    init() {
        recentItems = loadRecentSnapshots()
    }

    func generateContent() async {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return }

        let apiKey = UserDefaults.standard.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add your OpenRouter API key in Settings before generating."
            return
        }

        reels = []
        error = nil
        isLoading = true
        streamBuffer = ""
        parser.reset()

        do {
            let prompt = ContentPromptLibrary.prompt(for: contentMode, topic: trimmedTopic)
            let stream = service.stream(
                prompt: prompt.userPrompt,
                systemPrompt: prompt.systemPrompt,
                apiKey: apiKey
            )
            for try await token in stream {
                streamBuffer += token
                processBuffer()
            }
            flushBuffer()
            if !reels.isEmpty {
                saveRecentSnapshot(topic: trimmedTopic, mode: contentMode, reels: reels)
            }
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

    func loadRecentSnapshot(_ snapshot: RecentContentSnapshot) {
        topic = snapshot.topic
        contentMode = snapshot.mode
        reels = snapshot.hydrateReels()
        error = nil
        isLoading = false
        streamBuffer = ""
        parser.reset()
        saveRecentSnapshot(topic: snapshot.topic, mode: snapshot.mode, reels: reels)
    }

    private func loadRecentSnapshots() -> [RecentContentSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: Self.recentSnapshotsKey) else {
            return []
        }

        do {
            let snapshots = try JSONDecoder().decode([RecentContentSnapshot].self, from: data)
            return Array(snapshots.prefix(Self.maxRecentItems))
        } catch {
            return []
        }
    }

    private func saveRecentSnapshot(topic: String, mode: ContentMode, reels: [Reel]) {
        let normalizedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTopic.isEmpty, !reels.isEmpty else { return }

        let snapshot = RecentContentSnapshot(
            topic: normalizedTopic,
            mode: mode,
            reels: reels.map(StoredReel.init(from:)),
            updatedAt: .now
        )

        var updated = recentItems.filter {
            !($0.topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTopic.lowercased() && $0.mode == mode)
        }
        updated.insert(snapshot, at: 0)
        recentItems = Array(updated.prefix(Self.maxRecentItems))

        do {
            let data = try JSONEncoder().encode(recentItems)
            UserDefaults.standard.set(data, forKey: Self.recentSnapshotsKey)
        } catch {
            return
        }
    }

    private func processLine(_ line: String) {
        guard let reel = parser.parseLine(line) else { return }
        reels.append(reel)
    }
}

struct ReelContentParser {
    private(set) var chapterCount = 0

    mutating func reset() {
        chapterCount = 0
    }

    mutating func parseLine(_ line: String) -> Reel? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("CHAPTER:") {
            let title = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            chapterCount += 1
            return Reel(content: .chapterTitle(index: chapterCount, title: title))
        }

        guard chapterCount > 0, let text = Self.extractBulletText(from: trimmed), !text.isEmpty else {
            return nil
        }

        return Reel(content: .content(chapterIndex: chapterCount, text: text))
    }

    static func extractBulletText(from line: String) -> String? {
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
            return String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let regex = try? NSRegularExpression(pattern: #"^\d+[.)]\s+"#) {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, options: [], range: range),
               let swiftRange = Range(match.range, in: line) {
                return String(line[swiftRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return nil
    }
}
