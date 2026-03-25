import Foundation

struct PathLessonSummary: Codable, Identifiable, Hashable {
    let id: String
    let order: Int
    let title: String
    let summary: String
}
