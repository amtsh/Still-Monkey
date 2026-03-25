//
//  SearchRowView.swift
//  Reeld
//

import SwiftUI

struct SearchRowView: View {
    let iconName: String
    let title: String
    var trailingLabel: String? = nil
    /// When set, icon uses this color; otherwise `longBreakColor` (neutral rows).
    var iconForeground: Color? = nil
    /// When set, trailing label uses a compact accent pill (same metrics as neutral “Last seen”).
    var trailingPillAccent: Color? = nil
    /// When true, omits the leading icon (Suggested rows with trailing mode pill only).
    var leadingIconHidden: Bool = false
    var isEditing: Bool = false
    var onTap: () -> Void
    var onDelete: (() -> Void)? = nil

    private var resolvedIconColor: Color {
        iconForeground ?? Config.Brand.longBreakColor
    }

    var body: some View {
        Group {
            if isEditing {
                editingRow
            } else {
                tappableRow
            }
        }
    }

    private var tappableRow: some View {
        Button {
            onTap()
        } label: {
            rowContent(showChevron: true)
        }
        .buttonStyle(.plain)
    }

    private var editingRow: some View {
        HStack(spacing: HomeLayout.listRowIconTitleSpacing) {
            if !leadingIconHidden {
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(resolvedIconColor.opacity(0.88))
                    .frame(width: HomeLayout.listRowLeadingIconWidth, alignment: .center)
            }

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)

            Spacer()

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
                .frame(minWidth: UITouchTarget.minimum, minHeight: UITouchTarget.minimum)
            }
        }
        .padding(.vertical, HomeLayout.listRowVerticalPadding)
        .frame(minHeight: HomeLayout.listRowMinHeight, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rowContent(showChevron: Bool) -> some View {
        HStack(spacing: HomeLayout.listRowIconTitleSpacing) {
            if !leadingIconHidden {
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(resolvedIconColor.opacity(0.88))
                    .frame(width: HomeLayout.listRowLeadingIconWidth, alignment: .center)
            }

            Text(title)
                .font(.body)
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)

            Spacer()

            if showChevron, let label = trailingLabel {
                HStack(spacing: HomeLayout.trailingPillChevronSpacing) {
                    if let accent = trailingPillAccent {
                        compactAccentPill(text: label, accent: accent)
                    } else {
                        neutralLastSeenPill(text: label)
                    }
                    trailingChevronImage
                }
            } else if let label = trailingLabel {
                if let accent = trailingPillAccent {
                    compactAccentPill(text: label, accent: accent)
                } else {
                    neutralLastSeenPill(text: label)
                }
            }
        }
        .padding(.vertical, HomeLayout.listRowVerticalPadding)
        .frame(minHeight: HomeLayout.listRowMinHeight, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trailingChevronImage: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.28))
            .frame(width: 20, alignment: .center)
    }

    private func neutralLastSeenPill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Config.Brand.readableSecondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(
                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    /// Same font and padding as neutral “Last seen”, with mode accent fill and stroke.
    private func compactAccentPill(text: String, accent: Color) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(accent.opacity(0.22))
            )
            .overlay(
                Capsule()
                    .stroke(accent.opacity(0.55), lineWidth: 1)
            )
    }
}
