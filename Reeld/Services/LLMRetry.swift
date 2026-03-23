import Foundation

/// Shared policy for OpenRouter calls: one automatic retry after transient failures.
enum LLMRetry {
    static let maxAttempts = 2

    static func delayBetweenAttempts() async {
        try? await Task.sleep(nanoseconds: 750_000_000)
    }
}
