//
//  BookmarkedContentView.swift
//  Still Monkey
//

import SwiftUI

struct BookmarkedContentView: View {
    let entry: BookmarkEntry
    let onConfirmRemove: () -> Void

    @State private var isConfirmingRemove = false

    var body: some View {
        Group {
            switch entry.payload {
            case let .feedReel(payload):
                bookmarkedFeedReel(payload)
            case let .feedLearnEnd(payload):
                bookmarkedFeedLearnEnd(payload)
            case let .pathReel(payload):
                bookmarkedPathReel(payload)
            case let .pathQuiz(payload):
                bookmarkedPathQuiz(payload)
            case let .pathResult(payload):
                bookmarkedPathResult(payload)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appBlendedNavigationBar()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticsFeedback.impactSoft()
                    isConfirmingRemove = true
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: UIIconSize.navAction, weight: .semibold))
                        .foregroundStyle(.white.opacity(ReadingNavigationChrome.toolbarBookmarkFilledOpacity))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove bookmark")
            }
        }
        .alert("Remove bookmark?", isPresented: $isConfirmingRemove) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                HapticsFeedback.impactMedium()
                onConfirmRemove()
            }
        } message: {
            Text("This removes the bookmark from your list on this device.")
        }
    }

    private func bookmarkedFeedReel(_ payload: FeedReelBookmarkPayload) -> some View {
        let reel = payload.storedReel.asReel
        return AppScreenCanvas(wash: .none) {
            ReelCardView(
                reel: reel,
                currentIndex: 0,
                cardIndex: 0,
                totalCount: 1,
                chapterTitle: payload.chapterTitle,
                topicTitle: payload.topicTitle,
                showsProgressBar: false,
                progressAccent: payload.contentMode.modeAccentColor
            )
            .containerRelativeFrame([.horizontal, .vertical])
        }
    }

    private func bookmarkedFeedLearnEnd(_ payload: FeedLearnEndBookmarkPayload) -> some View {
        BookmarkedLearnEndStaticView(
            topicTitle: payload.topicTitleDisplay,
            progressAccent: payload.contentMode.modeAccentColor
        )
    }

    private func bookmarkedPathReel(_ payload: PathReelBookmarkPayload) -> some View {
        let reel = payload.storedReel.asReel
        return AppScreenCanvas(wash: .pathDefault) {
            ReelCardView(
                reel: reel,
                currentIndex: 0,
                cardIndex: 0,
                totalCount: 1,
                chapterTitle: payload.chapterTitle,
                topicTitle: payload.topicTitle,
                showsProgressBar: false,
                progressAccent: ContentMode.path.modeAccentColor
            )
            .containerRelativeFrame([.horizontal, .vertical])
        }
    }

    private func bookmarkedPathQuiz(_ payload: PathQuizBookmarkPayload) -> some View {
        AppScreenCanvas(wash: .none) {
            BookmarkedQuizReadOnlyView(
                question: payload.question,
                topicTitle: payload.topicTitle,
                lessonTitle: payload.lessonTitle
            )
        }
    }

    private func bookmarkedPathResult(_ payload: PathResultBookmarkPayload) -> some View {
        AppScreenCanvas(wash: .none) {
            BookmarkedLessonResultStaticView(payload: payload)
        }
    }
}

private struct BookmarkedQuizReadOnlyView: View {
    let question: QuizQuestion
    let topicTitle: String
    let lessonTitle: String

    var body: some View {
        ZStack {
            AppScreenBackground.standard
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quiz")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Config.Brand.shortBreakColor)
                        Text(question.prompt)
                            .font(.system(size: ReadingTypography.bodySize))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .lineSpacing(ReadingTypography.bodyLineSpacing)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.24), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    if index == question.correctAnswerIndex {
                                        Circle()
                                            .fill(Config.Brand.shortBreakColor)
                                            .frame(width: 10, height: 10)
                                    }
                                }
                                .padding(.top, 2)
                                Text(choice)
                                    .font(.system(size: ReadingTypography.bodySize))
                                    .foregroundStyle(.white.opacity(0.84))
                                    .lineSpacing(ReadingTypography.bodyLineSpacing)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.white.opacity(index == question.correctAnswerIndex ? 0.08 : 0.04))
                            )
                        }
                    }

                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 24)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(lessonTitle)
                            .font(.system(size: ReadingTypography.footnoteTitleSize, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Text(topicTitle)
                            .font(.system(size: ReadingTypography.footnoteTopicSize, weight: .medium))
                            .foregroundStyle(Config.Brand.readableTertiaryText)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 44)
                .padding(.bottom, 56)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

private struct BookmarkedLearnEndStaticView: View {
    let topicTitle: String
    let progressAccent: Color

    var body: some View {
        ZStack {
            AppScreenBackground.standard
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(progressAccent)
                    .accessibilityHidden(true)

                Text("End of lesson")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 10) {
                    Text(topicTitle)
                        .font(.system(size: ReadingTypography.bodySize, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("You can continue to learn more about this topic by going deeper.")
                        .font(.system(size: ReadingTypography.bodySize))
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .lineSpacing(ReadingTypography.bodyLineSpacing)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct BookmarkedLessonResultStaticView: View {
    let payload: PathResultBookmarkPayload

    private var title: String {
        if payload.passed {
            return payload.isCourseComplete ? "Course Complete" : "Lesson Complete"
        }
        return "Checkpoint"
    }

    private var message: String {
        if payload.passed {
            if payload.isCourseComplete {
                return "You finished the full lesson path for this topic."
            }
            if payload.unlockedLessonID != nil {
                return "You unlocked the next lesson. Head back to the path to keep going."
            }
            return "You passed the quiz."
        }
        return "Saved checkpoint from this lesson."
    }

    var body: some View {
        ZStack {
            AppScreenBackground.standard
            VStack(spacing: 20) {
                Image(systemName: payload.passed ? (payload.isCourseComplete ? "flag.checkered.2.crossed" : "lock.open.fill") : "questionmark.circle.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(payload.passed ? Config.Brand.shortBreakColor : ContentMode.path.modeAccentColor.opacity(0.85))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: ReadingTypography.bodySize))
                    .foregroundStyle(Config.Brand.readableSecondaryText)
                    .lineSpacing(ReadingTypography.bodyLineSpacing)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
