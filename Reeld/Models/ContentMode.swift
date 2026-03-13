import Foundation

enum ContentMode: String, CaseIterable, Codable {
    case learn = "Learn"
    case story = "Story"

    var tabLabel: String {
        rawValue
    }

    var composerPlaceholder: String {
        switch self {
        case .learn:
            return "What do you want to learn?"
        case .story:
            return "What story do you want to read?"
        }
    }

    var loadingMessage: String {
        switch self {
        case .learn:
            return "Cooking ..."
        case .story:
            return "Writing your story ..."
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .learn:
            return "Enter a topic to start learning"
        case .story:
            return "Enter a topic to start reading a story"
        }
    }

    var defaultFeedTitle: String {
        switch self {
        case .learn:
            return "Feed"
        case .story:
            return "Story"
        }
    }
}
