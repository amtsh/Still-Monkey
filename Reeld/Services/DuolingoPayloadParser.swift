import Foundation

enum DuolingoPayloadParser {
    private enum ParserError: LocalizedError {
        case invalidJSON
        case invalidCourse
        case invalidLesson

        var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "The lesson response was not valid JSON."
            case .invalidCourse:
                return "The course map response was missing required lesson data."
            case .invalidLesson:
                return "The lesson content response was incomplete."
            }
        }
    }

    private struct CoursePayload: Decodable {
        let courseTitle: String
        let lessons: [CourseLessonPayload]
    }

    private struct CourseLessonPayload: Decodable {
        let id: String?
        let title: String
        let summary: String
    }

    private struct LessonPayload: Decodable {
        let lessonTitle: String?
        let summary: String?
        let chapters: [ChapterPayload]
        let quiz: [QuizPayload]
    }

    private struct ChapterPayload: Decodable {
        let title: String
        let cards: [String]
    }

    private struct QuizPayload: Decodable {
        let id: String?
        let prompt: String
        let choices: [String]
        let correctAnswerIndex: Int
        let explanation: String
    }

    static func parseCourseSnapshot(from content: String, topic: String) throws -> DuolingoCourseSnapshot {
        let payload = try decode(CoursePayload.self, from: content)
        let lessons = payload.lessons
            .prefix(8)
            .enumerated()
            .compactMap { offset, lesson -> DuolingoLessonSummary? in
                let trimmedTitle = lesson.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedSummary = lesson.summary.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty, !trimmedSummary.isEmpty else { return nil }

                let idSource = lesson.id?.trimmingCharacters(in: .whitespacesAndNewlines)
                let lessonID = sanitizeID(idSource?.isEmpty == false ? idSource! : trimmedTitle)

                return DuolingoLessonSummary(
                    id: lessonID.isEmpty ? "lesson-\(offset + 1)" : lessonID,
                    order: offset + 1,
                    title: trimmedTitle,
                    summary: trimmedSummary
                )
            }

        guard lessons.count >= 4 else {
            throw ParserError.invalidCourse
        }

        var uniqueLessons: [DuolingoLessonSummary] = []
        var seenIDs = Set<String>()
        for lesson in lessons {
            guard seenIDs.insert(lesson.id).inserted else { continue }
            uniqueLessons.append(lesson)
        }

        guard uniqueLessons.count >= 4 else {
            throw ParserError.invalidCourse
        }

        var snapshot = DuolingoCourseSnapshot(
            topic: topic.trimmingCharacters(in: .whitespacesAndNewlines),
            courseTitle: payload.courseTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? topic.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
                : payload.courseTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            lessons: uniqueLessons,
            currentLessonID: nil,
            unlockedLessonIDs: [],
            completedLessonIDs: [],
            lessonProgressByID: [:],
            updatedAt: .now
        )
        snapshot.unlockFirstLessonIfNeeded()
        return snapshot
    }

    static func parseLessonProgress(
        from content: String,
        lesson: DuolingoLessonSummary
    ) throws -> DuolingoLessonProgress {
        let payload = try decode(LessonPayload.self, from: content)

        var reels: [Reel] = []
        for (index, chapter) in payload.chapters.enumerated() {
            let trimmedTitle = chapter.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let cards = chapter.cards
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(4)

            guard !trimmedTitle.isEmpty, !cards.isEmpty else { continue }

            let chapterIndex = index + 1
            reels.append(Reel(content: .chapterTitle(index: chapterIndex, title: trimmedTitle)))
            reels.append(contentsOf: cards.map { Reel(content: .content(chapterIndex: chapterIndex, text: $0)) })
        }

        let quizQuestions = payload.quiz
            .prefix(4)
            .compactMap { question -> QuizQuestion? in
                let prompt = question.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                let explanation = question.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
                let choices = question.choices
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                guard
                    !prompt.isEmpty,
                    !explanation.isEmpty,
                    (2 ... 4).contains(choices.count),
                    choices.indices.contains(question.correctAnswerIndex)
                else {
                    return nil
                }

                let rawID = question.id?.trimmingCharacters(in: .whitespacesAndNewlines)
                let questionID = sanitizeID(rawID?.isEmpty == false ? rawID! : prompt)

                return QuizQuestion(
                    id: questionID.isEmpty ? UUID().uuidString : questionID,
                    prompt: prompt,
                    choices: choices,
                    correctAnswerIndex: question.correctAnswerIndex,
                    explanation: explanation
                )
            }

        guard !reels.isEmpty, quizQuestions.count >= 2 else {
            throw ParserError.invalidLesson
        }

        return DuolingoLessonProgress(
            lessonID: lesson.id,
            reels: reels.map(StoredReel.init(from:)),
            quizQuestions: quizQuestions,
            lastViewedReelID: nil,
            didReachQuiz: false,
            selectedAnswerIndices: [:],
            isQuizPassed: false,
            isCompleted: false,
            lastSubmissionPassed: nil
        )
    }

    private static func decode<T: Decodable>(_ type: T.Type, from content: String) throws -> T {
        let json = extractJSONObject(from: content)
        guard let data = json.data(using: .utf8) else {
            throw ParserError.invalidJSON
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ParserError.invalidJSON
        }
    }

    private static func extractJSONObject(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let start = trimmed.firstIndex(of: "{"),
            let end = trimmed.lastIndex(of: "}")
        else {
            return trimmed
        }

        return String(trimmed[start ... end])
    }

    private static func sanitizeID(_ value: String) -> String {
        let lowered = value.lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            if allowed.contains(scalar) {
                return Character(scalar)
            }
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                return "-"
            }
            return "-"
        }

        let collapsed = String(scalars)
            .replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return collapsed
    }
}
