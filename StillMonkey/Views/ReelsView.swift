//
//  ReelsView.swift
//  Still Monkey
//

import SwiftUI

private enum ReelFeedItemID: Hashable {
    case reel(Reel.ID)
    case learnEnd
}

private enum ReelFeedItem: Identifiable {
    case reel(Reel)
    case learnEnd

    var id: ReelFeedItemID {
        switch self {
        case let .reel(r): return .reel(r.id)
        case .learnEnd: return .learnEnd
        }
    }
}

struct ReelsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: TopicViewModel
    @State private var currentScrollID: ReelFeedItemID?
    @State private var hasShownSwipeHint = false
    @State private var isRestoringPosition = true
    /// Furthest slide index reached this session; used to show “jump to first” only after the user has swiped back from a later slide.
    @State private var maxVisitedSlideIndex: Int = 0

    private var topicTitle: String {
        let rawTitle = viewModel.topic.isEmpty ? viewModel.contentMode.defaultFeedTitle : viewModel.topic
        return rawTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
    }

    /// Learn mode appends a completion screen after the last reel.
    private var feedIncludesLearnEnd: Bool {
        viewModel.contentMode == .learn && !viewModel.reels.isEmpty
    }

    private var feedItems: [ReelFeedItem] {
        let reels = viewModel.reels
        if feedIncludesLearnEnd {
            return reels.map { .reel($0) } + [.learnEnd]
        }
        return reels.map { .reel($0) }
    }

    /// Index within `feedItems` (including Learn end page when present).
    private var currentScrollIndex: Int {
        guard let id = currentScrollID else { return 0 }
        switch id {
        case .learnEnd:
            return max(0, feedItems.count - 1)
        case let .reel(rid):
            return viewModel.reels.firstIndex(where: { $0.id == rid }) ?? 0
        }
    }

    var body: some View {
        AppScreenCanvas(wash: .none) {
            if viewModel.reels.isEmpty {
                emptyState
                    .transition(.opacity)
            } else {
                reelsFeed
                    .transition(.opacity)
            }

            if viewModel.isLoading && !viewModel.reels.isEmpty {
                loadingStrip
            }
        }
        .animation(reduceMotion ? .default : .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.reels.isEmpty)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appBlendedNavigationBar()
        // Learn + Story: same feed chrome (Path mode uses `PathLessonSessionView`).
        .toolbar {
            if !viewModel.reels.isEmpty {
                if currentScrollIndex == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            HapticsFeedback.impactSoft()
                            Task { await viewModel.generateContent() }
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
                        .accessibilityLabel("Reload content")
                    }
                } else if maxVisitedSlideIndex > currentScrollIndex {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            jumpToFirstReel()
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
        .onAppear {
            isRestoringPosition = true
            applyInitialPositionIfNeeded()
            revealProgressBarAfterRestore()
            syncMaxVisitedSlideIndex()
        }
        .onChange(of: currentScrollID) { _, newValue in
            switch newValue {
            case let .reel(id):
                viewModel.recordCurrentReelID(id)
            case .learnEnd:
                if let last = viewModel.reels.last?.id {
                    viewModel.recordCurrentReelID(last)
                }
            case nil:
                break
            }
            if isRestoringPosition, newValue != nil {
                isRestoringPosition = false
            }
            syncMaxVisitedSlideIndex()
        }
    }

    // MARK: – Feed

    private var reelsFeed: some View {
        let chapterTitlesByIndex = viewModel.chapterTitlesByIndex
        let items = feedItems

        return ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { offset, item in
                    Group {
                        switch item {
                        case let .reel(reel):
                            ZStack {
                                ReelCardView(
                                    reel: reel,
                                    currentIndex: currentScrollIndex,
                                    cardIndex: offset,
                                    totalCount: items.count,
                                    chapterTitle: chapterTitlesByIndex[reel.chapterIndex],
                                    topicTitle: topicTitle,
                                    showsProgressBar: !isRestoringPosition
                                )

                                if offset == 0 && !hasShownSwipeHint && items.count > 1 {
                                    SwipeHintOverlay()
                                        .onAppear { hasShownSwipeHint = true }
                                }
                            }
                        case .learnEnd:
                            LearnModeEndScreenView(
                                topicTitle: topicTitle,
                                totalSegments: items.count,
                                currentIndex: currentScrollIndex,
                                showsProgressBar: !isRestoringPosition,
                                isLoading: viewModel.isLoading,
                                onGoDeeper: {
                                    Task { await viewModel.generateContent(learnDeeper: true) }
                                },
                                onDone: handleBack
                            )
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                    .clipShape(Rectangle())
                    .clipped()
                    .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $currentScrollID)
        .scrollClipDisabled(false)
        .scrollContentBackground(.hidden)
        .clipShape(Rectangle())
        .clipped()
        .onChange(of: viewModel.reels.map(\.id)) { _, _ in
            maxVisitedSlideIndex = 0
            isRestoringPosition = true
            applyInitialPositionIfNeeded()
            revealProgressBarAfterRestore()
            syncMaxVisitedSlideIndex()
        }
    }

    private func syncMaxVisitedSlideIndex() {
        maxVisitedSlideIndex = max(maxVisitedSlideIndex, currentScrollIndex)
    }

    private func jumpToFirstReel() {
        guard let firstID = viewModel.reels.first?.id else { return }
        HapticsFeedback.impactSoft()
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25)) {
            currentScrollID = .reel(firstID)
        }
    }

    private func applyInitialPositionIfNeeded() {
        guard !viewModel.reels.isEmpty else { return }

        let savedID = viewModel.consumePendingStartReelID()
        if let savedID, viewModel.reels.contains(where: { $0.id == savedID }) {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                currentScrollID = .reel(savedID)
            }
            return
        }

        if let sid = currentScrollID {
            switch sid {
            case let .reel(rid):
                if viewModel.reels.contains(where: { $0.id == rid }) { return }
            case .learnEnd:
                if feedIncludesLearnEnd { return }
            }
        }

        if let firstID = viewModel.reels.first?.id {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                currentScrollID = .reel(firstID)
            }
        }
    }

    private func revealProgressBarAfterRestore() {
        Task { @MainActor in
            await Task.yield()
            isRestoringPosition = false
        }
    }

    // MARK: – Loading strip (shown while streaming continues)

    private var loadingStrip: some View {
        VStack {
            ProgressView()
                .progressViewStyle(.linear)
                .tint(.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 0)
            Spacer()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityLabel("Still generating content")
    }

    // MARK: – Empty / loading state

    private var emptyState: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                    .accessibilityLabel("Loading")
                Text(viewModel.contentMode.loadingMessage)
                    .font(.headline)
                    .foregroundStyle(Config.Brand.readableSecondaryText)
            } else if let error = viewModel.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: UIIconSize.hero))
                    .foregroundStyle(.orange.opacity(0.7))
                    .accessibilityHidden(true)
                Text(error)
                    .font(.body)
                    .foregroundStyle(Config.Brand.readableSecondaryText)
                    .lineSpacing(ReadingTypography.bodyLineSpacing)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                primaryButton(title: "Retry", disabled: viewModel.isLoading) {
                    Task { await viewModel.generateContent() }
                }
                secondaryButton(title: "Back", action: handleBack)
            } else {
                Image(systemName: viewModel.contentMode.suggestedRowIconName)
                    .font(.system(size: UIIconSize.hero))
                    .foregroundStyle(viewModel.contentMode.modeAccentColor.opacity(0.85))
                    .accessibilityHidden(true)
                Text(viewModel.contentMode.emptyStateMessage)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.35))
                HStack(spacing: 14) {
                    if !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        primaryButton(title: "Retry", disabled: viewModel.isLoading) {
                            Task { await viewModel.generateContent() }
                        }
                    }
                    secondaryButton(title: "Back", action: handleBack)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func primaryButton(title: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(title, action: action)
                .buttonStyle(.glassProminent)
                .disabled(disabled)
        } else {
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
                .tint(Config.Brand.startButtonFill)
                .foregroundStyle(Config.Brand.startButtonTextColor)
                .disabled(disabled)
        }
    }

    @ViewBuilder
    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(title, action: action)
                .buttonStyle(.glass)
                .foregroundStyle(.white.opacity(0.7))
        } else {
            Button(title, action: action)
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func handleBack() {
        dismiss()
    }
}

