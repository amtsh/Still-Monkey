//
//  HomeView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: TopicViewModel
    @State private var searchText = ""
    @State private var isEditingHistory = false
    @State private var pendingDeleteSnapshot: RecentContentSnapshot?
    @State private var suggestedViewModel = SuggestedTopicsViewModel()
    @State private var isShowingDeleteConfirmation = false
    var isSearchFocused: FocusState<Bool>.Binding
    var onOpenSettings: (() -> Void)? = nil
    var onOpenFeed: (() -> Void)? = nil
    var onStartLearning: (() -> Void)? = nil

    private var canStart: Bool {
        !viewModel.isLoading && !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var recentItems: [RecentContentSnapshot] {
        viewModel.recentItems
    }

    private var todayItems: [RecentContentSnapshot] {
        let calendar = Calendar.current
        return recentItems.filter { calendar.isDateInToday($0.updatedAt) }
    }

    private var yesterdayItems: [RecentContentSnapshot] {
        let calendar = Calendar.current
        return recentItems.filter { calendar.isDateInYesterday($0.updatedAt) }
    }

    private var earlierItems: [RecentContentSnapshot] {
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
                pendingDeleteSnapshot = nil
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
        let sections: [(id: String, title: String, items: [RecentContentSnapshot])] = [
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
    private func groupedRecentSection(id: String, title: String, items: [RecentContentSnapshot]) -> some View {
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
                        recentRow(item, isLastSeen: item.id == viewModel.lastAccessedRecentID)

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
    private func recentRow(_ item: RecentContentSnapshot, isLastSeen: Bool) -> some View {
        let iconName = item.mode == .story ? "moon.zzz" : "book"
        let row = SearchRowView(
            iconName: iconName,
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

    private func openRecent(_ snapshot: RecentContentSnapshot) {
        HapticsFeedback.impactSoft()
        viewModel.loadRecentSnapshot(snapshot)
        onOpenFeed?()
    }

    private func requestDeleteRecent(_ snapshot: RecentContentSnapshot) {
        pendingDeleteSnapshot = snapshot
        isShowingDeleteConfirmation = true
    }

    private func confirmDeleteRecent() {
        guard let snapshot = pendingDeleteSnapshot else { return }
        viewModel.deleteRecentSnapshot(snapshot)
        pendingDeleteSnapshot = nil
    }

    private func startLearning() {
        guard canStart else { return }
        isSearchFocused.wrappedValue = false
        HapticsFeedback.impactMedium()
        onStartLearning?()
    }
}
