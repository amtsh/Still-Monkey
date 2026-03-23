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

    func generateContent() async {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return }
        guard let prompt = ContentPromptLibrary.prompt(for: contentMode, topic: trimmedTopic) else {
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

        for attempt in 0 ..< LLMRetry.maxAttempts {
            reels = []
            error = nil
            streamBuffer = ""
            parser.reset()

            do {
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
            return "Could not read the model’s response after retrying. Try again or rephrase your topic."
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
                return "App configuration error. Update Reeld or contact support."
            case .invalidResponse:
                return "The server returned an unexpected response. Try again."
            case .streamFailed(let message):
                return "OpenRouter: \(message)"
            case .httpError(let code, _):
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

    private func processLine(_ line: String) {
        guard let reel = parser.parseLine(line) else { return }
        reels.append(reel)
    }
}
