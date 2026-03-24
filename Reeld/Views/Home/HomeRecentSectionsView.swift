//
//  HomeRecentSectionsView.swift
//  Reeld
//

import SwiftUI

struct HomeRecentSectionsView: View {
    let buckets: HomeRecentFeed.Buckets
    @Binding var isEditingHistory: Bool
    let reduceMotion: Bool
    let lastAccessedReelID: String?
    let lastAccessedCourseID: String?
    let onOpen: (HomeRecentItem) -> Void
    let onRequestDelete: (HomeRecentItem) -> Void

    private var sections: [(id: String, title: String, items: [HomeRecentItem])] {
        [
            ("today", "Recent", buckets.today),
            ("yesterday", "Yesterday", buckets.yesterday),
            ("earlier", "Earlier", buckets.earlier),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HomeLayout.groupedSectionInnerSpacing) {
            ForEach(sections, id: \.id) { section in
                groupedSection(title: section.title, items: section.items)
            }
        }
    }

    @ViewBuilder
    private func groupedSection(title: String, items: [HomeRecentItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: HomeLayout.sectionHeaderSpacing) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Config.Brand.readableTertiaryText)

                    Spacer()

                    Button(isEditingHistory ? "Done" : "Edit") {
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.2)) {
                            isEditingHistory.toggle()
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Config.Brand.readableTertiaryText)
                    .buttonStyle(.plain)
                }

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        recentRow(item, isLastSeen: isLastSeen(item))

                        if index < items.count - 1 {
                            Divider()
                                .background(.white.opacity(0.12))
                                .padding(.leading, HomeLayout.dividerLeadingInset)
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
            onTap: { onOpen(item) },
            onDelete: isEditingHistory ? { onRequestDelete(item) } : nil
        )

        if isEditingHistory {
            row
        } else {
            row
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onRequestDelete(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }

    private func isLastSeen(_ item: HomeRecentItem) -> Bool {
        switch item {
        case let .reel(snapshot):
            return snapshot.id == lastAccessedReelID
        case let .duolingo(snapshot):
            return snapshot.id == lastAccessedCourseID
        }
    }
}
