import Foundation
import Testing
@testable import StillMonkey

struct StillMonkeyTests {
    @Test func jsonExtractionDoesNotTruncateWhenBraceAppearsInsideString() throws {
        let raw = """
        Preamble
        {"courseTitle": "C", "lessons": [
          {"id": "l1", "title": "A", "summary": "s1"},
          {"id": "l2", "title": "B", "summary": "s2"},
          {"id": "l3", "title": "C", "summary": "s3"},
          {"id": "l4", "title": "D", "summary": "Uses } in a sentence"}
        ]}
        """
        let extracted = JSONExtraction.extractFirstJSONObject(from: raw)
        let snapshot = try PathPayloadParser.parseCourseSnapshot(from: extracted, topic: "T")
        #expect(snapshot.lessons.contains { $0.summary.contains("}") })
    }

    @Test func parserCreatesChapterAndContentReelsFromValidLines() {
        var parser = ReelContentParser()
        let input = [
            "CHAPTER: Intro to Quantum Computing",
            "- Qubits can represent superposition states unlike binary bits. This enables richer state encoding and potentially more efficient problem-solving for specific algorithms.",
            "- Measurement collapses state probabilities into a classical outcome."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 3)
        assertChapter(reels[0], index: 1, title: "Intro to Quantum Computing")
        assertContent(
            reels[1],
            chapterIndex: 1,
            textContains: "Qubits can represent superposition states"
        )
        assertContent(
            reels[2],
            chapterIndex: 1,
            textContains: "Measurement collapses state probabilities"
        )
    }

    @Test func parserSupportsMultipleBulletPrefixes() {
        var parser = ReelContentParser()
        let input = [
            "CHAPTER: Networking Basics",
            "* TCP ensures ordered delivery by tracking sequence numbers and retransmissions when packets are lost.",
            "• UDP favors low latency over reliability, useful for streaming and real-time communication.",
            "1. HTTP defines a request-response protocol for transferring web resources across clients and servers.",
            "2) TLS adds encryption and authentication to protect data in transit."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 5)
        for reel in reels.dropFirst() {
            assertContent(reel, chapterIndex: 1, textContains: "")
        }
    }

    @Test func parserSupportsChapterHeadingVariants() {
        var parser = ReelContentParser()
        let input = [
            "### Chapter 1: Compiler Design",
            "– Lexing converts source code into a stream of tokens for parsing.",
            "CHAPTER 2 - Parsing",
            "— Parsing builds a syntax tree from tokens to represent program structure."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 4)
        assertChapter(reels[0], index: 1, title: "Compiler Design")
        assertContent(reels[1], chapterIndex: 1, textContains: "Lexing converts source code")
        assertChapter(reels[2], index: 2, title: "Parsing")
        assertContent(reels[3], chapterIndex: 2, textContains: "Parsing builds a syntax tree")
    }

    @Test func parserIgnoresBulletsBeforeFirstChapter() {
        var parser = ReelContentParser()
        let input = [
            "- This should be ignored because no chapter exists yet.",
            "CHAPTER: First Real Chapter",
            "- This should be included."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 2)
        assertChapter(reels[0], index: 1, title: "First Real Chapter")
        assertContent(reels[1], chapterIndex: 1, textContains: "This should be included")
    }

    @Test func parserIncrementsChapterIndexAcrossChapters() {
        var parser = ReelContentParser()
        let input = [
            "CHAPTER: Foundations",
            "- A first bullet for chapter one.",
            "CHAPTER: Advanced Concepts",
            "- A first bullet for chapter two."
        ]

        let reels = input.compactMap { parser.parseLine($0) }

        #expect(reels.count == 4)
        assertChapter(reels[0], index: 1, title: "Foundations")
        assertContent(reels[1], chapterIndex: 1, textContains: "chapter one")
        assertChapter(reels[2], index: 2, title: "Advanced Concepts")
        assertContent(reels[3], chapterIndex: 2, textContains: "chapter two")
    }

