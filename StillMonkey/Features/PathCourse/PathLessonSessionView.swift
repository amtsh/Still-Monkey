import SwiftUI

struct PathLessonSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: PathLessonSessionViewModel
    let bookmarkStore: BookmarkStore
    @State private var currentPageID: PathLessonSessionViewModel.PageID?
    @State private var hasAppliedInitialPosition = false
    @State private var isPagingReady = false
    /// Furthest page index reached this session; “jump to first” only after swiping back from a later slide (matches `ReelsView`).
    @State private var maxVisitedSlideIndex: Int = 0

    init(viewModel: PathLessonSessionViewModel, bookmarkStore: BookmarkStore) {
        _viewModel = State(initialValue: viewModel)
        self.bookmarkStore = bookmarkStore
    }

    private var currentIndex: Int {
        guard let currentPageID else { return 0 }
        return viewModel.pages.firstIndex(of: currentPageID) ?? 0
    }

    private var isChapterLoadingState: Bool {
        (viewModel.isLoading && viewModel.pages.isEmpty) || (!viewModel.pages.isEmpty && !isPagingReady)
    }

    private var bookmarkEntryForCurrentPage: BookmarkEntry? {
        guard let pageID = currentPageID, !viewModel.pages.isEmpty else { return nil }
        let topicTitle = viewModel.topicTitle

        switch pageID {
        case let .reel(reelID):
            guard let reel = viewModel.reel(for: .reel(reelID)) else { return nil }
            let chapterTitle = viewModel.chapterTitlesByIndex[reel.chapterIndex]
            let stableKey = BookmarkStableKey.pathReel(lessonID: viewModel.lessonID, reelID: reel.id)
            let payload = PathReelBookmarkPayload(
                storedReel: StoredReel(from: reel),
                chapterTitle: chapterTitle,
                topicTitle: topicTitle
            )
            return BookmarkEntry(
                stableKey: stableKey,
                displayTitle: reel.displayBookmarkTitle(chapterTitle: chapterTitle),
                displaySubtitle: topicTitle,
                payload: .pathReel(payload)
            )
        case .quiz, .result:
            return nil
        }
    }

    private func pathBookmarkButton(for entry: BookmarkEntry) -> some View {
        let isOn = bookmarkStore.contains(stableKey: entry.stableKey)
        return Button {
            HapticsFeedback.impactSoft()
            bookmarkStore.toggle(entry)
        } label: {
            Image(systemName: isOn ? "bookmark.fill" : "bookmark")
                .font(.system(size: UIIconSize.navAction, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            .white.opacity(
                isOn ? ReadingNavigationChrome.toolbarBookmarkFilledOpacity : ReadingNavigationChrome.toolbarActionOpacity
            )
        )
        .accessibilityLabel(isOn ? "Remove bookmark" : "Bookmark this page")
    }

    var body: some View {
        Group {
            if isChapterLoadingState {
                AppScreenCanvas(wash: .none) {
                    lessonContent
                }
            } else {
                AppScreenCanvas(wash: .custom(
                    topLeading: Config.Brand.accentColor(at: 5).opacity(0.12),
                    topTrailing: Config.Brand.actionTint.opacity(0.18)
                )) {
                    lessonContent
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appBlendedNavigationBar()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.lesson?.title ?? "Lesson")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(ReadingNavigationChrome.titleOpacity))
                    .lineLimit(1)
            }
            if !viewModel.pages.isEmpty {
                if let bookmarkEntry = bookmarkEntryForCurrentPage {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        pathBookmarkButton(for: bookmarkEntry)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Group {
                        if currentIndex == 0 {
                            Button {
                                Task { await reloadLesson() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: UIIconSize.navAction, weight: .semibold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(
                                viewModel.isLoading
                                    ? .white.opacity(ReadingNavigationChrome.toolbarActionDisabledOpacity)
                                    : .white.opacity(ReadingNavigationChrome.toolbarActionOpacity)
                            )
                            .disabled(viewModel.isLoading)
                            .accessibilityLabel("Reload lesson")
                        } else if maxVisitedSlideIndex > currentIndex, let firstContentPageID = viewModel.firstContentPageID {
                            Button {
                                jumpToLessonStart(firstContentPageID)
                            } label: {
                                Image(systemName: "arrowshape.up")
                                    .font(.system(size: UIIconSize.navAction, weight: .semibold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(ReadingNavigationChrome.toolbarActionOpacity))
                            .accessibilityLabel("Go to first slide")
                        }
                    }
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
        .onChange(of: viewModel.reelsChangeToken) { _, _ in
            maxVisitedSlideIndex = 0
            syncMaxVisitedSlideIndex()
        }
        .onChange(of: currentPageID) { _, newValue in
            viewModel.recordVisiblePage(newValue)
            syncMaxVisitedSlideIndex()
        }
        .onAppear {
            syncMaxVisitedSlideIndex()
        }
    }

    @ViewBuilder
    private var lessonContent: some View {
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

    private var pagedLesson: some View {
        ScrollView(.vertical) {
            let pages = viewModel.pages
            let chapterTitlesByIndex = viewModel.chapterTitlesByIndex

            LazyVStack(spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.element) { pageIndex, pageID in
                    page(
                        for: pageID,
                        pageIndex: pageIndex,
                        totalPageCount: pages.count,
                        chapterTitlesByIndex: chapterTitlesByIndex
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .clipShape(Rectangle())
                    .clipped()
                    .id(pageID)
                }
            }
            .scrollTargetLayout()
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $currentPageID)
        .scrollClipDisabled(false)
        .scrollContentBackground(.hidden)
        .clipShape(Rectangle())
        .clipped()
    }

    private func page(
        for pageID: PathLessonSessionViewModel.PageID,
        pageIndex: Int,
        totalPageCount: Int,
        chapterTitlesByIndex: [Int: String]
    ) -> some View {
        ZStack {
            pageContent(
                for: pageID,
                pageIndex: pageIndex,
                totalPageCount: totalPageCount,
                chapterTitlesByIndex: chapterTitlesByIndex
            )
        }
    }

    @ViewBuilder
    private func pageContent(
        for pageID: PathLessonSessionViewModel.PageID,
        pageIndex: Int,
        totalPageCount: Int,
        chapterTitlesByIndex: [Int: String]
    ) -> some View {
        if let reel = viewModel.reel(for: pageID) {
            ReelCardView(
                reel: reel,
                currentIndex: currentIndex,
                cardIndex: pageIndex,
                totalCount: totalPageCount,
                chapterTitle: chapterTitlesByIndex[reel.chapterIndex],
                topicTitle: viewModel.topicTitle,
                showsProgressBar: true,
                progressAccent: ContentMode.path.modeAccentColor
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
                onReread: {
                    if let firstContentPageID = viewModel.firstContentPageID {
                        jumpToLessonStart(firstContentPageID)
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
                .accessibilityLabel("Loading lesson")
            Text("Loading lesson ...")
                .font(.headline)
                .foregroundStyle(Config.Brand.readableSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: UIIconSize.hero))
                .foregroundStyle(ContentMode.path.modeAccentColor.opacity(0.9))
            Text(message)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Button("Back to path") {
                dismiss()
            }
            .font(.headline.weight(.semibold))
            .controlSize(.large)
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

    private func syncMaxVisitedSlideIndex() {
        maxVisitedSlideIndex = max(maxVisitedSlideIndex, currentIndex)
    }

    private func reloadLesson() async {
        HapticsFeedback.impactSoft()
        hasAppliedInitialPosition = false
        isPagingReady = false
        maxVisitedSlideIndex = 0
        await viewModel.reloadLessonContent()
        guard viewModel.error == nil else { return }
        applyInitialPositionIfNeeded()
    }

    private func jumpToLessonStart(_ firstContentPageID: PathLessonSessionViewModel.PageID) {
        withAnimation(reduceMotion ? .none : .spring(response: 0.38, dampingFraction: 0.84)) {
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
            AppScreenBackground.standard

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
                                    .font(.system(size: ReadingTypography.bodySize))
                                    .foregroundStyle(choiceForeground(for: index))
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
                                    .fill(choiceBackground(for: index))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(choiceBorder(for: index), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "Option \(index + 1) of \(question.choices.count): \(choice)"
                                + (selectedAnswerIndex == index ? ", selected" : "")
                        )
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
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

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
    let onReread: () -> Void
    let onBackToPath: () -> Void

    @State private var didEmitResultHaptic = false

    var body: some View {
        ZStack {
            AppScreenBackground.standard

            VStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(iconColor)
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

                VStack(spacing: 12) {
                    if didPassQuiz {
                        Button {
                            HapticsFeedback.impactMedium()
                            onBackToPath()
                        } label: {
                            Text("Back to path")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Config.Brand.startButtonFill)
                        .foregroundStyle(Config.Brand.startButtonTextColor)

                        Button("Read lesson again") {
                            HapticsFeedback.impactSoft()
                            onReread()
                        }
                        .font(.system(size: 17, weight: .medium))
                        .buttonStyle(.plain)
                        .foregroundStyle(Config.Brand.readableSecondaryText)
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
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            guard !didEmitResultHaptic else { return }
            didEmitResultHaptic = true
            if didPassQuiz {
                HapticsFeedback.lessonSuccess()
            } else if hasQuizAttempt {
                HapticsFeedback.lessonNeedsRetry()
            }
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
        return ContentMode.path.modeAccentColor.opacity(0.85)
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
