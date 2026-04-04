//
//  HomeRecentItem.swift
//  Still Monkey
//

import Foundation

/// Unified recent row for reels and lesson paths. IDs are prefixed to avoid collisions.
enum HomeRecentItem: Identifiable {
    case reel(RecentContentSnapshot)
    case path(PathCourseSnapshot)

    var id: String {
        switch self {
        case let .reel(snapshot):
            return "reel:\(snapshot.id)"
        case let .path(snapshot):
            return "path:\(snapshot.id)"
        }
    }

    var updatedAt: Date {
        switch self {
        case let .reel(snapshot):
            return snapshot.updatedAt
        case let .path(snapshot):
            return snapshot.updatedAt
        }
    }

    var displayTopic: String {
        switch self {
        case let .reel(snapshot):
            return snapshot.displayTopic
        case let .path(snapshot):
            return snapshot.displayTopic
        }
    }

    /// Mode for this row (reel snapshots store mode; paths are always Path).
    var contentMode: ContentMode {
        switch self {
        case let .reel(snapshot):
            snapshot.mode
        case .path:
            .path
        }
    }

    /// Short UI label: "Learn", "Story", or "Path".
    var modeLabel: String {
        contentMode.tabLabel
    }

    /// SF Symbol name for this row’s mode (aligned with `contentMode`).
    var modeSystemImageName: String {
        contentMode.modeRowIconName
    }
}

enum HomeRecentFeed {
    /// Max rows shown on the home recent list (reels + paths combined).
    static let homeDisplayLimit = 10

    /// Merge, sort newest first, and cap for home.
    static func mergedItems(
        reels: [RecentContentSnapshot],
        courses: [PathCourseSnapshot],
        limit: Int = homeDisplayLimit
    ) -> [HomeRecentItem] {
        let reelItems = reels.map(HomeRecentItem.reel)
        let courseItems = courses.map(HomeRecentItem.path)
        let merged = (reelItems + courseItems).sorted { $0.updatedAt > $1.updatedAt }
        return Array(merged.prefix(limit))
    }
}
