//
//  TopicViewModel.swift
//  Still Monkey
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
        let pairs: [(Int, String)] = reels.compactMap { reel in
            guard case let .chapterTitle(index, title) = reel.content else { return nil }
            return (index, title)
        }
        return Dictionary(pairs, uniquingKeysWith: { _, new in new })
    }

    private let service: any OpenRouterServing
    private let userDefaults: UserDefaults
    private var streamBuffer = ""
    private var parser = ReelContentParser()

    private static let recentSnapshotsKey = "recentContentSnapshots"
    private static let lastAccessedRecentKey = "lastAccessedRecentSnapshotID"
    private static let recentSnapshotLastViewedReelIDsKey = "recentSnapshotLastViewedReelIDs"
    private static let maxRecentItems = 10
    private var activeRecentSnapshotID: String?
    private var lastViewedReelIDsBySnapshotID: [String: String] = [:]

    init(
        service: any OpenRouterServing = OpenRouterService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
        recentItems = loadRecentSnapshots()
        lastAccessedRecentID = userDefaults.string(forKey: Self.lastAccessedRecentKey)
        if let stored = userDefaults.dictionary(forKey: Self.recentSnapshotLastViewedReelIDsKey) as? [String: String] {
            lastViewedReelIDsBySnapshotID = stored
        }
    }

    /// - Parameter topicOverride: When set (e.g. captured before search UI clears `topic`), used instead of `topic` so generation still runs.
    /// - Parameter learnDeeper: Learn mode only—second pass on the same topic with a deeper prompt; uses current reels’ chapter titles before they are cleared.
    func generateContent(topicOverride: String? = nil, learnDeeper: Bool = false) async {
        let trimmedTopic = (topicOverride ?? topic).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return }
        topic = trimmedTopic

        let priorChapterTitles: [String] = {
            guard learnDeeper, contentMode == .learn else { return [] }
            var seen = Set<String>()
            var titles: [String] = []
            for reel in reels {
                if case let .chapterTitle(_, title) = reel.content, seen.insert(title).inserted {
                    titles.append(title)
                }
            }
            return titles
        }()

        let prompt: ContentPrompt?
        if learnDeeper {
            guard contentMode == .learn else { return }
            prompt = ContentPromptLibrary.learnDeeperPrompt(topic: trimmedTopic, priorChapterTitles: priorChapterTitles)
        } else {
            prompt = ContentPromptLibrary.prompt(for: contentMode, topic: trimmedTopic)
        }

        guard let prompt else {
            error = "This mode uses the lesson map flow."
            return
        }

        let apiKey = userDefaults.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add OpenRouter API key in Settings."
            return
        }

        isLoading = true
        defer { isLoading = false }

        var lastError: Error?
        let appendAsNextChapter = learnDeeper && contentMode == .learn
        let existingReels = reels
        let existingMaxChapterIndex = existingReels.map(\.chapterIndex).max() ?? 0

        for attempt in 0 ..< LLMRetry.maxAttempts {
            let keepExistingReelsVisible = appendAsNextChapter

            var generatedReels: [Reel] = []
            var localStreamBuffer = ""
            var localParser = ReelContentParser()

            if keepExistingReelsVisible {
                generatedReels = []
                localStreamBuffer = ""
                localParser.reset()
            } else {
                reels = []
                streamBuffer = ""
                parser.reset()
            }
            error = nil

            do {
                let stream = service.stream(
                    prompt: prompt.userPrompt,
                    systemPrompt: prompt.systemPrompt,
                    apiKey: apiKey
                )
                for try await token in stream {
                    if keepExistingReelsVisible {
                        localStreamBuffer += token
                        processBuffer(
                            streamBuffer: &localStreamBuffer,
                            parser: &localParser,
                            reels: &generatedReels
                        )
                    } else {
                        streamBuffer += token
                        processBuffer(streamBuffer: &streamBuffer, parser: &parser, reels: &reels)
                    }
                }
                if keepExistingReelsVisible {
                    flushBuffer(
                        streamBuffer: &localStreamBuffer,
                        parser: &localParser,
                        reels: &generatedReels
                    )
                } else {
                    flushBuffer(streamBuffer: &streamBuffer, parser: &parser, reels: &reels)
                }

                let finalReels: [Reel]
                let firstNewReelID: Reel.ID?
                if keepExistingReelsVisible {
                    let shiftedGenerated = reelsWithShiftedChapterIndices(
                        generatedReels,
                        chapterOffset: existingMaxChapterIndex
                    )
                    finalReels = existingReels + shiftedGenerated
                    firstNewReelID = shiftedGenerated.first?.id
                } else {
                    finalReels = reels
                    firstNewReelID = nil
                }

                let hasUsableOutput = keepExistingReelsVisible ? !generatedReels.isEmpty : !finalReels.isEmpty
                if hasUsableOutput {
                    if keepExistingReelsVisible {
                        reels = finalReels
                        pendingStartReelID = firstNewReelID
                    }
                    saveRecentSnapshot(topic: trimmedTopic, mode: contentMode, reels: finalReels)
                    HapticsFeedback.generationSucceeded()
                    return
                }
                lastError = TopicGenerationError.emptyOrUnparseableResponse
                if attempt < LLMRetry.maxAttempts - 1 {
                    await LLMRetry.delayBetweenAttempts()
                    continue
                }
            } catch {
                lastError = error
                if attempt < LLMRetry.maxAttempts - 1 {
                    await LLMRetry.delayBetweenAttempts()
                }
            }
        }

        error = Self.userFacingStreamError(lastError)
    }

    private enum TopicGenerationError: LocalizedError {
        case emptyOrUnparseableResponse

        var errorDescription: String? {
            switch self {
            case .emptyOrUnparseableResponse:
                return "The model returned no usable cards."
            }
        }
    }

    private static func userFacingStreamError(_ error: Error?) -> String {
        guard let error else {
            return "Something went wrong. Please try again."
        }
        if error is TopicGenerationError {
            return "Something went wrong. Please try again."
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost:
                return "You appear to be offline. Check your connection and try again."
            case .timedOut:
                return "The request timed out. Try again in a moment."
            case .cannotFindHost, .dnsLookupFailed:
                return "Could not reach the server. Check your network."
            default:
                break
            }
        }
        if let oe = error as? OpenRouterService.OpenRouterError {
            switch oe {
            case .invalidEndpoint:
                return "App configuration error. Update Still Monkey or contact support."
            case .invalidResponse:
                return "The server returned an unexpected response. Try again."
            case let .streamFailed(message):
                return "OpenRouter: \(message)"
            case let .httpError(code, _):
                if code == 401 || code == 403 {
                    return "Your API key was rejected. Check Settings → OpenRouter key."
                }
                if code == 429 {
                    return "Rate limited. Wait a moment and try again."
                }
                return "Server returned error \(code). Try again."
            }
        }
        if let localized = error as? LocalizedError, let description = localized.errorDescription, !description.isEmpty {
            return "Could not load content after retrying. \(description)"
        }
        return "Could not load content after retrying. Please check your connection and try again."
    }

    private func processBuffer(streamBuffer: inout String, parser: inout ReelContentParser, reels: inout [Reel]) {
        let lines = streamBuffer.components(separatedBy: "\n")
        guard lines.count > 1 else { return }
        for line in lines.dropLast() {
            processLine(line, parser: &parser, reels: &reels)
        }
        streamBuffer = lines.last ?? ""
    }

    private func flushBuffer(streamBuffer: inout String, parser: inout ReelContentParser, reels: inout [Reel]) {
        guard !streamBuffer.isEmpty else { return }
        processLine(streamBuffer, parser: &parser, reels: &reels)
        streamBuffer = ""
    }

    private func reelsWithShiftedChapterIndices(_ reels: [Reel], chapterOffset: Int) -> [Reel] {
        guard chapterOffset > 0 else { return reels }
        return reels.map { reel in
            switch reel.content {
            case let .chapterTitle(index, title):
                return Reel(id: reel.id, content: .chapterTitle(index: index + chapterOffset, title: title))
            case let .content(chapterIndex, text):
                return Reel(id: reel.id, content: .content(chapterIndex: chapterIndex + chapterOffset, text: text))
            }
        }
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
        userDefaults.set(snapshot.id, forKey: Self.lastAccessedRecentKey)
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
        userDefaults.set(lastViewedReelIDsBySnapshotID, forKey: Self.recentSnapshotLastViewedReelIDsKey)
    }

    func consumePendingStartReelID() -> Reel.ID? {
        defer { pendingStartReelID = nil }
        return pendingStartReelID
    }

    func deleteRecentSnapshot(_ snapshot: RecentContentSnapshot) {
        recentItems.removeAll { $0.id == snapshot.id }

        if lastAccessedRecentID == snapshot.id {
            lastAccessedRecentID = nil
            userDefaults.removeObject(forKey: Self.lastAccessedRecentKey)
        }

        if activeRecentSnapshotID == snapshot.id {
            activeRecentSnapshotID = nil
            pendingStartReelID = nil
        }

        lastViewedReelIDsBySnapshotID.removeValue(forKey: snapshot.id)
        userDefaults.set(lastViewedReelIDsBySnapshotID, forKey: Self.recentSnapshotLastViewedReelIDsKey)

        do {
            let data = try JSONEncoder().encode(recentItems)
            userDefaults.set(data, forKey: Self.recentSnapshotsKey)
        } catch {
            return
        }
    }

    private func loadRecentSnapshots() -> [RecentContentSnapshot] {
        guard let data = userDefaults.data(forKey: Self.recentSnapshotsKey) else {
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
            userDefaults.set(data, forKey: Self.recentSnapshotsKey)
        } catch {
            return
        }
    }

    private func processLine(_ line: String, parser: inout ReelContentParser, reels: inout [Reel]) {
        guard let reel = parser.parseLine(line) else { return }
        reels.append(reel)
    }
}
