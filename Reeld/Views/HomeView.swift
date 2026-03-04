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

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                    if !recentItems.isEmpty {
                        recentItemsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Reeld")
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
        .preferredColorScheme(.dark)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Heal from doomscrolling")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .minimumScaleFactor(0.85)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.63, blue: 0.71),
                            Color(red: 0.83, green: 0.56, blue: 1.00),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Build better attention with bite-sized microlearning reels.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .glassCard(cornerRadius: 24)
    }

    private var recentItemsSection: some View {
        let sections: [(id: String, title: String, items: [RecentContentSnapshot])] = [
            ("today", "History", todayItems),
            ("yesterday", "Yesterday", yesterdayItems),
            ("earlier", "Earlier", earlierItems),
        ]

        return VStack(alignment: .leading, spacing: 16) {
            ForEach(sections, id: \.id) { section in
                groupedRecentSection(title: section.title, items: section.items)
            }
        }
    }

    @ViewBuilder
    private func groupedRecentSection(title: String, items: [RecentContentSnapshot]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        recentRow(item, isLastSeen: item.id == viewModel.lastAccessedRecentID)

                        if index < items.count - 1 {
                            Divider()
                                .background(.white.opacity(0.12))
                                .padding(.leading, 50)
                        }
                    }
                }
                .glassCard(cornerRadius: 14)
            }
        }
    }

    private func recentRow(_ item: RecentContentSnapshot, isLastSeen: Bool) -> some View {
        Button {
            openRecent(item)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbolName(for: item.displayTopic))
                    .font(.system(size: 20, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(symbolColor(for: item.displayTopic))
                    .frame(width: 24)

                Text(item.displayTopic)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)

                Spacer()

                if isLastSeen {
                    Text("Last seen")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.58))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.28))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func openRecent(_ snapshot: RecentContentSnapshot) {
        HapticsFeedback.impactSoft()
        viewModel.loadRecentSnapshot(snapshot)
        onOpenFeed?()
    }

    private func startLearning() {
        guard canStart else { return }
        isSearchFocused.wrappedValue = false
        HapticsFeedback.impactMedium()
        onStartLearning?()
    }

    private func symbolName(for title: String) -> String {
        let key = title.lowercased()

        if key.contains("ai") || key.contains("ml") || key.contains("model") || key.contains("neural") {
            return "cpu"
        }
        if key.contains("code") || key.contains("program") || key.contains("swift") || key.contains("dev") {
            return "chevron.left.forwardslash.chevron.right"
        }
        if key.contains("design") || key.contains("ui") || key.contains("ux") {
            return "paintpalette"
        }
        if key.contains("finance") || key.contains("money") || key.contains("invest") || key.contains("stock") {
            return "dollarsign.circle"
        }
        if key.contains("health") || key.contains("fitness") || key.contains("wellness") {
            return "heart.text.square"
        }
        if key.contains("history") || key.contains("culture") || key.contains("society") {
            return "book.closed"
        }
        if key.contains("science") || key.contains("physics") || key.contains("chem") || key.contains("bio") {
            return "atom"
        }
        if key.contains("space") || key.contains("astronomy") {
            return "moon.stars"
        }
        if key.contains("business") || key.contains("strategy") || key.contains("startup") {
            return "briefcase"
        }
        if key.contains("music") || key.contains("song") {
            return "music.note"
        }
        if key.contains("art") || key.contains("photo") {
            return "photo"
        }

        return "sparkles"
    }

    private func symbolColor(for title: String) -> Color {
        let key = title.lowercased()

        if key.contains("ai") || key.contains("ml") || key.contains("model") || key.contains("neural") {
            return .cyan
        }
        if key.contains("code") || key.contains("program") || key.contains("swift") || key.contains("dev") {
            return .blue
        }
        if key.contains("design") || key.contains("ui") || key.contains("ux") {
            return .mint
        }
        if key.contains("finance") || key.contains("money") || key.contains("invest") || key.contains("stock") {
            return .green
        }
        if key.contains("health") || key.contains("fitness") || key.contains("wellness") {
            return .pink
        }
        if key.contains("history") || key.contains("culture") || key.contains("society") {
            return .orange
        }
        if key.contains("science") || key.contains("physics") || key.contains("chem") || key.contains("bio") {
            return .purple
        }
        if key.contains("space") || key.contains("astronomy") {
            return .indigo
        }
        if key.contains("business") || key.contains("strategy") || key.contains("startup") {
            return .teal
        }
        if key.contains("music") || key.contains("song") {
            return .yellow
        }
        if key.contains("art") || key.contains("photo") {
            return .red
        }

        return .cyan
    }
}
