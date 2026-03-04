//
//  HomeView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: TopicViewModel
    var onOpenFeed: (() -> Void)? = nil
    @FocusState private var isTextFieldFocused: Bool

    private var canStart: Bool {
        !viewModel.isLoading && !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                    recentItemsSection
                    bottomComposer
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
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(.black.opacity(0.94))
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start Here")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                Text("Heal from\ndoomscrolling")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
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

                Text("... with microlearning")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        )
    }

    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            if recentItems.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No recent topics yet. Generate one to see it here.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
            } else {
                groupedRecentSection(title: "Today", items: todayItems)
                groupedRecentSection(title: "Yesterday", items: yesterdayItems)
                groupedRecentSection(title: "Earlier", items: earlierItems)
            }
        }
    }

    @ViewBuilder
    private func groupedRecentSection(title: String, items: [RecentContentSnapshot]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.52))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .padding(.horizontal, 2)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        recentRow(item)

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

    private func recentRow(_ item: RecentContentSnapshot) -> some View {
        Button {
            openRecent(item)
        } label: {
            HStack(spacing: 10) {
                Text(item.displayTopic)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)

                Spacer()

                Text(item.modeLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.1), in: Capsule())

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

    private var bottomComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Menu {
                ForEach(ContentMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.contentMode = mode
                    } label: {
                        if viewModel.contentMode == mode {
                            Label(mode.tabLabel, systemImage: "checkmark")
                        } else {
                            Text(mode.tabLabel)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.contentMode.tabLabel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                TextField(viewModel.contentMode.composerPlaceholder, text: $viewModel.topic)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .focused($isTextFieldFocused)
                    .submitLabel(.go)
                    .onSubmit { startLearning() }

                Button(action: startLearning) {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 22, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(canStart ? .white.opacity(0.78) : .white.opacity(0.3))
                    )
                }
                .disabled(!canStart)
                .buttonStyle(.plain)
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 7)
            .background(.clear, in: Capsule())
            .overlay(
                Capsule().stroke(.white.opacity(0.55), lineWidth: 1.4)
            )

            if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.95))
                    .padding(.leading, 6)
            }
        }
    }

    private func startLearning() {
        isTextFieldFocused = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { await viewModel.generateContent() }
    }

    private func openRecent(_ snapshot: RecentContentSnapshot) {
        isTextFieldFocused = false
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        viewModel.loadRecentSnapshot(snapshot)
        onOpenFeed?()
    }
}
