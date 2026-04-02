//
//  ReelsView.swift
//  Still Monkey
//

import SwiftUI

struct ReelsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: TopicViewModel
    @State private var currentID: Reel.ID?
    @State private var hasShownSwipeHint = false
    @State private var isRestoringPosition = true
    /// Furthest slide index reached this session; used to show “jump to first” only after the user has swiped back from a later slide.
    @State private var maxVisitedSlideIndex: Int = 0

    private var topicTitle: String {
        let rawTitle = viewModel.topic.isEmpty ? viewModel.contentMode.defaultFeedTitle : viewModel.topic
        return rawTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
    }

    private var currentIndex: Int {
        guard let id = currentID else { return 0 }
        return viewModel.reels.firstIndex(where: { $0.id == id }) ?? 0
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
                if currentIndex == 0 {
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
                } else if maxVisitedSlideIndex > currentIndex {
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
        .onChange(of: currentID) { _, newValue in
            viewModel.recordCurrentReelID(newValue)
            if isRestoringPosition, newValue != nil {
                isRestoringPosition = false
            }
            syncMaxVisitedSlideIndex()
        }
    }

    // MARK: – Feed

    private var reelsFeed: some View {
        let reels = viewModel.reels
        let chapterTitlesByIndex = viewModel.chapterTitlesByIndex

      return ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(reels.enumerated()), id: \.element.id) { offset, reel in
                    ZStack {
                        ReelCardView(
                            reel: reel,
                            currentIndex: currentIndex,
                            cardIndex: offset,
                            totalCount: reels.count,
                            chapterTitle: chapterTitlesByIndex[reel.chapterIndex],
                            topicTitle: topicTitle,
                            showsProgressBar: !isRestoringPosition
                        )

                        if offset == 0 && !hasShownSwipeHint && reels.count > 1 {
                            SwipeHintOverlay()
                                .onAppear { hasShownSwipeHint = true }
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                    .clipShape(Rectangle())
                    .clipped()
                    .id(reel.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $currentID)
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
        maxVisitedSlideIndex = max(maxVisitedSlideIndex, currentIndex)
    }

    private func jumpToFirstReel() {
        guard let firstID = viewModel.reels.first?.id else { return }
        HapticsFeedback.impactSoft()
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25)) {
            currentID = firstID
        }
    }

    private func applyInitialPositionIfNeeded() {
        guard !viewModel.reels.isEmpty else { return }

        let savedID = viewModel.consumePendingStartReelID()
        if let savedID, viewModel.reels.contains(where: { $0.id == savedID }) {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                currentID = savedID
            }
            return
        }

        if let currentID, viewModel.reels.contains(where: { $0.id == currentID }) {
            return
        }

        if let firstID = viewModel.reels.first?.id {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                currentID = firstID
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
