import Foundation

struct ReelContentParser {
    private(set) var chapterCount = 0

    mutating func reset() {
        chapterCount = 0
    }

    mutating func parseLine(_ line: String) -> Reel? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let title = Self.extractChapterTitle(from: trimmed) {
            guard !title.isEmpty else { return nil }
            chapterCount += 1
            return Reel(content: .chapterTitle(index: chapterCount, title: title))
        }

        guard chapterCount > 0, let text = Self.extractBulletText(from: trimmed), !text.isEmpty else {
            return nil
        }

        return Reel(content: .content(chapterIndex: chapterCount, text: text))
    }

    private static func extractChapterTitle(from line: String) -> String? {
        let normalized = line
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let patterns = [
            #"(?i)^\s*(?:#{1,6}\s*)?chapter\s*\d*\s*[:\-]\s*(.+?)\s*$"#,
            #"(?i)^\s*(?:#{1,6}\s*)?chapter\s+(.+?)\s*$"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(normalized.startIndex..., in: normalized)
            guard
                let match = regex.firstMatch(in: normalized, options: [], range: range),
                match.numberOfRanges > 1,
                let titleRange = Range(match.range(at: 1), in: normalized)
            else { continue }
            let title = String(normalized[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { return title }
        }

        return nil
    }

    static func extractBulletText(from line: String) -> String? {
        let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("- ") || normalized.hasPrefix("* ") || normalized.hasPrefix("• ") || normalized.hasPrefix("– ") || normalized.hasPrefix("— ") {
            return String(normalized.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let regex = try? NSRegularExpression(pattern: #"^\s*(?:[-*•–—]\s+|\d+[.)]\s+)"#) {
            let range = NSRange(normalized.startIndex..., in: normalized)
            if let match = regex.firstMatch(in: normalized, options: [], range: range),
               let swiftRange = Range(match.range, in: normalized) {
                return String(normalized[swiftRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return nil
    }
}
