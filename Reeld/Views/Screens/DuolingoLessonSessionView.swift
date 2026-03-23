import SwiftUI

struct DuolingoLessonSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DuolingoLessonSessionViewModel
    @State private var currentPageID: DuolingoLessonSessionViewModel.PageID?
    @State private var hasAppliedInitialPosition = false
    @State private var isPagingReady = false

    init(viewModel: DuolingoLessonSessionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var currentIndex: Int {
        guard let currentPageID else { return 0 }
        return viewModel.pages.firstIndex(of: currentPageID) ?? 0
    }

    var body: some View {
        ZStack {
            ReeldScreenBackground.standard
                .ignoresSafeArea()

            ReeldScreenBackground.accentWash(
                topLeading: Config.Brand.accentColor(at: 5).opacity(0.12),
                topTrailing: Config.Brand.actionTint.opacity(0.18)
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if viewModel.isLoading && viewModel.pages.isEmpty {
                loadingState
            } else if let error = viewModel.error, viewModel.pages.isEmpty {
                errorState(message: error)
            } else if !viewModel.pages.isEmpty && !isPagingReady {
                loadingState
            } else {
                pagedLesson
            }
        }
        .navigationTitle(viewModel.lesson?.title ?? "Lesson")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let firstContentPageID = viewModel.firstContentPageID {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        jumpToLessonStart(firstContentPageID)
                    } label: {
                        Image(systemName: "arrowshape.up")
                            .font(.system(size: UIIconSize.navAction, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        currentPageID == firstContentPageID
                            ? .white.opacity(0.28)
                            : .white.opacity(0.88)
                    )
                    .disabled(currentPageID == firstContentPageID)
                    .accessibilityLabel("Go to lesson start")
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
            applyInitialPositionIfNeeded()
        }
        .onChange(of: viewModel.pages) { _, _ in
            applyInitialPositionIfNeeded()
        }
        .onChange(of: currentPageID) { _, newValue in
            viewModel.recordVisiblePage(newValue)
        }
    }

    private var pagedLesson: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.pages, id: \.self) { pageID in
                    page(for: pageID)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(pageID)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $currentPageID)
    }

    @ViewBuilder
    private func page(for pageID: DuolingoLessonSessionViewModel.PageID) -> some View {
        if let reel = viewModel.reel(for: pageID) {
            ReelCardView(
                reel: reel,
                currentIndex: currentIndex,
                cardIndex: currentIndexForPage(pageID),
                totalCount: viewModel.pages.count,
                chapterTitle: viewModel.chapterTitlesByIndex[reel.chapterIndex],
                topicTitle: viewModel.topicTitle,
                showsProgressBar: true
            )
        } else if let question = viewModel.question(for: pageID) {
            QuizQuestionCard(
                question: question,
                selectedAnswerIndex: viewModel.selectedAnswerIndex(for: question),
                revealAnswers: viewModel.shouldRevealAnswer(for: question),
                onSelectAnswer: { answerIndex in
                    viewModel.selectAnswer(answerIndex, for: question)
                },
                isCorrectChoice: { choiceIndex in
                    viewModel.choiceIsCorrect(choiceIndex, for: question)
                },
                topicTitle: viewModel.topicTitle,
                lessonTitle: viewModel.lesson?.title ?? "Lesson"
            )
        } else {
            LessonResultCard(
                canSubmitQuiz: viewModel.canSubmitQuiz,
                hasQuizAttempt: viewModel.hasQuizAttempt,
                didPassQuiz: viewModel.didPassQuiz,
                unlockedLessonID: viewModel.latestResult?.unlockedLessonID ?? (viewModel.didPassQuiz ? viewModel.nextLessonID : nil),
                isCourseComplete: viewModel.latestResult?.isCourseComplete ?? false,
                onSubmit: {
                    viewModel.submitQuiz()
                },
                onRetry: {
                    if let firstQuestion = viewModel.quizQuestions.first {
                        currentPageID = .quiz(firstQuestion.id)
                    }
                },
                onBackToPath: {
                    dismiss()
                }
            )
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            Text("Loading lesson...")
                .font(.headline)
                .foregroundStyle(Config.Brand.readableSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: UIIconSize.hero))
                .foregroundStyle(Config.Brand.focusColor.opacity(0.9))
            Text(message)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Button("Back to path") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(Config.Brand.startButtonFill)
            .foregroundStyle(Config.Brand.startButtonTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func applyInitialPositionIfNeeded() {
        guard !hasAppliedInitialPosition, !viewModel.pages.isEmpty else { return }
        hasAppliedInitialPosition = true
        isPagingReady = false

        Task { @MainActor in
            await Task.yield()
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                currentPageID = viewModel.initialPageID()
            }
            await Task.yield()
            isPagingReady = true
        }
    }

    private func currentIndexForPage(_ pageID: DuolingoLessonSessionViewModel.PageID) -> Int {
        viewModel.pages.firstIndex(of: pageID) ?? 0
    }

    private func jumpToLessonStart(_ firstContentPageID: DuolingoLessonSessionViewModel.PageID) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            currentPageID = firstContentPageID
        }
    }
}

private struct QuizQuestionCard: View {
    let question: QuizQuestion
    let selectedAnswerIndex: Int?
    let revealAnswers: Bool
    let onSelectAnswer: (Int) -> Void
    let isCorrectChoice: (Int) -> Bool
    let topicTitle: String
    let lessonTitle: String

