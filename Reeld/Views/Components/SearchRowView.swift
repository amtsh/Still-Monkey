//
//  SearchRowView.swift
//  Reeld
//

import SwiftUI

struct SearchRowView: View {
    let iconName: String
    let title: String
    var trailingLabel: String? = nil
    var isEditing: Bool = false
    var onTap: () -> Void
    var onDelete: (() -> Void)? = nil

    private let iconColor = Color(red: 0.72, green: 0.78, blue: 0.96)

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
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(iconColor.opacity(0.88))
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)

            Spacer()

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func rowContent(showChevron: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(iconColor.opacity(0.88))
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)

            Spacer()

            if let trailingLabel {
                Text(trailingLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        Color(red: 231 / 255, green: 208 / 255, blue: 214 / 255)
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(
                        Capsule().stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.28))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
