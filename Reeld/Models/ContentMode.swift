import Foundation

enum ContentMode: String, CaseIterable, Codable {
    case learn = "Learn"
    case story = "Story"
    case duolingo = "Duolingo"

    var tabLabel: String {
        rawValue
    }

    var composerPlaceholder: String {
        switch self {
        case .learn:
            return "What do you want to learn?"
        case .story:
            return "What story do you want to read?"
        case .duolingo:
            return "What do you want to master?"
        }
    }

    var loadingMessage: String {
        switch self {
        case .learn:
            return "Cooking ..."
        case .story:
            return "Writing your story ..."
        case .duolingo:
            return "Building your lesson path ..."
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .learn:
            return "Enter a topic to start learning"
        case .story:
            return "Enter a topic to start reading a story"
        case .duolingo:
            return "Enter a topic to build a lesson path"
        }
    }

    var defaultFeedTitle: String {
        switch self {
        case .learn:
            return "Feed"
        case .story:
            return "Story"
        case .duolingo:
            return "Path"
        }
    }
}