    var body: some View {
        ZStack {
            ReeldScreenBackground.standard

            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quiz")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Config.Brand.shortBreakColor)
                    Text(question.prompt)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.88))
                        .lineSpacing(10)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                        Button {
                            onSelectAnswer(index)
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(circleBorder(for: index), lineWidth: 2)
                                        .background(Circle().fill(circleFill(for: index)))
                                        .frame(width: 24, height: 24)
                                    if selectedAnswerIndex == index {
                                        Circle()
                                            .fill(choiceForeground(for: index))
                                            .frame(width: 10, height: 10)
                                    }
                                }
                                .padding(.top, 2)

                                Text(choice)
                                    .font(.system(size: 20))
                                    .foregroundStyle(choiceForeground(for: index))
                                    .lineSpacing(10)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(choiceBackground(for: index))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(choiceBorder(for: index), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if revealAnswers, let selectedAnswerIndex {
                    Text(feedbackMessage(for: selectedAnswerIndex))
                        .font(.subheadline)
                        .foregroundStyle(feedbackColor(for: selectedAnswerIndex))

                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text(lessonTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                    Text(topicTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Config.Brand.readableTertiaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 44)
            .padding(.bottom, 56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func circleFill(for index: Int) -> Color {
        if selectedAnswerIndex == index {
            return choiceForeground(for: index).opacity(0.18)
        }
        return .clear
    }

    private func circleBorder(for index: Int) -> Color {
        if selectedAnswerIndex == index {
            return choiceForeground(for: index)
        }
        return .white.opacity(0.24)
    }

    private func choiceBackground(for index: Int) -> Color {
        if revealAnswers {
            if isCorrectChoice(index) {
                return Config.Brand.shortBreakColor.opacity(0.18)
            }
            if selectedAnswerIndex == index {
                return Config.Brand.destructiveTint.opacity(0.45)
            }
        }

        if selectedAnswerIndex == index {
            return Color.white.opacity(0.1)
        }

        return Color.white.opacity(0.04)
    }

    private func choiceBorder(for index: Int) -> Color {
        if revealAnswers {
            if isCorrectChoice(index) {
                return Config.Brand.shortBreakColor.opacity(0.72)
            }
            if selectedAnswerIndex == index {
                return Color.red.opacity(0.55)
            }
        }

        if selectedAnswerIndex == index {
            return Color.white.opacity(0.34)
        }

        return Color.white.opacity(0.08)
    }

    private func choiceForeground(for index: Int) -> Color {
        if revealAnswers {
            if isCorrectChoice(index) {
                return Config.Brand.shortBreakColor
            }
            if selectedAnswerIndex == index {
                return Color.red.opacity(0.82)
            }
        }

        if selectedAnswerIndex == index {
            return .white
        }

        return .white.opacity(0.84)
    }

    private func feedbackMessage(for selectedAnswerIndex: Int) -> String {
        isCorrectChoice(selectedAnswerIndex) ? "Correct" : "Not quite"
    }

    private func feedbackColor(for selectedAnswerIndex: Int) -> Color {
        isCorrectChoice(selectedAnswerIndex) ? Config.Brand.shortBreakColor : Color.red.opacity(0.85)
    }
}

private struct LessonResultCard: View {
    let canSubmitQuiz: Bool
    let hasQuizAttempt: Bool
    let didPassQuiz: Bool
    let unlockedLessonID: String?
    let isCourseComplete: Bool
    let onSubmit: () -> Void
    let onRetry: () -> Void
    let onBackToPath: () -> Void

    var body: some View {
        ZStack {
            ReeldScreenBackground.standard

            VStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.headline)
                    .foregroundStyle(Config.Brand.readableSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                VStack(spacing: 12) {
                    if didPassQuiz {
                        Button("Back to path") {
                            onBackToPath()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Config.Brand.startButtonFill)
                        .foregroundStyle(Config.Brand.startButtonTextColor)
                    } else if hasQuizAttempt {
                        Button("Try again") {
                            onRetry()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Config.Brand.startButtonFill)
                        .foregroundStyle(Config.Brand.startButtonTextColor)
                    } else if !hasQuizAttempt {
                        Button("Check answers") {
                            onSubmit()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Config.Brand.startButtonFill)
                        .foregroundStyle(Config.Brand.startButtonTextColor)
                        .disabled(!canSubmitQuiz)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var iconName: String {
        if didPassQuiz {
            return isCourseComplete ? "flag.checkered.2.crossed" : "lock.open.fill"
        }
        if hasQuizAttempt {
            return "arrow.counterclockwise.circle.fill"
        }
        return "questionmark.circle.fill"
    }

    private var iconColor: Color {
        if didPassQuiz {
            return Config.Brand.shortBreakColor
        }
        if hasQuizAttempt {
            return Color.red.opacity(0.78)
        }
        return Config.Brand.focusColor.opacity(0.85)
    }

    private var title: String {
        if didPassQuiz {
            return isCourseComplete ? "Course Complete" : "Lesson Complete"
        }
        if hasQuizAttempt {
            return "Try That Again"
        }
        return "Checkpoint"
    }

    private var message: String {
        if didPassQuiz {
            if isCourseComplete {
                return "You finished the full lesson path for this topic."
            }
            if unlockedLessonID != nil {
                return "You unlocked the next lesson. Head back to the path to keep going."
            }
            return "You passed the quiz."
        }

        if hasQuizAttempt {
            return "Every answer needs to be correct to unlock the next lesson."
        }

        return canSubmitQuiz
            ? "Check your answers to unlock the next lesson."
            : "Answer every question before submitting."
    }
}
