import Foundation

extension OpenRouterServing {
    /// Performs `fetchJSON` up to `LLMRetry.maxAttempts` times with a short backoff between failures.
    func fetchJSONWithRetry(
        prompt: String,
        systemPrompt: String,
        apiKey: String,
        maxTokens: Int
    ) async throws -> String {
        var lastError: Error?
        for attempt in 0 ..< LLMRetry.maxAttempts {
            do {
                return try await fetchJSON(
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    apiKey: apiKey,
                    maxTokens: maxTokens
                )
            } catch {
                lastError = error
                if attempt < LLMRetry.maxAttempts - 1 {
                    await LLMRetry.delayBetweenAttempts()
                }
            }
        }
        throw lastError ?? URLError(.unknown)
    }
}
