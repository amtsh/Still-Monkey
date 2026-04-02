import Foundation

enum PathPayloadParser {
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

    private struct ExtendLessonsPayload: Decodable {
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

    static func parseCourseSnapshot(from content: String, topic: String) throws -> PathCourseSnapshot {
        let payload = try decode(CoursePayload.self, from: content)
        let lessons = payload.lessons
            .prefix(8)
            .enumerated()
            .compactMap { offset, lesson -> PathLessonSummary? in
                let trimmedTitle = lesson.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedSummary = lesson.summary.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty, !trimmedSummary.isEmpty else { return nil }

                let idSource = lesson.id?.trimmingCharacters(in: .whitespacesAndNewlines)
                let lessonID = sanitizeID(idSource?.isEmpty == false ? idSource! : trimmedTitle)

                return PathLessonSummary(
                    id: lessonID.isEmpty ? "lesson-\(offset + 1)" : lessonID,
                    order: offset + 1,
                    title: trimmedTitle,
                    summary: trimmedSummary
                )
            }

        guard lessons.count >= 4 else {
            throw ParserError.invalidCourse
        }

        var uniqueLessons: [PathLessonSummary] = []
        var seenIDs = Set<String>()
        for lesson in lessons {
            guard seenIDs.insert(lesson.id).inserted else { continue }
            uniqueLessons.append(lesson)
        }

        guard uniqueLessons.count >= 4 else {
            throw ParserError.invalidCourse
        }

        var snapshot = PathCourseSnapshot(
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

    /// Parses additional lessons for an existing course; assigns sequential `order` from `startingOrder`.
    static func parseAdditionalLessons(
        from content: String,
        startingOrder: Int,
        existingLessonIDs: Set<String>
    ) throws -> [PathLessonSummary] {
        let payload = try decode(ExtendLessonsPayload.self, from: content)

        var uniqueLessons: [PathLessonSummary] = []
        var seenIDs = Set<String>()

        for lesson in payload.lessons.prefix(8) {
            let trimmedTitle = lesson.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSummary = lesson.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty, !trimmedSummary.isEmpty else { continue }

            let idSource = lesson.id?.trimmingCharacters(in: .whitespacesAndNewlines)
            var baseID = sanitizeID((idSource?.isEmpty == false) ? idSource! : trimmedTitle)
            if baseID.isEmpty {
                baseID = "lesson-ext-\(startingOrder + uniqueLessons.count + 1)"
            }

            var uniqueID = baseID
            var n = 0
            while seenIDs.contains(uniqueID) || existingLessonIDs.contains(uniqueID) {
                n += 1
                uniqueID = "\(baseID)-\(n)"
            }
            seenIDs.insert(uniqueID)

            let order = startingOrder + uniqueLessons.count + 1
            uniqueLessons.append(
                PathLessonSummary(
                    id: uniqueID,
                    order: order,
                    title: trimmedTitle,
                    summary: trimmedSummary
                )
            )
        }

        guard uniqueLessons.count >= 3 else {
            throw ParserError.invalidCourse
        }

        return uniqueLessons
    }

    static func parseLessonProgress(
        from content: String,
        lesson: PathLessonSummary
    ) throws -> PathLessonProgress {
        let payload = try decode(LessonPayload.self, from: content)

        var reels: [Reel] = []
        for (index, chapter) in payload.chapters.enumerated() {
            let trimmedTitle = chapter.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let cards = normalizedCards(from: chapter.cards).prefix(4)

            guard !trimmedTitle.isEmpty, !cards.isEmpty else { continue }

            let chapterIndex = index + 1
            reels.append(Reel(content: .chapterTitle(index: chapterIndex, title: trimmedTitle)))
            reels.append(contentsOf: cards.map { Reel(content: .content(chapterIndex: chapterIndex, text: $0)) })
        }

        var quizQuestions: [QuizQuestion] = []
        var seenQuizIDs = Set<String>()
        for question in payload.quiz.prefix(4) {
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
                continue
            }

            let rawID = question.id?.trimmingCharacters(in: .whitespacesAndNewlines)
            let sanitized = sanitizeID(rawID?.isEmpty == false ? rawID! : prompt)
            var baseID = sanitized.isEmpty ? UUID().uuidString : sanitized
            var uniqueID = baseID
            var n = 0
            while seenQuizIDs.contains(uniqueID) {
                n += 1
                uniqueID = "\(baseID)-\(n)"
            }
            seenQuizIDs.insert(uniqueID)

            quizQuestions.append(
                QuizQuestion(
                    id: uniqueID,
                    prompt: prompt,
                    choices: choices,
                    correctAnswerIndex: question.correctAnswerIndex,
                    explanation: explanation
                )
            )
        }

        guard !reels.isEmpty, quizQuestions.count >= 2 else {
            throw ParserError.invalidLesson
        }

        return PathLessonProgress(
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
        let json = JSONExtraction.extractFirstJSONObject(from: content)
        guard let data = json.data(using: .utf8) else {
            throw ParserError.invalidJSON
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            let snakeDecoder: JSONDecoder = {
              let d = JSONDecoder()
                d.keyDecodingStrategy = .convertFromSnakeCase
                return d
            }()
            do {
                return try snakeDecoder.decode(type, from: data)
            } catch {
                throw ParserError.invalidJSON
            }
        }
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

    private static func normalizedCards(from cards: [String]) -> [String] {
        let sentences = cards
            .flatMap(sentenceChunks(from:))
            .filter { !$0.isEmpty }

        guard !sentences.isEmpty else { return [] }

        var groupedCards: [String] = []
        var currentChunk: [String] = []

        for sentence in sentences {
            currentChunk.append(sentence)
            if currentChunk.count == 3 {
                groupedCards.append(currentChunk.joined(separator: " "))
                currentChunk.removeAll()
            }
        }

        if !currentChunk.isEmpty {
            if groupedCards.isEmpty {
                groupedCards.append(currentChunk.joined(separator: " "))
            } else {
                groupedCards[groupedCards.count - 1] += " " + currentChunk.joined(separator: " ")
            }
        }

        return groupedCards
    }

    private static func sentenceChunks(from value: String) -> [String] {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let pattern = "(?<=[.!?])\\s+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [trimmed] }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        let separated = regex.stringByReplacingMatches(in: trimmed, range: range, withTemplate: "\n")

        return separated
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
