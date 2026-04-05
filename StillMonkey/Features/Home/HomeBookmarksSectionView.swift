//
//  HomeBookmarksSectionView.swift
//  Still Monkey
//

import SwiftUI

struct HomeBookmarksSectionView: View {
    let entries: [BookmarkEntry]
    let onOpen: (BookmarkEntry) -> Void
    let onRemove: (BookmarkEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HomeLayout.sectionHeaderSpacing) {
            Text("Bookmarks")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    bookmarkRow(entry)

                    if index < entries.count - 1 {
                        Divider()
                            .background(.white.opacity(0.12))
                            .padding(.leading, HomeLayout.homeRowDividerLeadingInset)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ entry: BookmarkEntry) -> some View {
        Button {
            HapticsFeedback.impactSoft()
            onOpen(entry)
        } label: {
            HStack(alignment: .center, spacing: HomeLayout.listRowIconTitleSpacing) {
                ZStack {
                    RoundedRectangle(cornerRadius: HomeLayout.homeRowAvatarCornerRadius, style: .continuous)
                        .fill(Config.Brand.listIconWellFill)
                    RoundedRectangle(cornerRadius: HomeLayout.homeRowAvatarCornerRadius, style: .continuous)
                        .strokeBorder(Config.Brand.listIconWellStroke, lineWidth: 1)
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(ReadingNavigationChrome.toolbarBookmarkFilledOpacity))
                }
                .frame(width: HomeLayout.homeRowAvatarSize, height: HomeLayout.homeRowAvatarSize)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(entry.displaySubtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: HomeLayout.trailingPillChevronSpacing) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.28))
                        .frame(width: 20, alignment: .center)
                }
            }
            .padding(.vertical, HomeLayout.listRowVerticalPadding)
            .frame(minHeight: HomeLayout.listRowMinHeight, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRemove(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(entry.displayTitle), \(entry.displaySubtitle)")
    }
}
