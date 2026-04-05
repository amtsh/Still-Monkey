import Foundation

struct QuizQuestion: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctAnswerIndex: Int
    let explanation: String

    func isValidChoiceIndex(_ index: Int) -> Bool {
        choices.indices.contains(index)
    }
}
