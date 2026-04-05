import Foundation

struct LessonCompletionResult: Equatable {
    let passed: Bool
    let unlockedLessonID: String?
    let isCourseComplete: Bool
}
