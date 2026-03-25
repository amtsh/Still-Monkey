import Foundation

enum ContentPromptLibrary {
    static func prompt(for mode: ContentMode, topic: String) -> ContentPrompt? {
        switch mode {
        case .learn:
            return ContentPrompt(
                systemPrompt: learnSystemPrompt,
                userPrompt: topic
            )
        case .story:
            return ContentPrompt(
                systemPrompt: storySystemPrompt,
                userPrompt: "Create a story about: \(topic)"
            )
        case .path:
            return nil
        }
    }

    static func pathCoursePrompt(topic: String) -> ContentPrompt {
        ContentPrompt(
            systemPrompt: pathCourseSystemPrompt,
            userPrompt: topic
        )
    }

    /// Continuation lessons after the learner has finished the current map (deeper / advanced track).
    static func pathExtendCoursePrompt(
        topic: String,
        courseTitle: String,
        completedLessonLines: [String],
        existingLessonIDs: [String]
    ) -> ContentPrompt {
        let completedBlock = completedLessonLines.isEmpty
            ? "None."
            : completedLessonLines.joined(separator: "\n")
        let existingIDsBlock = existingLessonIDs.joined(separator: ", ")

        return ContentPrompt(
            systemPrompt: pathExtendCourseSystemPrompt,
            userPrompt: """
            Topic: \(topic)
            Course title: \(courseTitle)

            Lessons already completed (do not repeat these titles or ids):
            \(completedBlock)

            Existing lesson ids you must NOT reuse: \(existingIDsBlock)

            Generate the next segment of the path that goes deeper: more advanced, applied, or specialized topics that build on what was covered.
            """
        )
    }

    static func pathLessonPrompt(
        topic: String,
        courseTitle: String,
        lesson: PathLessonSummary,
        completedLessonTitles: [String]
    ) -> ContentPrompt {
        let completedText = completedLessonTitles.isEmpty
            ? "None yet."
            : completedLessonTitles.joined(separator: ", ")

        return ContentPrompt(
            systemPrompt: pathLessonSystemPrompt,
            userPrompt: """
            Topic: \(topic)
            Course title: \(courseTitle)
            Lesson order: \(lesson.order)
            Lesson title: \(lesson.title)
            Lesson summary: \(lesson.summary)
            Completed lessons so far: \(completedText)
            """
        )
    }

    private static let learnSystemPrompt = """
    You are an expert educational writer. Teach the topic with depth: definitions, mechanisms, cause-and-effect, and at least one concrete example or analogy per bullet where it helps understanding.
    Avoid shallow listicles, vague claims, and filler. Each bullet must add new insight.

    Output only plain text using this exact structure, with no preamble and no markdown headings:

    CHAPTER: Chapter Title Here
    - Bullet 1 (55-85 words, 3-5 sentences: explain the idea clearly; include specifics, not generic advice)
    - Bullet 2 (55-85 words, 3-5 sentences)
    - ... continue until Bullet 10

    Rules:
    - Every chapter must have exactly 10 bullet points.
    - Every bullet must be on its own line and start with "- ".
    - Prefer precision: names, numbers, steps, or contrasts when relevant to the topic.
    - Do not include any text outside this format.
    """

    private static let storySystemPrompt = """
    You are a storytelling assistant that teaches through rich narrative: sensory detail, character reaction, and plot logic—not summaries or clichés.
    Each beat should advance the story and deepen what the reader understands about the topic.

    Output only plain text using this exact structure, with no preamble and no markdown headings:

    CHAPTER: Chapter Title Here
    - Story beat 1 (55-85 words, 3-5 sentences: concrete scene or moment; show, don't tell)
    - Story beat 2 (55-85 words, 3-5 sentences)
    - ... continue until Story beat 10

    Rules:
    - Every chapter must have exactly 10 story beats.
    - Every story beat must be on its own line and start with "- ".
    - Maintain continuity: each beat follows logically from the last.
    - Avoid shallow or generic beats; keep language clear and engaging for mobile reading.
    - Do not include any text outside this format.
    """

    private static let pathCourseSystemPrompt = """
    You are designing a substantive mobile-first lesson path: each lesson should feel worth studying, with clear scope and progression.
    Return only valid JSON matching this exact shape:

    {
      "courseTitle": "Short course title",
      "lessons": [
        {
          "id": "lesson-1-short-slug",
          "title": "Lesson title",
          "summary": "One concise sentence about what this lesson covers."
        }
      ]
    }

    Rules:
    - Return 4 to 8 lessons depending on topic complexity.
    - Lessons must build sequentially from beginner-friendly to more advanced.
    - Titles must be short and clear for mobile UI.
    - Summaries must be one informative sentence (what the learner will understand or do), under 120 characters—avoid vague marketing language.
    - Every lesson id must be unique, lowercase, and hyphenated.
    - Do not include markdown, code fences, comments, or any text outside the JSON object.
    """

    private static let pathExtendCourseSystemPrompt = """
    The learner has already completed every lesson in their current path. You are adding NEW lessons that continue the same course, going deeper or more advanced.
    Return only valid JSON matching this exact shape:

    {
      "lessons": [
        {
          "id": "lesson-unique-slug",
          "title": "Lesson title",
          "summary": "One concise sentence about what this lesson covers."
        }
      ]
    }

    Rules:
    - Return 4 to 8 new lessons. Each must be distinct from prior lessons and strictly more advanced or applied than the completed list.
    - Lesson ids must be unique, lowercase, hyphenated, and must not appear in the "existing lesson ids" list provided by the user.
    - Titles must be short and clear for mobile UI.
    - Summaries must be one informative sentence (under 120 characters).
    - Do not include markdown, code fences, comments, or any text outside the JSON object.
    """

    private static let pathLessonSystemPrompt = """
    You are generating one short, bite-sized lesson for a mobile micro-learning app.
    Return only valid JSON matching this exact shape:

    {
      "lessonTitle": "Lesson title",
      "summary": "Short summary",
      "chapters": [
        {
          "title": "Chapter title",
          "cards": [
            "Card text with 2 to 3 clear sentences."
          ]
        }
      ],
      "quiz": [
        {
          "id": "question-1",
          "prompt": "Question text",
          "choices": ["Option A", "Option B", "Option C"],
          "correctAnswerIndex": 0,
          "explanation": "Short explanation for why the answer is correct."
        }
      ]
    }

    Rules:
    - Return 2 to 4 chapters.
    - Each chapter must include 2 to 4 cards.
    - Each card must contain at least 4 sentences with substantive explanation (definitions, steps, examples, or implications)—not vague filler.
    - Each card must be readable on mobile and stay focused on one idea.
    - Return 2 to 4 quiz questions.
    - Each quiz question must have 3 or 4 choices.
    - Every question must be answerable using only the lesson content.
    - Do not include markdown, code fences, comments, or any text outside the JSON object.
    """
}
