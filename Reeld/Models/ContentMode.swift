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
            return "Learn something new today."
        case .story:
            return "Pick a topic for your next story."
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
