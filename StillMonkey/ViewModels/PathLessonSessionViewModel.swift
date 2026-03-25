import Foundation
import Observation

@Observable
@MainActor
final class PathLessonSessionViewModel {
    enum PageID: Hashable {
        case reel(UUID)
        case quiz(String)
        case result
    }

    let lessonID: String

    var isLoading = false
    var error: String?
    private(set) var latestResult: LessonCompletionResult?

    private let courseViewModel: PathCourseViewModel
    private var hasLoaded = false

    init(courseViewModel: PathCourseViewModel, lessonID: String) {
        self.courseViewModel = courseViewModel
        self.lessonID = lessonID
    }

    var lesson: PathLessonSummary? {
        courseViewModel.lessonSummary(for: lessonID)
    }

    var topicTitle: String {
        courseViewModel.course?.displayTopic ?? ""
    }

    var reels: [Reel] {
        progress?.hydratedReels ?? []
    }

    var quizQuestions: [QuizQuestion] {
        progress?.quizQuestions ?? []
    }

    var chapterTitlesByIndex: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: reels.compactMap { reel in
                guard case let .chapterTitle(index, title) = reel.content else { return nil }
                return (index, title)
            }
        )
    }

    var pages: [PageID] {
        var pageIDs = reels.map { PageID.reel($0.id) }
        pageIDs.append(contentsOf: quizQuestions.map { PageID.quiz($0.id) })
        pageIDs.append(.result)
        return pageIDs
    }

    var progress: PathLessonProgress? {
        courseViewModel.lessonProgress(for: lessonID)
    }

    var canSubmitQuiz: Bool {
        progress?.areAllQuestionsAnswered ?? false
    }

    var didPassQuiz: Bool {
        progress?.lastSubmissionPassed == true
    }

    var hasQuizAttempt: Bool {
        progress?.lastSubmissionPassed != nil
    }

    var nextLessonID: String? {
        courseViewModel.nextLessonID(after: lessonID)
    }

    var firstContentPageID: PageID? {
        reels.first.map { .reel($0.id) }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true
        error = nil

        do {
            _ = try await courseViewModel.startOrRestoreLesson(lessonID: lessonID)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Regenerates lesson reels + quiz from the model (navbar reload on first slide).
    func reloadLessonContent() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            _ = try await courseViewModel.reloadLessonContent(lessonID: lessonID)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func initialPageID() -> PageID? {
        guard let progress else { return pages.first }

        if progress.isCompleted || progress.lastSubmissionPassed == true {
            return .result
        }

        if progress.didReachQuiz, let questionID = resumeQuestionID(from: progress) {
            return .quiz(questionID)
        }

        if
            let rawID = progress.lastViewedReelID,
            let reelID = UUID(uuidString: rawID),
            reels.contains(where: { $0.id == reelID })
        {
            return .reel(reelID)
        }

        return pages.first
    }

    func reel(for pageID: PageID) -> Reel? {
        guard case .reel(let reelID) = pageID else { return nil }
        return reels.first(where: { $0.id == reelID })
    }

    func question(for pageID: PageID) -> QuizQuestion? {
        guard case .quiz(let questionID) = pageID else { return nil }
        return quizQuestions.first(where: { $0.id == questionID })
    }

    func selectedAnswerIndex(for question: QuizQuestion) -> Int? {
        progress?.selectedAnswerIndex(for: question.id)
    }

    func selectAnswer(_ answerIndex: Int, for question: QuizQuestion) {
        guard question.isValidChoiceIndex(answerIndex) else { return }
        courseViewModel.selectAnswer(answerIndex, for: question.id, lessonID: lessonID)
        if progress?.areAllQuestionsAnswered == true {
            latestResult = courseViewModel.submitQuizAnswers(lessonID: lessonID)
        } else {
            latestResult = nil
        }
    }

    func choiceIsCorrect(_ choiceIndex: Int, for question: QuizQuestion) -> Bool {
        question.correctAnswerIndex == choiceIndex
    }

    func shouldRevealAnswer(for question: QuizQuestion) -> Bool {
        return progress?.selectedAnswerIndices[question.id] != nil
    }

    func recordVisiblePage(_ pageID: PageID?) {
        guard let pageID else { return }

        switch pageID {
        case .reel(let reelID):
            courseViewModel.recordProgressPosition(for: lessonID, reelID: reelID, didReachQuiz: false)
        case .quiz, .result:
            courseViewModel.recordProgressPosition(for: lessonID, reelID: nil, didReachQuiz: true)
        }
    }

    func submitQuiz() {
        latestResult = courseViewModel.submitQuizAnswers(lessonID: lessonID)
    }

    private func resumeQuestionID(from progress: PathLessonProgress) -> String? {
        if let firstUnanswered = progress.firstUnansweredQuestionID {
            return firstUnanswered
        }

        if let firstIncorrect = progress.quizQuestions.first(where: {
            progress.selectedAnswerIndices[$0.id] != $0.correctAnswerIndex
        }) {
            return firstIncorrect.id
        }

        return progress.quizQuestions.first?.id
    }
}