    @Test func parserResetClearsChapterState() {
        var parser = ReelContentParser()
        _ = parser.parseLine("CHAPTER: Temporary")
        parser.reset()
        let reel = parser.parseLine("CHAPTER: Fresh Start")

        #expect(reel != nil)
        if let reel {
            assertChapter(reel, index: 1, title: "Fresh Start")
        }
    }

    @Test func learnPromptContainsCriticalFormattingRules() {
        let prompt = ContentPromptLibrary.prompt(for: .learn, topic: "Quantum Mechanics")

        #expect(prompt != nil)
        #expect(prompt?.systemPrompt.contains("exactly 10 bullet points") == true)
        #expect(prompt?.systemPrompt.contains("Every bullet must be on its own line and start with \"- \"") == true)
        #expect(prompt?.systemPrompt.contains("Do not include any text outside this format.") == true)
    }

    @Test func pathCourseParserUnlocksFirstLessonAndClampsToEightLessons() throws {
        let snapshot = try PathPayloadParser.parseCourseSnapshot(
            from: """
            {
              "courseTitle": "Quantum Basics",
              "lessons": [
                {"id": "lesson-1", "title": "Atoms", "summary": "Start with the building blocks."},
                {"id": "lesson-2", "title": "Waves", "summary": "See how particles behave like waves."},
                {"id": "lesson-3", "title": "Measurement", "summary": "Learn what observation changes."},
                {"id": "lesson-4", "title": "Superposition", "summary": "Understand how states can overlap."},
                {"id": "lesson-5", "title": "Entanglement", "summary": "Follow spooky linked states."},
                {"id": "lesson-6", "title": "Tunneling", "summary": "Watch particles cross barriers."},
                {"id": "lesson-7", "title": "Qubits", "summary": "Meet quantum information units."},
                {"id": "lesson-8", "title": "Gates", "summary": "Transform quantum states with logic."},
                {"id": "lesson-9", "title": "Algorithms", "summary": "End with quantum speedups."}
              ]
            }
            """,
            topic: "Quantum Mechanics"
        )

        #expect(snapshot.courseTitle == "Quantum Basics")
        #expect(snapshot.lessons.count == 8)
        #expect(snapshot.unlockedLessonIDs == ["lesson-1"])
        #expect(snapshot.currentActionableLessonID == "lesson-1")
    }

    @Test func pathCourseParserRejectsMalformedResponses() {
        do {
            _ = try PathPayloadParser.parseCourseSnapshot(
                from: "{\"courseTitle\":\"Broken\",\"lessons\":[{\"id\":\"lesson-1\",\"title\":\"Only One\",\"summary\":\"Too short.\"}]}",
                topic: "Biology"
            )
            Issue.record("Expected malformed path course payload to throw.")
        } catch {}
    }

    @Test func pathLessonParserBuildsReelsAndQuiz() throws {
        let lesson = PathLessonSummary(
            id: "lesson-1",
            order: 1,
            title: "Atoms",
            summary: "Start with atomic structure."
        )

        let progress = try PathPayloadParser.parseLessonProgress(
            from: """
            {
              "lessonTitle": "Atoms",
              "summary": "Start with atomic structure.",
              "chapters": [
                {"title": "Inside the atom", "cards": ["Atoms contain protons, neutrons, and electrons. Each part changes how matter behaves.", "The nucleus holds most of the mass. Electrons occupy the surrounding cloud."]},
                {"title": "Atomic number", "cards": ["The proton count defines the element. Change the proton count and you change the element.", "Neutrons can vary without changing the element name."]}
              ],
              "quiz": [
                {"id": "q1", "prompt": "What defines the element?", "choices": ["Proton count", "Electron speed", "Color"], "correctAnswerIndex": 0, "explanation": "The number of protons determines the element."},
                {"id": "q2", "prompt": "Where is most atomic mass?", "choices": ["In the nucleus", "In the electron cloud", "Outside the atom"], "correctAnswerIndex": 0, "explanation": "The nucleus contains protons and neutrons, which hold most of the mass."}
              ]
            }
            """,
            lesson: lesson
        )

        #expect(progress.hydratedReels.count == 4)
        #expect(progress.quizQuestions.count == 2)
        #expect(progress.quizQuestions.first?.choices.count == 3)
        for reel in progress.hydratedReels {
            if case .content(_, let text) = reel.content {
                #expect(sentenceCount(in: text) >= 3)
            }
        }
    }

