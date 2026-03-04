import Foundation

struct OpenRouterService {
    func stream(prompt: String, systemPrompt: String, apiKey: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await consumeStream(
                        prompt: prompt,
                        systemPrompt: systemPrompt,
                        apiKey: apiKey,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func consumeStream(
        prompt: String,
        systemPrompt: String,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let url = URL(string: Config.openRouterEndpoint) else {
            throw OpenRouterError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "model": Config.openRouterModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.6,
            "max_tokens": 1500,
            "stream": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw OpenRouterError.httpError(httpResponse.statusCode, "Request failed")
        }

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let data = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            if data == "[DONE]" {
                return
            }
            guard let chunkData = data.data(using: .utf8) else { continue }
            let json = try JSONSerialization.jsonObject(with: chunkData) as? [String: Any]

            if let error = json?["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenRouterError.streamFailed(message)
            }

            guard
                let choices = json?["choices"] as? [[String: Any]],
                let delta = choices.first?["delta"] as? [String: Any]
            else {
                continue
            }

            if let text = delta["content"] as? String, !text.isEmpty {
                continuation.yield(text)
                continue
            }

            if let contentParts = delta["content"] as? [[String: Any]] {
                for part in contentParts {
                    if let text = part["text"] as? String, !text.isEmpty {
                        continuation.yield(text)
                    }
                }
            }
        }
    }

    enum OpenRouterError: Error, LocalizedError {
        case invalidEndpoint
        case invalidResponse
        case streamFailed(String)
        case httpError(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidEndpoint:
                return "Invalid OpenRouter endpoint."
            case .invalidResponse:
                return "Invalid response from OpenRouter."
            case .streamFailed(let message):
                return "OpenRouter error: \(message)"
            case .httpError(let code, let body):
                return "HTTP \(code): \(body)"
            }
        }
    }
}
