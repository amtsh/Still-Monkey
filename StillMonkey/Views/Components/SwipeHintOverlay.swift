import SwiftUI

struct SwipeHintOverlay: View {
    @State private var visible = true

    var body: some View {
        VStack {
            Spacer()
            if visible {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.compact.up")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .symbolEffect(.pulse, options: .nonRepeating)
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
            withAnimation(.easeOut(duration: 0.6)) { visible = false }
        }
    }
}
