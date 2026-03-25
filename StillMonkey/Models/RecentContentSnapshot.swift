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