    @MainActor
    @Test func pathPerfectQuizUnlocksExactlyOneNextLesson() {
        let (defaults, suiteName) = makeTestDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let viewModel = PathCourseViewModel(
            service: StubOpenRouterService(),
            userDefaults: defaults
        )
        let snapshot = makeCourseSnapshot(
            progress: makeLessonProgress(
                lessonID: "lesson-1",
                selectedAnswers: ["q1": 0, "q2": 1]
            )
        )

        viewModel.loadRecentCourse(snapshot)
        let result = viewModel.submitQuizAnswers(lessonID: "lesson-1")

        #expect(result == LessonCompletionResult(passed: true, unlockedLessonID: "lesson-2", isCourseComplete: false))
        #expect(viewModel.course?.completedLessonIDs.contains("lesson-1") == true)
        #expect(viewModel.course?.unlockedLessonIDs.contains("lesson-2") == true)
        #expect(viewModel.course?.accessState(for: "lesson-3") == Optional.some(.locked))
        #expect(viewModel.course?.currentLessonID == "lesson-2")
    }

    @MainActor
    @Test func pathLessonSessionResumesAtSavedReel() {
        let (defaults, suiteName) = makeTestDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let viewModel = PathCourseViewModel(
            service: StubOpenRouterService(),
            userDefaults: defaults
        )
        var progress = makeLessonProgress(lessonID: "lesson-1")
        let savedReelID = progress.hydratedReels[1].id
        progress.lastViewedReelID = savedReelID.uuidString

        viewModel.loadRecentCourse(makeCourseSnapshot(progress: progress))
        let session = PathLessonSessionViewModel(courseViewModel: viewModel, lessonID: "lesson-1")

        let initialPage = session.initialPageID()

        if case .some(.reel(let reelID)) = initialPage {
            #expect(reelID == savedReelID)
        } else {
            Issue.record("Expected path lesson to resume at saved reel.")
        }
    }

    @MainActor
    @Test func pathLessonSessionResumesAtFirstUnansweredQuizQuestion() {
        let (defaults, suiteName) = makeTestDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let viewModel = PathCourseViewModel(
            service: StubOpenRouterService(),
            userDefaults: defaults
        )
        var progress = makeLessonProgress(lessonID: "lesson-1")
        progress.didReachQuiz = true
        progress.selectedAnswerIndices["q1"] = 0

        viewModel.loadRecentCourse(makeCourseSnapshot(progress: progress))
        let session = PathLessonSessionViewModel(courseViewModel: viewModel, lessonID: "lesson-1")

        let initialPage = session.initialPageID()

        if case .some(.quiz(let questionID)) = initialPage {
            #expect(questionID == "q2")
        } else {
            Issue.record("Expected path lesson to resume at the next quiz question.")
        }
    }

    @MainActor
    @Test func pathProgressPersistsAcrossViewModelReload() {
        let (defaults, suiteName) = makeTestDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstViewModel = PathCourseViewModel(
            service: StubOpenRouterService(),
            userDefaults: defaults
        )
        var progress = makeLessonProgress(lessonID: "lesson-1")
        progress.didReachQuiz = true
        progress.selectedAnswerIndices["q1"] = 0

        firstViewModel.loadRecentCourse(makeCourseSnapshot(progress: progress))

        let secondViewModel = PathCourseViewModel(
            service: StubOpenRouterService(),
            userDefaults: defaults
        )

        #expect(secondViewModel.recentCourses.count == 1)
        #expect(secondViewModel.recentCourses.first?.lessonProgressByID["lesson-1"]?.didReachQuiz == true)
        #expect(secondViewModel.recentCourses.first?.lessonProgressByID["lesson-1"]?.selectedAnswerIndices["q1"] == 0)
    }

