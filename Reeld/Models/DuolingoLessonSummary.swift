import Foundation

struct DuolingoLessonSummary: Codable, Identifiable, Hashable {
    let id: String
    let order: Int
    let title: String
    let summary: String
}
