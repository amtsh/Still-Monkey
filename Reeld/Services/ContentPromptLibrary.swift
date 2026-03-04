import Foundation

struct ContentPrompt {
    let systemPrompt: String
    let userPrompt: String
}

enum ContentPromptLibrary {
    static func prompt(for mode: ContentMode, topic: String) -> ContentPrompt {
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
        }
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
}
