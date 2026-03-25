import Foundation

enum PathLessonAccessState: Equatable {
    case locked
    case unlocked
    case current
    case completed
}

struct PathCourseSnapshot: Codable, Identifiable {
    let topic: String
    let courseTitle: String
    var lessons: [PathLessonSummary]
    var currentLessonID: String?
    var unlockedLessonIDs: [String]
    var completedLessonIDs: [String]
    var lessonProgressByID: [String: PathLessonProgress]
    var updatedAt: Date

    var id: String {
        "path::\(normalizedTopicKey)"
    }

    var normalizedTopicKey: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var displayTopic: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
    }

    /// Every lesson in the map has been completed; user can extend with more lessons.
    var isEntirePathCompleted: Bool {
        !lessons.isEmpty && lessons.allSatisfy { completedLessonIDs.contains($0.id) }
    }

    var currentActionableLessonID: String? {
        if
            let currentLessonID,
            unlockedLessonIDs.contains(currentLessonID),
            !completedLessonIDs.contains(currentLessonID)
        {
            return currentLessonID
        }

        if let nextUnlocked = lessons.first(where: {
            unlockedLessonIDs.contains($0.id) && !completedLessonIDs.contains($0.id)
        }) {
            return nextUnlocked.id
        }

        return lessons.last?.id
    }

    func progress(for lessonID: String) -> PathLessonProgress? {
        lessonProgressByID[lessonID]
    }

    func nextLessonID(after lessonID: String) -> String? {
        guard let currentIndex = lessons.firstIndex(where: { $0.id == lessonID }) else { return nil }
        let nextIndex = lessons.index(after: currentIndex)
        guard lessons.indices.contains(nextIndex) else { return nil }
        return lessons[nextIndex].id
    }

    func accessState(for lessonID: String) -> PathLessonAccessState {
        if completedLessonIDs.contains(lessonID) {
            return .completed
        }

        if lessonID == currentActionableLessonID {
            return .current
        }

        if unlockedLessonIDs.contains(lessonID) {
            return .unlocked
        }

        return .locked
    }

    mutating func upsertLessonProgress(_ progress: PathLessonProgress) {
        lessonProgressByID[progress.lessonID] = progress
        updatedAt = .now
    }

    mutating func unlockFirstLessonIfNeeded() {
        guard unlockedLessonIDs.isEmpty, let firstLessonID = lessons.first?.id else { return }
        unlockedLessonIDs = [firstLessonID]
        currentLessonID = firstLessonID
    }

    mutating func markLessonPassed(_ lessonID: String) -> LessonCompletionResult {
        if !completedLessonIDs.contains(lessonID) {
            completedLessonIDs.append(lessonID)
        }

        let nextLessonID = nextLessonID(after: lessonID)
        if let nextLessonID, !unlockedLessonIDs.contains(nextLessonID) {
            unlockedLessonIDs.append(nextLessonID)
        }

        currentLessonID = nextLessonID ?? lessonID
        updatedAt = .now

        return LessonCompletionResult(
            passed: true,
            unlockedLessonID: nextLessonID,
            isCourseComplete: nextLessonID == nil
        )
    }
}
