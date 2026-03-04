//
//  HomeView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: TopicViewModel
    @FocusState private var isTextFieldFocused: Bool

    private var canStart: Bool {
        !viewModel.isLoading && !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 28)
                heroSection
                Spacer()
                bottomComposer
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
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

    private var heroSection: some View {
        VStack(spacing: 10) {
            Text("Heal from\ndoomscrolling")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.63, blue: 0.71),
                            Color(red: 0.83, green: 0.56, blue: 1.00)
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
}
