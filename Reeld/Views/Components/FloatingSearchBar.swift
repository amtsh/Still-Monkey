import SwiftUI

struct FloatingSearchBar: View {
    @Bindable var viewModel: TopicViewModel
    var isSearchFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isSearchFocused.wrappedValue {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ContentMode.allCases, id: \.self) { mode in
                            let isSelected = viewModel.contentMode == mode

                            Button {
                                HapticsFeedback.selectionChanged()
                                viewModel.contentMode = mode
                            } label: {
                                Text(mode.tabLabel)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.white : Config.Brand.readableSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 6)
                                    .frame(width: HomeLayout.modePillWidth)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? mode.modeAccentColor.opacity(0.22) : Color.clear)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? mode.modeAccentColor.opacity(0.55) : Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                    .glassBackground(in: Capsule(), interactive: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(mode.tabLabel) mode\(isSelected ? ", selected" : "")")
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

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
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.22), value: isSearchFocused.wrappedValue)
        .onAppear {
            if !ContentMode.allCases.contains(viewModel.contentMode) {
                viewModel.contentMode = .learn
            }
        }
    }
}
