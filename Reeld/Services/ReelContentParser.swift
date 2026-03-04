import Foundation

struct ReelContentParser {
    private(set) var chapterCount = 0

    mutating func reset() {
        chapterCount = 0
    }

    mutating func parseLine(_ line: String) -> Reel? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("CHAPTER:") {
            let title = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            chapterCount += 1
            return Reel(content: .chapterTitle(index: chapterCount, title: title))
        }

        guard chapterCount > 0, let text = Self.extractBulletText(from: trimmed), !text.isEmpty else {
            return nil
        }

        return Reel(content: .content(chapterIndex: chapterCount, text: text))
    }

    static func extractBulletText(from line: String) -> String? {
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
            return String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let regex = try? NSRegularExpression(pattern: #"^\d+[.)]\s+"#) {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, options: [], range: range),
               let swiftRange = Range(match.range, in: line) {
                return String(line[swiftRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return nil
    }
}
