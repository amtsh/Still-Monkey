//
//  SuggestedTopicsViewModel.swift
//  Still Monkey
//

import Foundation
import Observation

struct SuggestedTopicsByMode: Codable, Equatable {
    var learn: [String]
    var story: [String]
    var path: [String]

    static let empty = SuggestedTopicsByMode(learn: [], story: [], path: [])

    var isComplete: Bool {
        learn.count == 3 && story.count == 3 && path.count == 3
    }
}

struct SuggestedTopicRow: Identifiable, Hashable {
    let id: String
    let topic: String
    let mode: ContentMode
}

@Observable
@MainActor
final class SuggestedTopicsViewModel {
    private(set) var payload: SuggestedTopicsByMode = .empty
    var isLoading = false
    var error: String?
    /// True when topics are shown from cache after a failed refresh (user is offline or API failed).
    var showCachedTopicsNotice = false
    private var retryCount = 0

    private let service: any OpenRouterServing
    private let userDefaults: UserDefaults

    private static let cacheKey = "suggestedTopicsByModeCache"

    private static let systemPrompt = """
    Return only valid JSON matching this exact shape. No markdown, code fences, or commentary.

    {
      "learn": ["Topic for learning mode 1", "Topic 2", "Topic 3"],
      "story": ["Topic for story mode 1", "Topic 2", "Topic 3"],
      "path": ["Topic for lesson-path mode 1", "Topic 2", "Topic 3"]
    }

    Rules:
    - Each array must contain exactly 3 distinct, specific topic strings.
    - "learn": educational / explanatory topics suited to a learning feed.
    - "story": narrative topics suited to story-style reading.
    - "path": topics suited to a structured multi-lesson course path (mastery / skills).
    - Do not reuse the same topic string across learn, story, and path.
    """

    private static let userPrompt = "Generate topic suggestions for three modes: Learn, Story, and Path."

    var topicRows: [SuggestedTopicRow] {
        ContentMode.allCases.flatMap { mode in
            let topics = topics(for: mode)
            return topics.enumerated().map { index, topic in
                SuggestedTopicRow(
                    id: "\(mode.rawValue)|\(index)|\(topic)",
                    topic: topic,
                    mode: mode
                )
            }
        }
    }

    init(
        service: any OpenRouterServing = OpenRouterService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
        payload = loadCachedPayload()
    }

    private func topics(for mode: ContentMode) -> [String] {
        switch mode {
        case .learn:
            payload.learn
        case .story:
            payload.story
        case .path:
            payload.path
        }
    }

    /// Loads suggestions when cache is missing or incomplete.
    func fetchIfEmpty() async {
        guard !payload.isComplete, !isLoading else { return }
        await fetchTrendingTopics()
    }

    func fetchTrendingTopics() async {
        let apiKey = userDefaults.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add OpenRouter API key in Settings."
            return
        }

        let previousPayload = payload
        error = nil
        showCachedTopicsNotice = false
        isLoading = true
        retryCount = 0

        await fetchWithRetries(apiKey: apiKey, previousPayload: previousPayload)
        isLoading = false
    }

    private func fetchWithRetries(apiKey: String, previousPayload: SuggestedTopicsByMode) async {
        for attempt in 0 ..< LLMRetry.maxAttempts {
            do {
                let content = try await service.fetchJSONWithRetry(
                    prompt: Self.userPrompt,
                    systemPrompt: Self.systemPrompt,
                    apiKey: apiKey,
                    maxTokens: 1200
                )
                if let parsed = parsePayload(from: content) {
                    payload = parsed
                    saveCachedPayload(parsed)
                    showCachedTopicsNotice = false
                    return
                }
                throw SuggestedTopicsError.invalidFormat
            } catch {
                retryCount = attempt + 1
                if attempt < LLMRetry.maxAttempts - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    let cached = loadCachedPayload()
                    if cached.isComplete {
                        payload = cached
                        showCachedTopicsNotice = true
                        self.error = nil
                    } else if previousPayload.isComplete {
                        payload = previousPayload
                        showCachedTopicsNotice = true
                        self.error = nil
                    } else {
                        payload = .empty
                        showCachedTopicsNotice = false
                        self.error = "Could not load suggestions. Try again."
                    }
                }
            }
        }
    }

    private struct SuggestedAPIEnvelope: Decodable {
        let learn: [String]
        let story: [String]
        let path: [String]
    }

    private func parsePayload(from content: String) -> SuggestedTopicsByMode? {
        let json = JSONExtraction.extractFirstJSONObject(from: content)
        guard let data = json.data(using: .utf8) else { return nil }
        guard let envelope = try? JSONDecoder().decode(SuggestedAPIEnvelope.self, from: data) else { return nil }

        let learn = normalizeTopicArray(envelope.learn)
        let story = normalizeTopicArray(envelope.story)
        let path = normalizeTopicArray(envelope.path)
        guard learn.count == 3, story.count == 3, path.count == 3 else { return nil }

        return SuggestedTopicsByMode(learn: learn, story: story, path: path)
    }

    private func normalizeTopicArray(_ raw: [String]) -> [String] {
        let trimmed = raw.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return Array(trimmed.prefix(3))
    }

    private func loadCachedPayload() -> SuggestedTopicsByMode {
        guard let data = userDefaults.data(forKey: Self.cacheKey) else { return .empty }
        if let decoded = try? JSONDecoder().decode(SuggestedTopicsByMode.self, from: data), decoded.isComplete {
            return decoded
        }
        return .empty
    }

    private func saveCachedPayload(_ payload: SuggestedTopicsByMode) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        userDefaults.set(data, forKey: Self.cacheKey)
    }

    enum SuggestedTopicsError: Error {
        case invalidFormat
    }
}
