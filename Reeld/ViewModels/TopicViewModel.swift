//
//  TopicViewModel.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import Foundation
import Observation

@Observable
@MainActor
final class TopicViewModel {
    var topic: String = ""
    var contentMode: ContentMode = .learn
    var reels: [Reel] = []
    var isLoading: Bool = false
    var error: String?
    var recentItems: [RecentContentSnapshot] = []
    var lastAccessedRecentID: String?
    var pendingStartReelID: Reel.ID?

    var chapterTitlesByIndex: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: reels.compactMap { reel in
                guard case let .chapterTitle(index, title) = reel.content else { return nil }
                return (index, title)
            }
        )
    }

    private let service = OpenRouterService()
    private var streamBuffer = ""
    private var parser = ReelContentParser()

    private static let recentSnapshotsKey = "recentContentSnapshots"
    private static let lastAccessedRecentKey = "lastAccessedRecentSnapshotID"
    private static let recentSnapshotLastViewedReelIDsKey = "recentSnapshotLastViewedReelIDs"
    private static let maxRecentItems = 10
    private var activeRecentSnapshotID: String?
    private var lastViewedReelIDsBySnapshotID: [String: String] = [:]

    init() {
        recentItems = loadRecentSnapshots()
        lastAccessedRecentID = UserDefaults.standard.string(forKey: Self.lastAccessedRecentKey)
        if let stored = UserDefaults.standard.dictionary(forKey: Self.recentSnapshotLastViewedReelIDsKey) as? [String: String] {
            lastViewedReelIDsBySnapshotID = stored
        }
    }

    func generateContent() async {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return }

        let apiKey = UserDefaults.standard.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add OpenRouter API key in Settings."
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
            self.error = "Something went wrong. Please check your connection and try again."
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
        lastAccessedRecentID = snapshot.id
        UserDefaults.standard.set(snapshot.id, forKey: Self.lastAccessedRecentKey)
        activeRecentSnapshotID = snapshot.id
        pendingStartReelID = {
            guard
                let rawID = lastViewedReelIDsBySnapshotID[snapshot.id],
                let reelID = UUID(uuidString: rawID),
                reels.contains(where: { $0.id == reelID })
            else { return nil }
            return reelID
        }()
    }

    func recordCurrentReelID(_ reelID: Reel.ID?) {
        guard
            let snapshotID = activeRecentSnapshotID,
            let reelID
        else { return }
        lastViewedReelIDsBySnapshotID[snapshotID] = reelID.uuidString
        UserDefaults.standard.set(lastViewedReelIDsBySnapshotID, forKey: Self.recentSnapshotLastViewedReelIDsKey)
    }

    func consumePendingStartReelID() -> Reel.ID? {
        defer { pendingStartReelID = nil }
        return pendingStartReelID
    }

    func deleteRecentSnapshot(_ snapshot: RecentContentSnapshot) {
        recentItems.removeAll { $0.id == snapshot.id }

        if lastAccessedRecentID == snapshot.id {
            lastAccessedRecentID = nil
            UserDefaults.standard.removeObject(forKey: Self.lastAccessedRecentKey)
        }

        if activeRecentSnapshotID == snapshot.id {
            activeRecentSnapshotID = nil
            pendingStartReelID = nil
        }

        lastViewedReelIDsBySnapshotID.removeValue(forKey: snapshot.id)
        UserDefaults.standard.set(lastViewedReelIDsBySnapshotID, forKey: Self.recentSnapshotLastViewedReelIDsKey)

        do {
            let data = try JSONEncoder().encode(recentItems)
            UserDefaults.standard.set(data, forKey: Self.recentSnapshotsKey)
        } catch {
            return
        }
    }

    private func loadRecentSnapshots() -> [RecentContentSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: Self.recentSnapshotsKey) else {
            return []
        }

        do {
            let snapshots = try JSONDecoder().decode([RecentContentSnapshot].self, from: data)
            return Array(snapshots.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(Self.maxRecentItems))
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
        recentItems = Array(updated.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(Self.maxRecentItems))

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
