import Foundation

struct PathLessonProgress: Codable, Identifiable {
    let lessonID: String
    var reels: [StoredReel]
    var quizQuestions: [QuizQuestion]
    var lastViewedReelID: String?
    var didReachQuiz: Bool
    var selectedAnswerIndices: [String: Int]
    var isQuizPassed: Bool
    var isCompleted: Bool
    var lastSubmissionPassed: Bool?

    var id: String {
        lessonID
    }

    var hydratedReels: [Reel] {
        reels.map(\.asReel)
    }

    var areAllQuestionsAnswered: Bool {
        !quizQuestions.isEmpty && quizQuestions.allSatisfy { selectedAnswerIndices[$0.id] != nil }
    }

    var firstUnansweredQuestionID: String? {
        quizQuestions.first(where: { selectedAnswerIndices[$0.id] == nil })?.id
    }

    func selectedAnswerIndex(for questionID: String) -> Int? {
        selectedAnswerIndices[questionID]
    }

    func isAnswerCorrect(for questionID: String) -> Bool? {
        guard
            let answerIndex = selectedAnswerIndices[questionID],
            let question = quizQuestions.first(where: { $0.id == questionID })
        else {
            return nil
        }

        return answerIndex == question.correctAnswerIndex
    }
}
