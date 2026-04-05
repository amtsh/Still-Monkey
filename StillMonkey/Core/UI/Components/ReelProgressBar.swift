import SwiftUI

struct ReelProgressBar: View {
    let totalSegments: Int
    let currentIndex: Int
    var progressAccent: Color = Config.Brand.learnAccentColor

    private var useContinuousStyle: Bool {
        totalSegments > 32
    }

    var body: some View {
        Group {
            if useContinuousStyle {
                continuousBar
            } else {
                segmentedBar
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("Card \(currentIndex + 1) of \(totalSegments)")
    }

    private var segmentedBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(totalSegments, 0), id: \.self) { offset in
                Capsule()
                    .fill(segmentColor(at: offset))
                    .frame(height: 2.5)
            }
        }
        .padding(.horizontal, 16)
    }

    private var continuousBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 3)
                Capsule()
                    .fill(progressAccent)
                    .frame(width: progressWidth(in: geo.size.width), height: 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 3)
        .padding(.horizontal, 16)
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard totalSegments > 0 else { return 0 }
        let frac = CGFloat(currentIndex + 1) / CGFloat(totalSegments)
        return totalWidth * min(1, max(0, frac))
    }

    private func segmentColor(at index: Int) -> Color {
        if index < currentIndex { return Color.white.opacity(0.42) }
        if index == currentIndex { return progressAccent }
        return Color.white.opacity(0.18)
    }
}
