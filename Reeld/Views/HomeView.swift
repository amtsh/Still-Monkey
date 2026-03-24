//
//  HomeView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: TopicViewModel
    @Bindable var courseViewModel: DuolingoCourseViewModel

    @State private var searchText = ""
    @State private var isEditingHistory = false
    @State private var pendingDeleteItem: HomeRecentItem?
    @State private var suggestedViewModel = SuggestedTopicsViewModel()
    @State private var isShowingDeleteConfirmation = false
    var isSearchFocused: FocusState<Bool>.Binding
    var onOpenSettings: (() -> Void)? = nil
    var onOpenFeed: (() -> Void)? = nil
    var onOpenCourseMap: (() -> Void)? = nil
    var onStartLearning: (() -> Void)? = nil

    private var canStart: Bool {
        !(viewModel.isLoading || courseViewModel.isLoading)
            && !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var mergedRecentItems: [HomeRecentItem] {
        HomeRecentFeed.mergedItems(reels: viewModel.recentItems, courses: courseViewModel.recentCourses)
    }

    private var recentBuckets: HomeRecentFeed.Buckets {
        HomeRecentFeed.Buckets.partition(mergedRecentItems)
    }

    var body: some View {
        ZStack {
            ReeldScreenBackground.standard
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: HomeLayout.sectionSpacing) {
                    HomeHeroCardView()

                    if mergedRecentItems.isEmpty {
                        emptyRecentHint
                    }

                    if !mergedRecentItems.isEmpty {
                        HomeRecentSectionsView(
                            buckets: recentBuckets,
                            isEditingHistory: $isEditingHistory,
                            reduceMotion: reduceMotion,
                            lastAccessedReelID: viewModel.lastAccessedRecentID,
                            lastAccessedCourseID: courseViewModel.lastAccessedCourseID,
                            onOpen: openRecent,
                            onRequestDelete: requestDeleteRecent
                        )
                    }

                    SuggestedTopicsView(viewModel: suggestedViewModel) { topic in
                        viewModel.contentMode = .learn
                        viewModel.topic = topic
                        searchText = topic
                        onStartLearning?()
                    }
                }
                .padding(.horizontal, HomeLayout.scrollHorizontalPadding)
                .padding(.top, HomeLayout.scrollTopPadding)
                .padding(.bottom, HomeLayout.scrollBottomPadding)
            }
            .scrollDisabled(isSearchFocused.wrappedValue)

            if isSearchFocused.wrappedValue {
                searchFocusOverlay
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.22), value: isSearchFocused.wrappedValue)
        .navigationTitle("Still Monkey")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: viewModel.contentMode.composerPlaceholder)
        .searchFocused(isSearchFocused)
        .onChange(of: searchText) { _, newValue in
            if viewModel.topic != newValue {
                viewModel.topic = newValue
            }
        }
        .onSubmit(of: .search) {
            startLearning()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticsFeedback.impactSoft()
                    onOpenSettings?()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: UIIconSize.navAction, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
        .alert("Remove from recent?", isPresented: $isShowingDeleteConfirmation) {
            Button("Remove", role: .destructive) {
                confirmDeleteRecent()
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteItem = nil
            }
        } message: {
            if let item = pendingDeleteItem {
                Text("“\(item.displayTopic)” will be removed from this device. You can’t undo this.")
            } else {
                Text("This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyRecentHint: some View {
        Text("Your recent topics will appear here after you learn or open a path.")
            .font(.subheadline)
            .foregroundStyle(Config.Brand.readableTertiaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Your recent topics will appear here after you learn or open a path.")
    }

    private var searchFocusOverlay: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.38))
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused.wrappedValue = false
            }
            .transition(.opacity)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Dismiss search")
    }

    private func openRecent(_ item: HomeRecentItem) {
        HapticsFeedback.impactSoft()

        switch item {
        case let .reel(snapshot):
            viewModel.contentMode = snapshot.mode
            viewModel.loadRecentSnapshot(snapshot)
            searchText = snapshot.topic
            onOpenFeed?()
        case let .duolingo(snapshot):
            viewModel.contentMode = .path
            viewModel.topic = snapshot.topic
            searchText = snapshot.topic
            courseViewModel.loadRecentCourse(snapshot)
            onOpenCourseMap?()
        }
    }

    private func requestDeleteRecent(_ item: HomeRecentItem) {
        pendingDeleteItem = item
        isShowingDeleteConfirmation = true
    }

    private func confirmDeleteRecent() {
        guard let item = pendingDeleteItem else { return }

        switch item {
        case let .reel(snapshot):
            viewModel.deleteRecentSnapshot(snapshot)
        case let .duolingo(snapshot):
            courseViewModel.deleteRecentCourse(snapshot)
        }

        pendingDeleteItem = nil
    }

    private func startLearning() {
        guard canStart else { return }
        isSearchFocused.wrappedValue = false
        HapticsFeedback.impactMedium()
        onStartLearning?()
    }
}
