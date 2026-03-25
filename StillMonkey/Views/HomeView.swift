//
//  HomeView.swift
//  Still Monkey
//

import SwiftUI

struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: TopicViewModel
    @Bindable var courseViewModel: PathCourseViewModel

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
    var onStartSuggestion: ((String, ContentMode) -> Void)? = nil

    private var canStart: Bool {
        !(viewModel.isLoading || courseViewModel.isLoading)
            && !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var recentItemsForHome: [HomeRecentItem] {
        HomeRecentFeed.mergedItems(reels: viewModel.recentItems, courses: courseViewModel.recentCourses)
    }

    var body: some View {
        AppScreenCanvas(wash: .none) {
            ScrollView {
                VStack(alignment: .leading, spacing: HomeLayout.sectionSpacing) {
                    HomeHeroCardView()

                    if !recentItemsForHome.isEmpty {
                        HomeRecentSectionsView(
                            items: recentItemsForHome,
                            isEditingHistory: $isEditingHistory,
                            reduceMotion: reduceMotion,
                            lastAccessedReelID: viewModel.lastAccessedRecentID,
                            lastAccessedCourseID: courseViewModel.lastAccessedCourseID,
                            onOpen: openRecent,
                            onRequestDelete: requestDeleteRecent
                        )
                    }

                    SuggestedTopicsView(viewModel: suggestedViewModel) { topic, mode in
                        viewModel.contentMode = mode
                        viewModel.topic = topic
                        searchText = topic
                        if let onStartSuggestion {
                            onStartSuggestion(topic, mode)
                        } else {
                            onStartLearning?()
                        }
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
            guard viewModel.topic != newValue else { return }
            // Programmatic unfocus often clears the search field; don't wipe the topic we just started from.
            if newValue.isEmpty, !isSearchFocused.wrappedValue {
                return
            }
            if newValue.isEmpty, viewModel.isLoading || courseViewModel.isLoading {
                return
            }
            viewModel.topic = newValue
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
        .appBlendedNavigationBar()
        .preferredColorScheme(.dark)
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
        case let .path(snapshot):
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
        case let .path(snapshot):
            courseViewModel.deleteRecentCourse(snapshot)
        }

        pendingDeleteItem = nil
    }

    private func startLearning() {
        guard canStart else { return }
        HapticsFeedback.impactMedium()
        onStartLearning?()
        isSearchFocused.wrappedValue = false
    }
}

