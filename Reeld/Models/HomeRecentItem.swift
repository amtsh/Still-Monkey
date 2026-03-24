//
//  HomeRecentItem.swift
//  Reeld
//

import Foundation

/// Unified recent row for reels and Duolingo courses. IDs are prefixed to avoid collisions.
enum HomeRecentItem: Identifiable {
    case reel(RecentContentSnapshot)
    case duolingo(DuolingoCourseSnapshot)

    var id: String {
        switch self {
        case let .reel(snapshot):
            return "reel:\(snapshot.id)"
        case let .duolingo(snapshot):
            return "duolingo:\(snapshot.id)"
        }
    }

    var updatedAt: Date {
        switch self {
        case let .reel(snapshot):
            return snapshot.updatedAt
        case let .duolingo(snapshot):
            return snapshot.updatedAt
        }
    }

    var displayTopic: String {
        switch self {
        case let .reel(snapshot):
            return snapshot.displayTopic
        case let .duolingo(snapshot):
            return snapshot.displayTopic
        }
    }

    var iconName: String {
        switch self {
        case let .reel(snapshot):
            return snapshot.mode == .story ? "moon.zzz" : "book"
        case .duolingo:
            return "point.3.connected.trianglepath.dotted"
        }
    }
}

enum HomeRecentFeed {
    /// Merge and sort once (newest first).
    static func mergedItems(
        reels: [RecentContentSnapshot],
        courses: [DuolingoCourseSnapshot]
    ) -> [HomeRecentItem] {
        let reelItems = reels.map(HomeRecentItem.reel)
        let courseItems = courses.map(HomeRecentItem.duolingo)
        return (reelItems + courseItems).sorted { $0.updatedAt > $1.updatedAt }
    }

    struct Buckets {
        let today: [HomeRecentItem]
        let yesterday: [HomeRecentItem]
        let earlier: [HomeRecentItem]

        /// Single pass over sorted items — O(n).
        static func partition(_ items: [HomeRecentItem]) -> Buckets {
            let calendar = Calendar.current
            var today: [HomeRecentItem] = []
            var yesterday: [HomeRecentItem] = []
            var earlier: [HomeRecentItem] = []
            today.reserveCapacity(items.count)
            for item in items {
                if calendar.isDateInToday(item.updatedAt) {
                    today.append(item)
                } else if calendar.isDateInYesterday(item.updatedAt) {
                    yesterday.append(item)
                } else {
                    earlier.append(item)
                }
            }
            return Buckets(today: today, yesterday: yesterday, earlier: earlier)
        }
    }
}
