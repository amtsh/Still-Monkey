//
//  BookmarkEntry.swift
//  Still Monkey
//

import Foundation

/// Self-contained bookmark so content can reopen after recent/path deletion.
struct BookmarkEntry: Identifiable, Codable, Equatable {
    var id: UUID
    /// Deterministic key for add/remove toggle (same page replaces previous bookmark).
    var stableKey: String
    var addedAt: Date
    var displayTitle: String
    var displaySubtitle: String
    var payload: BookmarkPayload

    init(
        id: UUID = UUID(),
        stableKey: String,
        addedAt: Date = .now,
        displayTitle: String,
        displaySubtitle: String,
        payload: BookmarkPayload
    ) {
        self.id = id
        self.stableKey = stableKey
        self.addedAt = addedAt
        self.displayTitle = displayTitle
        self.displaySubtitle = displaySubtitle
        self.payload = payload
    }
}

enum BookmarkPayload: Codable, Equatable {
    case feedReel(FeedReelBookmarkPayload)
    case feedLearnEnd(FeedLearnEndBookmarkPayload)
    case pathReel(PathReelBookmarkPayload)
    case pathQuiz(PathQuizBookmarkPayload)
    case pathResult(PathResultBookmarkPayload)
}

// MARK: - Payloads (fields needed to render `BookmarkedContentView`)

struct FeedReelBookmarkPayload: Codable, Equatable {
    var contentMode: ContentMode
    /// Topic line for `ReelCardView` (capitalized display string).
    var topicTitle: String
    var storedReel: StoredReel
    var chapterTitle: String?
}

struct FeedLearnEndBookmarkPayload: Codable, Equatable {
    var contentMode: ContentMode
    var topicTitleDisplay: String
}

struct PathReelBookmarkPayload: Codable, Equatable {
    var storedReel: StoredReel
    var chapterTitle: String?
    /// Course topic line for `ReelCardView`.
    var topicTitle: String
}

struct PathQuizBookmarkPayload: Codable, Equatable {
    var question: QuizQuestion
    var topicTitle: String
    var lessonTitle: String
}

struct PathResultBookmarkPayload: Codable, Equatable {
    var passed: Bool
    var unlockedLessonID: String?
    var isCourseComplete: Bool
}

enum BookmarkStableKey {
    static func feedReel(mode: ContentMode, topic: String, reelID: UUID) -> String {
        "feed-\(mode.rawValue)-\(normalizedTopic(topic))-reel-\(reelID.uuidString)"
    }

    static func pathReel(lessonID: String, reelID: UUID) -> String {
        "path-\(lessonID)-reel-\(reelID.uuidString)"
    }

    private static func normalizedTopic(_ topic: String) -> String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
