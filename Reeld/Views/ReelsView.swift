//
//  ReelsView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI
import UIKit

struct ReelsView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TopicViewModel
    var onBack: (() -> Void)? = nil
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
        .safeAreaInset(edge: .top) {
            topOverlay
        }
        .onChange(of: currentID) { oldValue, newValue in
            guard oldValue != nil, newValue != oldValue else { return }
            HapticsFeedback.impactSoft()
        }
        .background(InteractivePopGestureEnabler())
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
        .ignoresSafeArea()
        .onChange(of: viewModel.reels.count) { _, _ in
            if currentID == nil {
                currentID = viewModel.reels.first?.id
            }
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
                    .font(.system(size: 46))
                    .foregroundStyle(.orange.opacity(0.7))
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button("Retry") {
                    Task {
                        await viewModel.generateContent()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(viewModel.isLoading)
                Button("Back") {
                    handleBack()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
            } else {
                Image(systemName: viewModel.contentMode == .story ? "book.pages.fill" : "play.rectangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.15))
                Text(viewModel.contentMode.emptyStateMessage)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.35))
                HStack(spacing: 14) {
                    if !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("Retry") {
                            Task {
                                await viewModel.generateContent()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(.black)
                        .disabled(viewModel.isLoading)
                    }
                    Button("Back") {
                        handleBack()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var topOverlay: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    handleBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.55), .black.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PopGestureViewController {
        PopGestureViewController()
    }

    func updateUIViewController(_ uiViewController: PopGestureViewController, context: Context) {}
}

private final class PopGestureViewController: UIViewController, UIGestureRecognizerDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let navigationController else { return }
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}
