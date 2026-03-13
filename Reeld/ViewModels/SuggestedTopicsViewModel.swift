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
    private var retryCount = 0

    private let service = OpenRouterService()
    private static let maxRetries = 3
    private static let cacheKey = "suggestedTopicsCache"
    private static let systemPrompt = """
    Return only a JSON array of 5 to 7 curious topic strings. No other text or explanation.
    Example: ["Understanding Quarks", "Avoiding Diabetes", "Effect of Posture on Mindset"]
    """
    private static let userPrompt = "List of curious topics"

    init() {
        topics = loadCachedTopics()
    }

    func fetchTrendingTopics() async {
        let apiKey = UserDefaults.standard.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add OpenRouter API key in Settings."
            return
        }

        topics = []
        error = nil
        isLoading = true
        retryCount = 0

        await fetchWithRetries(apiKey: apiKey)
        isLoading = false
    }

    private func fetchWithRetries(apiKey: String) async {
        for attempt in 0 ..< Self.maxRetries {
            do {
                let content = try await service.fetchJSON(
                    prompt: Self.userPrompt,
                    systemPrompt: Self.systemPrompt,
                    apiKey: apiKey
                )
                if let parsed = parseTopics(from: content) {
                    topics = parsed
                    saveCachedTopics(parsed)
                    return
                }
                throw SuggestedTopicsError.invalidFormat
            } catch {
                retryCount = attempt + 1
                if attempt < Self.maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    self.error = "Could not load suggestions. Try again."
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
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func saveCachedTopics(_ topics: [String]) {
        guard let data = try? JSONEncoder().encode(topics) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }

    enum SuggestedTopicsError: Error {
        case invalidFormat
    }
}
