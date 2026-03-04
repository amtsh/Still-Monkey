import SwiftUI

struct FloatingSearchBar: View {
    @Bindable var viewModel: TopicViewModel
    var isSearchFocused: FocusState<Bool>.Binding
    var onStartLearning: (() -> Void)? = nil

    private var canStart: Bool {
        !viewModel.isLoading && !viewModel.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
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
                    .focused(isSearchFocused)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func startLearning() {
        isSearchFocused.wrappedValue = false
        HapticsFeedback.impactMedium()
        onStartLearning?()
    }
}
