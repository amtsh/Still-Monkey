//
//  HomeRecentSectionsView.swift
//  Still Monkey
//

import SwiftUI

struct HomeRecentSectionsView: View {
    let items: [HomeRecentItem]
    @Binding var isEditingHistory: Bool
    let reduceMotion: Bool
    let lastAccessedReelID: String?
    let lastAccessedCourseID: String?
    let onOpen: (HomeRecentItem) -> Void
    let onRequestDelete: (HomeRecentItem) -> Void

    /// Show "Last seen" on a single row only (the first matching recent item).
    private var lastSeenItemID: HomeRecentItem.ID? {
        items.first(where: isLastSeenCandidate)?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HomeLayout.sectionHeaderSpacing) {
            HStack(spacing: 12) {
                Text("Recent")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button(isEditingHistory ? "Done" : "Edit") {
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.2)) {
                        isEditingHistory.toggle()
                    }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Config.Brand.readableSecondaryText)
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    recentRow(item, isLastSeen: item.id == lastSeenItemID)

                    if index < items.count - 1 {
                        Divider()
                            .background(.white.opacity(0.12))
                            .padding(.leading, HomeLayout.homeRowDividerLeadingInset)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func recentRow(_ item: HomeRecentItem, isLastSeen: Bool) -> some View {
        if isEditingHistory {
            editingRow(item)
        } else {
            Button {
                HapticsFeedback.impactSoft()
                onOpen(item)
            } label: {
                rowLabel(item, isLastSeen: isLastSeen)
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onRequestDelete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func editingRow(_ item: HomeRecentItem) -> some View {
        HStack(spacing: HomeLayout.listRowIconTitleSpacing) {
            RecentRowLeadingIcon(systemImageName: item.modeSystemImageName, accent: item.contentMode.modeAccentColor)

            Text(item.displayTopic)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(item.modeLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(Config.Brand.readableSecondaryText)

            Button(role: .destructive) {
                onRequestDelete(item)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.plain)
            .frame(minWidth: UITouchTarget.minimum, minHeight: UITouchTarget.minimum)
        }
        .frame(minHeight: UITouchTarget.minimum, alignment: .center)
        .padding(.vertical, HomeLayout.listRowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("\(item.displayTopic), \(item.modeLabel)")
    }

    private func rowLabel(_ item: HomeRecentItem, isLastSeen: Bool) -> some View {
        HStack(alignment: .center, spacing: HomeLayout.listRowIconTitleSpacing) {
            RecentRowLeadingIcon(systemImageName: item.modeSystemImageName, accent: item.contentMode.modeAccentColor)

            VStack(alignment: .leading, spacing: 4) {
                if isLastSeen {
                    Text("Last seen")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Config.Brand.focusColor)
                }

                Text(item.displayTopic)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: HomeLayout.trailingPillChevronSpacing) {
                Text(item.modeLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Config.Brand.readableSecondaryText)

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
        .accessibilityLabel("\(item.displayTopic), \(item.modeLabel)")
    }

    private func isLastSeenCandidate(_ item: HomeRecentItem) -> Bool {
        switch item {
        case let .reel(snapshot):
            return snapshot.id == lastAccessedReelID
        case let .path(snapshot):
            return snapshot.id == lastAccessedCourseID
        }
    }
}

// MARK: - Neutral icon well (accent on symbol only)

private struct RecentRowLeadingIcon: View {
    let systemImageName: String
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: HomeLayout.homeRowAvatarCornerRadius, style: .continuous)
                .fill(Config.Brand.listIconWellFill)
            RoundedRectangle(cornerRadius: HomeLayout.homeRowAvatarCornerRadius, style: .continuous)
                .strokeBorder(Config.Brand.listIconWellStroke, lineWidth: 1)
            Image(systemName: systemImageName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
        }
        .frame(width: HomeLayout.homeRowAvatarSize, height: HomeLayout.homeRowAvatarSize)
        .accessibilityHidden(true)
    }
}
