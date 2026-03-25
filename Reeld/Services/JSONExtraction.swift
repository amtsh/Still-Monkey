import Foundation

/// Extracts the first top-level JSON object from LLM output. Balances `{` … `}` while respecting strings and escapes
/// so `}` inside `"…"` does not truncate the payload (unlike `firstIndex`/`lastIndex` of braces).
enum JSONExtraction {
    static func extractFirstJSONObject(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.firstIndex(of: "{") else { return trimmed }

        var depth = 0
        var inString = false
        var escapeNext = false
        var i = start

        while i < trimmed.endIndex {
            let ch = trimmed[i]

            if inString {
                if escapeNext {
                    escapeNext = false
                } else if ch == "\\" {
                    escapeNext = true
                } else if ch == "\"" {
                    inString = false
                }
                i = trimmed.index(after: i)
                continue
            }

            switch ch {
            case "\"":
                inString = true
            case "{":
                depth += 1
            case "}":
                depth -= 1
                if depth == 0 {
                    return String(trimmed[start ... i])
                }
            default:
                break
            }
            i = trimmed.index(after: i)
        }

        return String(trimmed[start...])
    }
}
