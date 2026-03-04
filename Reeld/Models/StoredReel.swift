import Foundation

struct StoredReel: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case chapterIndex
        case text
    }

    enum Kind: String, Codable {
        case chapterTitle
        case content
    }

    let id: UUID
    let kind: Kind
    let chapterIndex: Int
    let text: String

    init(from reel: Reel) {
        id = reel.id
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try container.decode(Kind.self, forKey: .kind)
        chapterIndex = try container.decode(Int.self, forKey: .chapterIndex)
        text = try container.decode(String.self, forKey: .text)
    }

    var asReel: Reel {
        switch kind {
        case .chapterTitle:
            return Reel(id: id, content: .chapterTitle(index: chapterIndex, title: text))
        case .content:
            return Reel(id: id, content: .content(chapterIndex: chapterIndex, text: text))
        }
    }
}
