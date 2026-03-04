//
//  ReelsView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct ReelsView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TopicViewModel
    @State private var currentID: Reel.ID?
    @State private var hasShownSwipeHint = false

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
            Color.black.ignoresSafeArea()

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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.reels.isEmpty)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            applyInitialPositionIfNeeded()
        }
        .onChange(of: currentID) { oldValue, newValue in
            viewModel.recordCurrentReelID(newValue)
            guard oldValue != nil, newValue != oldValue else { return }
            HapticsFeedback.impactSoft()
        }
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
                            topicTitle: topicTitle
                        )

                        if offset == 0 && !hasShownSwipeHint && viewModel.reels.count > 1 {
                            SwipeHintOverlay()
                                .onAppear { hasShownSwipeHint = true }
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
            applyInitialPositionIfNeeded()
        }
    }

    private func applyInitialPositionIfNeeded() {
        guard !viewModel.reels.isEmpty else { return }

        if let currentID, viewModel.reels.contains(where: { $0.id == currentID }) {
            return
        }

        let savedID = viewModel.consumePendingStartReelID()
        if let savedID, viewModel.reels.contains(where: { $0.id == savedID }) {
            currentID = savedID
        } else {
            currentID = viewModel.reels.first?.id
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
    }

    // MARK: – Empty / loading state

    private var emptyState: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                Text(viewModel.contentMode.loadingMessage)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.55))
            } else if let error = viewModel.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: UIIconSize.hero))
                    .foregroundStyle(.orange.opacity(0.7))
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                primaryButton(title: "Retry", disabled: viewModel.isLoading) {
                    Task { await viewModel.generateContent() }
                }
                secondaryButton(title: "Back", action: handleBack)
            } else {
                Image(systemName: viewModel.contentMode == .story ? "book.pages.fill" : "play.rectangle.fill")
                    .font(.system(size: UIIconSize.hero))
                    .foregroundStyle(.white.opacity(0.15))
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
                .tint(.white)
                .foregroundStyle(.black)
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
