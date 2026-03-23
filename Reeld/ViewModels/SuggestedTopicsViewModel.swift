//
//  SuggestedTopicsViewModel.swift
//  Reeld
//

import Foundation
import Observation

@Observable
@MainActor
final class SuggestedTopicsViewModel {
    var topics: [String] = []
    var isLoading = false
    var error: String?
    /// True when topics are shown from cache after a failed refresh (user is offline or API failed).
    var showCachedTopicsNotice = false
    private var retryCount = 0

    private let service: any OpenRouterServing
    private let userDefaults: UserDefaults
    private static let cacheKey = "suggestedTopicsCache"
    private static let systemPrompt = """
    Return only a JSON array of 5 to 7 curious topic strings. No other text or explanation.
    Example: ["Understanding Quarks", "Avoiding Diabetes", "Effect of Posture on Mindset"]
    """
    private static let userPrompt = "List of curious topics"

    init(
        service: any OpenRouterServing = OpenRouterService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
        topics = loadCachedTopics()
    }

    func fetchTrendingTopics() async {
        let apiKey = userDefaults.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add OpenRouter API key in Settings."
            return
        }

        let previousTopics = topics
        error = nil
        showCachedTopicsNotice = false
        isLoading = true
        retryCount = 0

        await fetchWithRetries(apiKey: apiKey, previousTopics: previousTopics)
        isLoading = false
    }

    private func fetchWithRetries(apiKey: String, previousTopics: [String]) async {
        for attempt in 0 ..< LLMRetry.maxAttempts {
            do {
                let content = try await service.fetchJSONWithRetry(
                    prompt: Self.userPrompt,
                    systemPrompt: Self.systemPrompt,
                    apiKey: apiKey,
                    maxTokens: 300
                )
                if let parsed = parseTopics(from: content) {
                    topics = parsed
                    saveCachedTopics(parsed)
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
                    let cached = loadCachedTopics()
                    if !cached.isEmpty {
                        topics = cached
                        showCachedTopicsNotice = true
                        self.error = nil
                    } else if !previousTopics.isEmpty {
                        topics = previousTopics
                        showCachedTopicsNotice = true
                        self.error = nil
                    } else {
                        topics = []
                        showCachedTopicsNotice = false
                        self.error = "Could not load suggestions. Try again."
                    }
                }
            }
        }
    }

    private func parseTopics(from content: String) -> [String]? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return nil }
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [String] else { return nil }
        return array.isEmpty ? nil : array
    }

    private func loadCachedTopics() -> [String] {
        guard let data = userDefaults.data(forKey: Self.cacheKey) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func saveCachedTopics(_ topics: [String]) {
        guard let data = try? JSONEncoder().encode(topics) else { return }
        userDefaults.set(data, forKey: Self.cacheKey)
    }

    enum SuggestedTopicsError: Error {
        case invalidFormat
    }
}
