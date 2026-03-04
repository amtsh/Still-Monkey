import SwiftUI

struct SwipeHintOverlay: View {
    @State private var visible = true

    var body: some View {
        VStack {
            Spacer()
            if visible {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white.opacity(0.45))
                        .symbolEffect(.pulse, options: .nonRepeating)
                    Text("Swipe up")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
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
