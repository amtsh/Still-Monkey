import SwiftUI

struct SwipeHintOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = true

    var body: some View {
        VStack {
            Spacer()
            if visible {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.compact.up")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .modifier(ConditionalPulseSymbolEffect(enabled: !reduceMotion))
                    Text("Swipe up")
                        .font(.caption2)
                        .foregroundStyle(Config.Brand.readableTertiaryText)
                }
                .padding(.bottom, 110)
                .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            if reduceMotion {
                visible = false
            } else {
                withAnimation(.easeOut(duration: 0.6)) { visible = false }
            }
        }
    }
}

private struct ConditionalPulseSymbolEffect: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.symbolEffect(.pulse, options: .nonRepeating)
        } else {
            content
        }
    }
}
