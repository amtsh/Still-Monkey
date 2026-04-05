import Foundation

extension Reel {
    /// Short title for bookmarks and navigation when a chapter title is known.
    func displayBookmarkTitle(chapterTitle: String?) -> String {
        if let chapterTitle, !chapterTitle.isEmpty { return chapterTitle }
        switch content {
        case .chapterTitle(_, let title):
            return title
        case .content(_, let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count <= 56 { return trimmed }
            return String(trimmed.prefix(56)) + "…"
        }
    }
}
