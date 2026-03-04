//
//  HomeView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: TopicViewModel
    var onOpenSettings: (() -> Void)? = nil
    var onOpenFeed: (() -> Void)? = nil

    private var recentItems: [RecentContentSnapshot] {
        Array(viewModel.recentItems.prefix(10))
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
        .safeAreaInset(edge: .top) {
            topHeader
        }
        .preferredColorScheme(.dark)
    }

    private var topHeader: some View {
        HStack {
            Text("Reeld")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onOpenSettings?()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(.black.opacity(0.94))
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
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        )
    }

    private var recentItemsSection: some View {
        let sections: [(id: String, title: String, items: [RecentContentSnapshot])] = [
            ("today", "Today", todayItems),
            ("yesterday", "Yesterday", yesterdayItems),
            ("earlier", "Earlier", earlierItems),
        ]

      return VStack(alignment: .leading, spacing: 14) {
            ForEach(sections, id: \.id) { section in
                groupedRecentSection(title: section.title, items: section.items)
            }
        }
    }

    @ViewBuilder
    private func groupedRecentSection(title: String, items: [RecentContentSnapshot]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        recentRow(item, isLastSeen: item.id == recentItems.first?.id)

                        if index < items.count - 1 {
                            Divider().background(.white.opacity(0.08))
                        }
                    }
                }
                .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    private func recentRow(_ item: RecentContentSnapshot, isLastSeen: Bool) -> some View {
        Button {
            openRecent(item)
        } label: {
            HStack(spacing: 10) {
                Text(item.displayTopic)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)

                Spacer()

                if isLastSeen {
                    Text("Last seen")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.1), in: Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func openRecent(_ snapshot: RecentContentSnapshot) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        viewModel.loadRecentSnapshot(snapshot)
        onOpenFeed?()
    }
}
