import SwiftUI

struct FloatingSearchBar: View {
    @Bindable var viewModel: TopicViewModel

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
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: UIIconSize.small, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassBackground(in: Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

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
}
