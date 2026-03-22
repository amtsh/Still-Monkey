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
        case .duolingo:
            return nil
        }
    }

    static func duolingoCoursePrompt(topic: String) -> ContentPrompt {
        ContentPrompt(
            systemPrompt: duolingoCourseSystemPrompt,
            userPrompt: topic
        )
    }

    static func duolingoLessonPrompt(
        topic: String,
        courseTitle: String,
        lesson: DuolingoLessonSummary,
        completedLessonTitles: [String]
    ) -> ContentPrompt {
        let completedText = completedLessonTitles.isEmpty
            ? "None yet."
            : completedLessonTitles.joined(separator: ", ")

        return ContentPrompt(
            systemPrompt: duolingoLessonSystemPrompt,
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
    You are an educational assistant. Break the topic into many chapters.
    Output only plain text using this exact structure, with no preamble and no markdown headings:

    CHAPTER: Chapter Title Here
    - Bullet 1 (35-50 words, 2-3 sentences, clear explanation)
    - Bullet 2 (35-50 words, 2-3 sentences, clear explanation)
    - ... continue until Bullet 10

    Rules:
    - Every chapter must have exactly 10 bullet points.
    - Every bullet must be on its own line and start with "- ".
    - Each bullet should be explanatory, not a short phrase.
    - Do not include any text outside this format.
    """

    private static let storySystemPrompt = """
    You are a storytelling assistant that teaches through narrative.
    Output only plain text using this exact structure, with no preamble and no markdown headings:

    CHAPTER: Chapter Title Here
    - Story beat 1 (35-50 words, 2-3 sentences, vivid and easy to read)
    - Story beat 2 (35-50 words, 2-3 sentences, vivid and easy to read)
    - ... continue until Story beat 10

    Rules:
    - Every chapter must have exactly 10 story beats.
    - Every story beat must be on its own line and start with "- ".
    - Keep continuity between beats so the chapter reads like a flowing story.
    - Keep language clear and engaging, suitable for quick reading on mobile.
    - Do not include any text outside this format.
    """

    private static let duolingoCourseSystemPrompt = """
    You are designing a mobile-first lesson path for a Duolingo-style learning experience.
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
    - Summaries must be one sentence and under 120 characters.
    - Every lesson id must be unique, lowercase, and hyphenated.
    - Do not include markdown, code fences, comments, or any text outside the JSON object.
    """

    private static let duolingoLessonSystemPrompt = """
    You are generating one Duolingo-style lesson for a mobile micro-learning app.
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
    - Each card must contain at least 3 sentences.
    - Each card must be readable on mobile and stay focused on one idea.
    - Return 2 to 4 quiz questions.
    - Each quiz question must have 3 or 4 choices.
    - Every question must be answerable using only the lesson content.
    - Do not include markdown, code fences, comments, or any text outside the JSON object.
    """
}
