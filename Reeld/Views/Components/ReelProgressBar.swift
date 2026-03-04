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
        if index < currentIndex { return .white.opacity(0.7) }
        if index == currentIndex { return .white }
        return .white.opacity(0.22)
    }
}
