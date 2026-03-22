import SwiftUI

struct FloatingSearchBar: View {
    @Bindable var viewModel: TopicViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ContentMode.allCases, id: \.self) { mode in
                        let isSelected = viewModel.contentMode == mode

                        Button {
                            viewModel.contentMode = mode
                        } label: {
                            Text(mode.tabLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? accentColor(for: mode).opacity(0.24) : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? accentColor(for: mode).opacity(0.62) : .white.opacity(0.28), lineWidth: 1)
                                )
                                .glassBackground(in: Capsule(), interactive: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.95))
                    .padding(.leading, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .onAppear {
            if !ContentMode.allCases.contains(viewModel.contentMode) {
                viewModel.contentMode = .learn
            }
        }
    }

    private func accentColor(for mode: ContentMode) -> Color {
        switch mode {
        case .learn:
            return .orange
        case .story:
            return .pink
        case .duolingo:
            return Color(red: 0.42, green: 0.82, blue: 0.42)
        }
    }
}
