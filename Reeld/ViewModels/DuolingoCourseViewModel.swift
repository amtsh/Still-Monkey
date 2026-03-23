import Foundation
import Observation

@Observable
@MainActor
final class DuolingoCourseViewModel {
    var topic: String = ""
    var course: DuolingoCourseSnapshot?
    var isLoading = false
    var error: String?
    var recentCourses: [DuolingoCourseSnapshot] = []
    var lastAccessedCourseID: String?

    private let service: any OpenRouterServing
    private let userDefaults: UserDefaults

    private static let recentCoursesKey = "duolingoRecentCourses"
    private static let lastAccessedCourseKey = "duolingoLastAccessedCourseID"

    init(
        service: any OpenRouterServing = OpenRouterService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
        recentCourses = loadRecentCourses()
        lastAccessedCourseID = userDefaults.string(forKey: Self.lastAccessedCourseKey)
    }

    var currentActionableLessonID: String? {
        course?.currentActionableLessonID
    }

    func startCourse(for topic: String, forceRefresh: Bool = false) async {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else { return }

        self.topic = trimmedTopic
        error = nil

        if !forceRefresh, let existing = recentCourses.first(where: { $0.normalizedTopicKey == trimmedTopic.lowercased() }) {
            loadRecentCourse(existing)
            return
        }

        let apiKey = userDefaults.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            course = nil
            error = "Add OpenRouter API key in Settings."
            return
        }

        isLoading = true
        course = nil

        do {
            let prompt = ContentPromptLibrary.duolingoCoursePrompt(topic: trimmedTopic)
            let content = try await fetchJSONWithRetry(
                prompt: prompt.userPrompt,
                systemPrompt: prompt.systemPrompt,
                apiKey: apiKey,
                maxTokens: 2000
            )
            let snapshot = try DuolingoPayloadParser.parseCourseSnapshot(from: content, topic: trimmedTopic)
            loadCourse(snapshot)
        } catch {
            self.error = "Could not build the lesson path. Try again."
        }