    private func assertChapter(_ reel: Reel, index: Int, title: String) {
        switch reel.content {
        case .chapterTitle(let actualIndex, let actualTitle):
            #expect(actualIndex == index)
            #expect(actualTitle == title)
        default:
            Issue.record("Expected chapterTitle, got content reel.")
        }
    }

    private func assertContent(_ reel: Reel, chapterIndex: Int, textContains: String) {
        switch reel.content {
        case .content(let actualChapterIndex, let text):
            #expect(actualChapterIndex == chapterIndex)
            if !textContains.isEmpty {
                #expect(text.contains(textContains))
            }
        default:
            Issue.record("Expected content reel, got chapterTitle reel.")
        }
    }

    @MainActor
    private func makeCourseSnapshot(progress: PathLessonProgress) -> PathCourseSnapshot {
        let lessons = [
            PathLessonSummary(id: "lesson-1", order: 1, title: "Atoms", summary: "Start with matter."),
            PathLessonSummary(id: "lesson-2", order: 2, title: "Waves", summary: "See wave behavior."),
            PathLessonSummary(id: "lesson-3", order: 3, title: "Superposition", summary: "Layer possible states."),
            PathLessonSummary(id: "lesson-4", order: 4, title: "Entanglement", summary: "Connect distant particles.")
        ]

        return PathCourseSnapshot(
            topic: "Quantum Mechanics",
            courseTitle: "Quantum Basics",
            lessons: lessons,
            currentLessonID: "lesson-1",
            unlockedLessonIDs: ["lesson-1"],
            completedLessonIDs: [],
            lessonProgressByID: ["lesson-1": progress],
            updatedAt: .now
        )
    }

    private func makeLessonProgress(
        lessonID: String,
        selectedAnswers: [String: Int] = [:]
    ) -> PathLessonProgress {
        let reels = [
            Reel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, content: .chapterTitle(index: 1, title: "Inside the atom")),
            Reel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, content: .content(chapterIndex: 1, text: "Atoms contain protons, neutrons, and electrons.")),
            Reel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, content: .content(chapterIndex: 1, text: "The nucleus stores most of the mass."))
        ]

        let questions = [
            QuizQuestion(
                id: "q1",
                prompt: "What defines an element?",
                choices: ["Proton count", "Brightness", "Electron color"],
                correctAnswerIndex: 0,
                explanation: "The number of protons determines the element."
            ),
            QuizQuestion(
                id: "q2",
                prompt: "Where is most atomic mass?",
                choices: ["In the electron cloud", "In the nucleus", "In empty space"],
                correctAnswerIndex: 1,
                explanation: "Protons and neutrons in the nucleus hold most of the mass."
            )
        ]

        return PathLessonProgress(
            lessonID: lessonID,
            reels: reels.map(StoredReel.init(from:)),
            quizQuestions: questions,
            lastViewedReelID: nil,
            didReachQuiz: false,
            selectedAnswerIndices: selectedAnswers,
            isQuizPassed: false,
            isCompleted: false,
            lastSubmissionPassed: nil
        )
    }

    private func sentenceCount(in value: String) -> Int {
        value.split(whereSeparator: { ".!?".contains($0) }).count
    }

    private func makeTestDefaults() -> (UserDefaults, String) {
        let suiteName = "StillMonkeyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}

private struct StubOpenRouterService: OpenRouterServing, Sendable {
    func fetchJSON(
        prompt _: String,
        systemPrompt _: String,
        apiKey _: String,
        maxTokens _: Int
    ) async throws -> String {
        ""
    }

    func stream(prompt _: String, systemPrompt _: String, apiKey _: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}
