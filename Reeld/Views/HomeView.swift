//
//  HomeView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: TopicViewModel
    @Bindable var courseViewModel: DuolingoCourseViewModel

    private enum HomeRecentItem: Identifiable {
        case reel(RecentContentSnapshot)
        case duolingo(DuolingoCourseSnapshot)

        var id: String {
            switch self {
            case .reel(let snapshot):
                return snapshot.id
            case .duolingo(let snapshot):
                return snapshot.id
            }
        }

        var updatedAt: Date {
            switch self {
            case .reel(let snapshot):
                return snapshot.updatedAt
            case .duolingo(let snapshot):
                return snapshot.updatedAt
            }
        }

        var displayTopic: String {
            switch self {
            case .reel(let snapshot):
                return snapshot.displayTopic
            case .duolingo(let snapshot):
                return snapshot.displayTopic
            }
        }

        var iconName: String {
            switch self {
            case .reel(let snapshot):
                return snapshot.mode == .story ? "moon.zzz" : "book"
            case .duolingo:
                return "point.3.connected.trianglepath.dotted"
            }
        }
    }

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

    private var recentItems: [HomeRecentItem] {
        (viewModel.recentItems.map(HomeRecentItem.reel) + courseViewModel.recentCourses.map(HomeRecentItem.duolingo))
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    private var todayItems: [HomeRecentItem] {
        let calendar = Calendar.current
        return recentItems.filter { calendar.isDateInToday($0.updatedAt) }
    }

    private var yesterdayItems: [HomeRecentItem] {
        let calendar = Calendar.current
        return recentItems.filter { calendar.isDateInYesterday($0.updatedAt) }
    }

    private var earlierItems: [HomeRecentItem] {
        let calendar = Calendar.current
        return recentItems.filter { !calendar.isDateInToday($0.updatedAt) && !calendar.isDateInYesterday($0.updatedAt) }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.75, blue: 0.80).opacity(0.24),
                    .clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxHeight: 260)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                    if !recentItems.isEmpty {
                        recentItemsSection
                    }
                    SuggestedTopicsView(viewModel: suggestedViewModel) { topic in
                        viewModel.topic = topic
                        searchText = topic
                        onStartLearning?()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
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
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
        .alert("Delete this item?", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                confirmDeleteRecent()
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteItem = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .preferredColorScheme(.dark)
    }

    private var heroCard: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - 40, 0)
            let leftWidth = contentWidth * 0.7
            let rightWidth = contentWidth * 0.3

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Feed your curiosity.")
                        .font(.system(size: 24, weight: .semibold))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.85, blue: 0.70),
                                    Color(red: 1.00, green: 0.75, blue: 0.50),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Learn something real.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineSpacing(2)
                }
                .frame(width: leftWidth, alignment: .leading)

                LottieView(name: "flower_plant", speed: 0.9)
                    .frame(width: rightWidth, height: proxy.size.height - 40)
                    .opacity(0.95)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .frame(height: 210)
        .glassCard(cornerRadius: 24)
    }

    private var recentItemsSection: some View {
        let sections: [(id: String, title: String, items: [HomeRecentItem])] = [
            ("today", "Recent", todayItems),
            ("yesterday", "Yesterday", yesterdayItems),
            ("earlier", "Earlier", earlierItems),
        ]

        return VStack(alignment: .leading, spacing: 16) {
            ForEach(sections, id: \.id) { section in
                groupedRecentSection(id: section.id, title: section.title, items: section.items)
            }
        }
    }

    @ViewBuilder
    private func groupedRecentSection(id _: String, title: String, items: [HomeRecentItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))

                    Spacer()

                    Button(isEditingHistory ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditingHistory.toggle()
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        recentRow(item, isLastSeen: isLastSeen(item))

                        if index < items.count - 1 {
                            Divider()
                                .background(.white.opacity(0.12))
                                .padding(.leading, 42)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func recentRow(_ item: HomeRecentItem, isLastSeen: Bool) -> some View {
        let row = SearchRowView(
            iconName: item.iconName,
            title: item.displayTopic,
            trailingLabel: isLastSeen ? "Last seen" : nil,
            isEditing: isEditingHistory,
            onTap: { openRecent(item) },
            onDelete: isEditingHistory ? { requestDeleteRecent(item) } : nil
        )

        if isEditingHistory {
            row
        } else {
            row
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        requestDeleteRecent(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }

    private func openRecent(_ item: HomeRecentItem) {
        HapticsFeedback.impactSoft()

        switch item {
        case .reel(let snapshot):
            viewModel.contentMode = snapshot.mode
            viewModel.loadRecentSnapshot(snapshot)
            searchText = snapshot.topic
            onOpenFeed?()
        case .duolingo(let snapshot):
            viewModel.contentMode = .duolingo
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
        case .reel(let snapshot):
            viewModel.deleteRecentSnapshot(snapshot)
        case .duolingo(let snapshot):
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

    private func isLastSeen(_ item: HomeRecentItem) -> Bool {
        switch item {
        case .reel(let snapshot):
            return snapshot.id == viewModel.lastAccessedRecentID
        case .duolingo(let snapshot):
            return snapshot.id == courseViewModel.lastAccessedCourseID
        }
    }
}
