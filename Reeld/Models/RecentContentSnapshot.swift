import Foundation

struct RecentContentSnapshot: Codable, Identifiable {
    let topic: String
    let mode: ContentMode
    let reels: [StoredReel]
    let updatedAt: Date

    var id: String {
        "\(mode.rawValue.lowercased())::\(topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    var displayTopic: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
    }

    var modeLabel: String {
        mode.tabLabel
    }

    func hydrateReels() -> [Reel] {
        reels.map(\.asReel)
    }
}

struct StoredReel: Codable {
    enum Kind: String, Codable {
        case chapterTitle
        case content
    }

    let kind: Kind
    let chapterIndex: Int
    let text: String

    init(from reel: Reel) {
        switch reel.content {
        case .chapterTitle(let index, let title):
            kind = .chapterTitle
            chapterIndex = index
            text = title
        case .content(let chapterIndex, let text):
            kind = .content
            self.chapterIndex = chapterIndex
            self.text = text
        }
    }

    var asReel: Reel {
        switch kind {
        case .chapterTitle:
            return Reel(content: .chapterTitle(index: chapterIndex, title: text))
        case .content:
            return Reel(content: .content(chapterIndex: chapterIndex, text: text))
        }
    }
}