// MARK: - Learn end screen (Learn mode only)

private struct LearnModeEndScreenView: View {
    let topicTitle: String
    let totalSegments: Int
    let currentIndex: Int
    let showsProgressBar: Bool
    let isLoading: Bool
    let onGoDeeper: () -> Void
    let onDone: () -> Void

    @State private var didEmitSuccessHaptic = false

    var body: some View {
        ZStack {
            AppScreenBackground.standard

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(Config.Brand.shortBreakColor)
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

                    Text(
                        "You can continue to learn more about this topic by going deeper."
                    )
                    .font(.system(size: ReadingTypography.bodySize))
                    .foregroundStyle(Config.Brand.readableSecondaryText)
                    .lineSpacing(ReadingTypography.bodyLineSpacing)
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Button {
                        HapticsFeedback.impactMedium()
                        onGoDeeper()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            }
                            Text(isLoading ? "Loading …" : "Go deeper")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Config.Brand.startButtonFill)
                    .foregroundStyle(Config.Brand.startButtonTextColor)
                    .disabled(isLoading)
                    .accessibilityLabel(isLoading ? "Generating deeper lesson" : "Go deeper on this topic")

                    Button("Close") {
                        HapticsFeedback.impactSoft()
                        onDone()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Config.Brand.readableSecondaryText)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close, close feed")
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, showsProgressBar ? 52 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottom) {
            ReelProgressBar(totalSegments: totalSegments, currentIndex: currentIndex)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .opacity(showsProgressBar ? 1 : 0)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            guard !didEmitSuccessHaptic else { return }
            didEmitSuccessHaptic = true
            HapticsFeedback.lessonSuccess()
        }
    }
}
