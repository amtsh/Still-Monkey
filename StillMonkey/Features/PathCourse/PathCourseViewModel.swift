import Foundation
import Observation

@Observable
@MainActor
final class PathCourseViewModel {
    var topic: String = ""
    var course: PathCourseSnapshot?
    var isLoading = false
    var error: String?
    var recentCourses: [PathCourseSnapshot] = []
    var lastAccessedCourseID: String?

    private let service: any OpenRouterServing
    private let userDefaults: UserDefaults
    private var persistRecentCoursesTask: Task<Void, Never>?

    private static let recentCoursesKey = "pathRecentCourses"
    private static let lastAccessedCourseKey = "pathLastAccessedCourseID"

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

    /// True when every lesson on the map is completed; user can generate a deeper segment.
    var isPathFullyCompleted: Bool {
        course?.isEntirePathCompleted ?? false
    }

    /// Clears a stale error and drops the loaded map when switching topics so the UI does not flash the previous failure
    /// (or wrong course) before `startCourse` runs on the next run loop.
    func prepareForPathRequest(topic raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        error = nil
        topic = trimmed
        if let c = course, c.normalizedTopicKey != trimmed.lowercased() {
            course = nil
        }
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
            let prompt = ContentPromptLibrary.pathCoursePrompt(topic: trimmedTopic)
            let content = try await service.fetchJSONWithRetry(
                prompt: prompt.userPrompt,
                systemPrompt: prompt.systemPrompt,
                apiKey: apiKey,
                maxTokens: 2000
            )
            let snapshot = try await Task.detached(priority: .userInitiated) {
                try PathPayloadParser.parseCourseSnapshot(from: content, topic: trimmedTopic)
            }.value
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

    /// Appends new lessons after the learner finished the whole path; unlocks the first new lesson.
    func extendPathWithMoreLessons() async {
        guard var course, course.isEntirePathCompleted else { return }

        let apiKey = userDefaults.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            error = "Add OpenRouter API key in Settings."
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let existingIDs = Set(course.lessons.map(\.id))
        let maxOrder = course.lessons.map(\.order).max() ?? 0

        let completedLines: [String] = course.lessons
            .filter { course.completedLessonIDs.contains($0.id) }
            .sorted(by: { $0.order < $1.order })
            .map { "\($0.order). \($0.title) — \($0.summary)" }

        do {
            let prompt = ContentPromptLibrary.pathExtendCoursePrompt(
                topic: course.topic,
                courseTitle: course.courseTitle,
                completedLessonLines: completedLines,
                existingLessonIDs: Array(existingIDs)
            )
            let content = try await service.fetchJSONWithRetry(
                prompt: prompt.userPrompt,
                systemPrompt: prompt.systemPrompt,
                apiKey: apiKey,
                maxTokens: 2200
            )
            let newLessons = try await Task.detached(priority: .userInitiated) {
                try PathPayloadParser.parseAdditionalLessons(
                    from: content,
                    startingOrder: maxOrder,
                    existingLessonIDs: existingIDs
                )
            }.value

            course.lessons.append(contentsOf: newLessons)
            course.lessons.sort { $0.order < $1.order }

            if let firstNew = newLessons.first {
                if !course.unlockedLessonIDs.contains(firstNew.id) {
                    course.unlockedLessonIDs.append(firstNew.id)
                }
                course.currentLessonID = firstNew.id
            }

            course.updatedAt = .now
            saveCourse(course)
        } catch {
            self.error = "Could not add more lessons. Try again."
        }
    }

    func loadRecentCourse(_ snapshot: PathCourseSnapshot) {
        var updatedSnapshot = snapshot
        updatedSnapshot.updatedAt = .now
        topic = updatedSnapshot.topic
        error = nil
        saveCourse(updatedSnapshot)
    }

    func deleteRecentCourse(_ snapshot: PathCourseSnapshot) {
        recentCourses.removeAll { $0.id == snapshot.id }

        if lastAccessedCourseID == snapshot.id {
            lastAccessedCourseID = nil
            userDefaults.removeObject(forKey: Self.lastAccessedCourseKey)
        }

        if course?.id == snapshot.id {
            course = nil
        }

        persistRecentCoursesImmediate()
    }

    func accessState(for lesson: PathLessonSummary) -> PathLessonAccessState {
        course?.accessState(for: lesson.id) ?? .locked
    }

    /// Adds a locked lesson to `unlockedLessonIDs` so `startOrRestoreLesson` can run (premium path).
    func unlockLessonForPremiumMember(_ lessonID: String) {
        guard var course else { return }
        guard course.lessons.contains(where: { $0.id == lessonID }) else { return }
        guard !course.completedLessonIDs.contains(lessonID) else { return }
        if !course.unlockedLessonIDs.contains(lessonID) {
            course.unlockedLessonIDs.append(lessonID)
        }
        course.currentLessonID = lessonID
        saveCourse(course)
    }

    func lessonProgress(for lessonID: String) -> PathLessonProgress? {
        course?.progress(for: lessonID)
    }

    func lessonSummary(for lessonID: String) -> PathLessonSummary? {
        course?.lessons.first(where: { $0.id == lessonID })
    }

    func nextLessonID(after lessonID: String) -> String? {
        course?.nextLessonID(after: lessonID)
    }

    /// Drops cached lesson content and fetches fresh reels + quiz from the model (same as first open).
    func reloadLessonContent(lessonID: String) async throws -> PathLessonProgress {
        guard var course else {
            throw PathCourseError.missingCourse
        }

        guard course.accessState(for: lessonID) != .locked else {
            throw PathCourseError.lessonLocked
        }

        course.removeLessonProgress(for: lessonID)
        saveCourse(course)
        return try await startOrRestoreLesson(lessonID: lessonID)
    }

    func startOrRestoreLesson(lessonID: String) async throws -> PathLessonProgress {
        guard var course else {
            throw PathCourseError.missingCourse
        }

        guard course.accessState(for: lessonID) != .locked else {
            throw PathCourseError.lessonLocked
        }

        if let existing = course.progress(for: lessonID), !existing.reels.isEmpty, !existing.quizQuestions.isEmpty {
            course.currentLessonID = lessonID
            saveCourse(course)
            return existing
        }

        let apiKey = userDefaults.string(forKey: Config.apiKeyUserDefaultsKey) ?? ""
        guard !apiKey.isEmpty else {
            throw PathCourseError.missingAPIKey
        }

        guard let lesson = course.lessons.first(where: { $0.id == lessonID }) else {
            throw PathCourseError.missingLesson
        }

        let completedTitles = course.lessons
            .filter { course.completedLessonIDs.contains($0.id) }
            .map(\.title)
        let prompt = ContentPromptLibrary.pathLessonPrompt(
            topic: course.topic,
            courseTitle: course.courseTitle,
            lesson: lesson,
            completedLessonTitles: completedTitles
        )

        let content = try await service.fetchJSONWithRetry(
            prompt: prompt.userPrompt,
            systemPrompt: prompt.systemPrompt,
            apiKey: apiKey,
            maxTokens: 3200
        )
        let progress = try await Task.detached(priority: .userInitiated) {
            try PathPayloadParser.parseLessonProgress(from: content, lesson: lesson)
        }.value

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

    private func loadCourse(_ snapshot: PathCourseSnapshot) {
        error = nil
        saveCourse(snapshot)
    }

    private func saveCourse(_ snapshot: PathCourseSnapshot) {
        var updatedSnapshot = snapshot
        updatedSnapshot.updatedAt = .now

        var updatedCourses = recentCourses.filter { $0.id != updatedSnapshot.id }
        updatedCourses.insert(updatedSnapshot, at: 0)
        recentCourses = Array(updatedCourses.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(10))
        userDefaults.set(updatedSnapshot.id, forKey: Self.lastAccessedCourseKey)
        lastAccessedCourseID = updatedSnapshot.id
        course = updatedSnapshot
        schedulePersistRecentCourses()
    }

    private func loadRecentCourses() -> [PathCourseSnapshot] {
        guard let data = userDefaults.data(forKey: Self.recentCoursesKey) else { return [] }

        do {
            let snapshots = try JSONDecoder().decode([PathCourseSnapshot].self, from: data)
            return snapshots.sorted(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            return []
        }
    }

    private func schedulePersistRecentCourses() {
        persistRecentCoursesTask?.cancel()
        persistRecentCoursesTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            persistRecentCoursesImmediate()
        }
    }

    private func persistRecentCoursesImmediate() {
        guard let data = try? JSONEncoder().encode(recentCourses) else { return }
        userDefaults.set(data, forKey: Self.recentCoursesKey)
    }

    enum PathCourseError: LocalizedError {
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
