//
//  ReelsView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct ReelsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: TopicViewModel
    @State private var currentID: Reel.ID?
    @State private var hasShownSwipeHint = false
    @State private var isRestoringPosition = true
    @State private var isZenMode = false

    private var topicTitle: String {
        let rawTitle = viewModel.topic.isEmpty ? viewModel.contentMode.defaultFeedTitle : viewModel.topic
        return rawTitle.trimmingCharacters(in: .whitespacesAndNewlines).localizedCapitalized
    }

    private var currentIndex: Int {
        guard let id = currentID else { return 0 }
        return viewModel.reels.firstIndex(where: { $0.id == id }) ?? 0
    }

    var body: some View {
        ZStack {
            ReeldScreenBackground.standard
                .ignoresSafeArea()

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

            if !viewModel.reels.isEmpty {
                aiAttribution
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .allowsHitTesting(false)
            }
        }
        .animation(reduceMotion ? .default : .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.reels.isEmpty)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isZenMode ? .hidden : .automatic, for: .navigationBar)
        .onDisappear {
            isZenMode = false
        }
        .onAppear {
            isRestoringPosition = true
            applyInitialPositionIfNeeded()
            revealProgressBarAfterRestore()
        }
        .onChange(of: currentID) { _, newValue in
            viewModel.recordCurrentReelID(newValue)
            if isRestoringPosition, newValue != nil {
                isRestoringPosition = false
            }
        }
    }

    private var aiAttribution: some View {
        Text("Generated for learning — verify important facts.")
            .font(.caption2)
            .foregroundStyle(Config.Brand.readableTertiaryText)
            .multilineTextAlignment(.center)
            .accessibilityLabel("AI-generated content. Verify important facts.")
    }

    // MARK: – Feed

    private var reelsFeed: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.reels.enumerated()), id: \.element.id) { offset, reel in
                    ZStack {
                        ReelCardView(
                            reel: reel,
                            currentIndex: currentIndex,
                            cardIndex: offset,
                            totalCount: viewModel.reels.count,
                            chapterTitle: viewModel.chapterTitlesByIndex[reel.chapterIndex],
                            topicTitle: topicTitle,
                            showsProgressBar: !isRestoringPosition,
                            zenModeDimProgress: isZenMode
                        )

                        if offset == 0 && !hasShownSwipeHint && viewModel.reels.count > 1 {
                            SwipeHintOverlay()
                                .onAppear { hasShownSwipeHint = true }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticsFeedback.impactSoft()
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.25)) {
                            isZenMode.toggle()
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                    .id(reel.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $currentID)
        .onChange(of: viewModel.reels.map(\.id)) { _, _ in
            isRestoringPosition = true
            applyInitialPositionIfNeeded()
            revealProgressBarAfterRestore()
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
                Image(systemName: viewModel.contentMode == .story ? "book.pages.fill" : "play.rectangle.fill")
                    .font(.system(size: UIIconSize.hero))
                    .foregroundStyle(.white.opacity(0.15))
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
