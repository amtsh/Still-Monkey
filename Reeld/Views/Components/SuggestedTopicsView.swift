//
//  SuggestedTopicsView.swift
//  Reeld
//

import SwiftUI

struct SuggestedTopicsView: View {
    @Bindable var viewModel: SuggestedTopicsViewModel
    var onSelectTopic: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("Suggested")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Config.Brand.readableTertiaryText)

                Spacer()

                Button {
                    HapticsFeedback.impactSoft()
                    Task { await viewModel.fetchTrendingTopics() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Config.Brand.readableTertiaryText)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Reload suggestions")
            }

            if viewModel.showCachedTopicsNotice, !viewModel.isLoading {
                Text("Showing saved topics. Connect to refresh when you’re online.")
                    .font(.caption)
                    .foregroundStyle(Config.Brand.readableTertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Showing saved topics from last successful refresh.")
            }

            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.error {
            errorView(message: error)
        } else if !viewModel.topics.isEmpty {
            topicsRowsView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 5, id: \.self) { index in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.12))
                        .frame(width: 16, height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.12))
                        .frame(height: 12)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.12))
                        .frame(width: 14, height: 12)
                }
                .padding(.vertical, 8)
                .frame(minHeight: 40)

                if index < 4 {
                    Divider()
                        .background(.white.opacity(0.12))
                        .padding(.leading, 30)
                }
            }
        }
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.body)
                .lineSpacing(ReadingTypography.bodyLineSpacing)
                .foregroundStyle(.white.opacity(0.7))

            Button("Retry") {
                Task { await viewModel.fetchTrendingTopics() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 14)
    }

    private var topicsRowsView: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.topics.enumerated()), id: \.element) { index, topic in
                topicRow(topic)

                if index < viewModel.topics.count - 1 {
                    Divider()
                        .background(.white.opacity(0.12))
                        .padding(.leading, 30)
                }
            }
        }
    }

    private func topicRow(_ topic: String) -> some View {
        SearchRowView(iconName: "magnifyingglass", title: topic) {
            HapticsFeedback.impactSoft()
            onSelectTopic(topic)
        }
    }
}
