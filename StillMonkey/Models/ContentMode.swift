import Foundation

enum ContentMode: String, CaseIterable, Codable {
    case path = "Path"
    case story = "Story"
    case learn = "Learn"

    var tabLabel: String {
        rawValue
    }

    var composerPlaceholder: String {
        switch self {
        case .learn:
            return "What do you want to learn?"
        case .story:
            return "What story do you want to read?"
        case .path:
            return "What do you want to master?"
        }
    }

    var loadingMessage: String {
        switch self {
        case .learn:
            return "Cooking ..."
        case .story:
            return "Writing your story ..."
        case .path:
            return "Building your lesson path ..."
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .learn:
            return "Enter a topic to start learning"
        case .story:
            return "Enter a topic to start reading a story"
        case .path:
            return "Enter a topic to build a lesson path"
        }
    }

    var defaultFeedTitle: String {
        switch self {
        case .learn:
            return "Feed"
        case .story:
            return "Story"
        case .path:
            return "Path"
        }
    }
}
