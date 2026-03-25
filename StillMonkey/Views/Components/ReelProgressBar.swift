import SwiftUI

struct ReelProgressBar: View {
    let totalSegments: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(totalSegments, 0), id: \.self) { offset in
                Capsule()
                    .fill(segmentColor(at: offset))
                    .frame(height: 2.5)
            }
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("Card \(currentIndex + 1) of \(totalSegments)")
    }

    private func segmentColor(at index: Int) -> Color {
        if index < currentIndex { return Color.white.opacity(0.42) }
        if index == currentIndex { return Config.Brand.focusColor }
        return Color.white.opacity(0.18)
    }
}