        isLoading = false
    }

    func refreshCurrentCourse() async {
        guard !topic.isEmpty else { return }
        await startCourse(for: topic, forceRefresh: true)
    }

    func loadRecentCourse(_ snapshot: DuolingoCourseSnapshot) {
        var updatedSnapshot = snapshot
        updatedSnapshot.updatedAt = .now
        topic = updatedSnapshot.topic
        error = nil
        saveCourse(updatedSnapshot)
    }

    func deleteRecentCourse(_ snapshot: DuolingoCourseSnapshot) {
        recentCourses.removeAll { $0.id == snapshot.id }

        if lastAccessedCourseID == snapshot.id {
            lastAccessedCourseID = nil
            userDefaults.removeObject(forKey: Self.lastAccessedCourseKey)
        }

        if course?.id == snapshot.id {
            course = nil
        }

        persistRecentCourses()
    }

    func accessState(for lesson: DuolingoLessonSummary) -> DuolingoLessonAccessState {
        course?.accessState(for: lesson.id) ?? .locked
    }

    func lessonProgress(for lessonID: String) -> DuolingoLessonProgress? {
        course?.progress(for: lessonID)
    }

    func lessonSummary(for lessonID: String) -> DuolingoLessonSummary? {
        course?.lessons.first(where: { $0.id == lessonID })
    }

    func nextLessonID(after lessonID: String) -> String? {
        course?.nextLessonID(after: lessonID)
    }

    func startOrRestoreLesson(lessonID: String) async throws -> DuolingoLessonProgress {
        guard var course else {
            throw DuolingoCourseError.missingCourse
        }

        guard course.accessState(for: lessonID) != .locked else {
            throw DuolingoCourseError.lessonLocked
        }

        if let existing = course.progress(for: lessonID), !existing.reels.isEmpty, !existing.quizQuestions.isEmpty {
            course.currentLessonID = lessonID
            saveCourse(course)
            return existing
        }

        let apiKey = userDefaults.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            throw DuolingoCourseError.missingAPIKey
        }

        guard let lesson = course.lessons.first(where: { $0.id == lessonID }) else {
            throw DuolingoCourseError.missingLesson
        }

        let completedTitles = course.lessons
            .filter { course.completedLessonIDs.contains($0.id) }
            .map(\.title)
        let prompt = ContentPromptLibrary.duolingoLessonPrompt(
            topic: course.topic,
            courseTitle: course.courseTitle,
            lesson: lesson,
            completedLessonTitles: completedTitles
        )

        let content = try await fetchJSONWithRetry(
            prompt: prompt.userPrompt,
            systemPrompt: prompt.systemPrompt,
            apiKey: apiKey,
            maxTokens: 3200
        )
        let progress = try DuolingoPayloadParser.parseLessonProgress(from: content, lesson: lesson)

        course.currentLessonID = lessonID
        course.upsertLessonProgress(progress)
        saveCourse(course)
        return progress
    }

    func recordProgressPosition(for lessonID: String, reelID: Reel.ID?, didReachQuiz: Bool) {
        guard var course, var progress = course.progress(for: lessonID) else { return }

        progress.lastViewedReelID = reelID?.uuidString
        progress.didReachQuiz = progress.didReachQuiz || didReachQuiz

        if didReachQuiz {
            progress.lastViewedReelID = nil
        }

        course.currentLessonID = lessonID
        course.upsertLessonProgress(progress)
        saveCourse(course)
    }

    func selectAnswer(_ answerIndex: Int, for questionID: String, lessonID: String) {
        guard var course, var progress = course.progress(for: lessonID) else { return }
        progress.selectedAnswerIndices[questionID] = answerIndex
        progress.lastSubmissionPassed = nil
        progress.didReachQuiz = true
        course.currentLessonID = lessonID
        course.upsertLessonProgress(progress)
        saveCourse(course)
    }

    func submitQuizAnswers(lessonID: String) -> LessonCompletionResult {
        guard var course, var progress = course.progress(for: lessonID) else {
            return LessonCompletionResult(passed: false, unlockedLessonID: nil, isCourseComplete: false)
        }

        guard progress.areAllQuestionsAnswered else {
            progress.lastSubmissionPassed = false
            progress.didReachQuiz = true
            course.upsertLessonProgress(progress)
            saveCourse(course)
            return LessonCompletionResult(passed: false, unlockedLessonID: nil, isCourseComplete: false)
        }

        let passed = progress.quizQuestions.allSatisfy {
            progress.selectedAnswerIndices[$0.id] == $0.correctAnswerIndex
        }

        progress.lastSubmissionPassed = passed
        progress.isQuizPassed = passed
        progress.isCompleted = passed
        progress.didReachQuiz = true
        course.upsertLessonProgress(progress)

        let result: LessonCompletionResult
        if passed {
            result = course.markLessonPassed(lessonID)
        } else {
            course.currentLessonID = lessonID
            result = LessonCompletionResult(passed: false, unlockedLessonID: nil, isCourseComplete: false)
        }

        saveCourse(course)
        return result
    }

    private func loadCourse(_ snapshot: DuolingoCourseSnapshot) {
        error = nil
        saveCourse(snapshot)
    }

    private func saveCourse(_ snapshot: DuolingoCourseSnapshot) {
        var updatedSnapshot = snapshot
        updatedSnapshot.updatedAt = .now

        var updatedCourses = recentCourses.filter { $0.id != updatedSnapshot.id }
        updatedCourses.insert(updatedSnapshot, at: 0)
        recentCourses = Array(updatedCourses.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(10))
        userDefaults.set(updatedSnapshot.id, forKey: Self.lastAccessedCourseKey)
        lastAccessedCourseID = updatedSnapshot.id
        course = updatedSnapshot
        persistRecentCourses()
    }

    private func loadRecentCourses() -> [DuolingoCourseSnapshot] {
        guard let data = userDefaults.data(forKey: Self.recentCoursesKey) else { return [] }

        do {
            let snapshots = try JSONDecoder().decode([DuolingoCourseSnapshot].self, from: data)
            return snapshots.sorted(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            return []
        }
    }

    private func persistRecentCourses() {
        guard let data = try? JSONEncoder().encode(recentCourses) else { return }
        userDefaults.set(data, forKey: Self.recentCoursesKey)
    }

    private func fetchJSONWithRetry(
        prompt: String,
        systemPrompt: String,
        apiKey: String,
        maxTokens: Int
    ) async throws -> String {
        var lastError: Error = DuolingoCourseError.invalidResponse

        for _ in 0 ..< 2 {
            do {
                return try await service.fetchJSON(
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    apiKey: apiKey,
                    maxTokens: maxTokens
                )
            } catch {
                lastError = error
            }
        }

        throw lastError
    }

    enum DuolingoCourseError: LocalizedError {
        case missingCourse
        case missingLesson
        case lessonLocked
        case missingAPIKey
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingCourse:
                return "No course is loaded."
            case .missingLesson:
                return "That lesson could not be found."
            case .lessonLocked:
                return "That lesson is still locked."
            case .missingAPIKey:
                return "Add OpenRouter API key in Settings."
            case .invalidResponse:
                return "The AI response could not be used."
            }
        }
    }
}
