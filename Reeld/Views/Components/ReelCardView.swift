import SwiftUI

private let chapterColors: [Color] = [.blue, .purple, .pink, .orange]

private func chapterAccent(for chapterIndex: Int) -> Color {
    chapterColors[max(0, chapterIndex - 1) % chapterColors.count]
}

struct ReelCardView: View {
    let reel: Reel

    var body: some View {
        switch reel.content {
        case .chapterTitle(let index, let title):
            ChapterTitleCard(index: index, title: title)
        case .content(let chapterIndex, let text):
            ContentCard(chapterIndex: chapterIndex, text: text)
        }
    }
}

private struct ChapterTitleCard: View {
    let index: Int
    let title: String
    @State private var appeared = false

    private var accent: Color { chapterAccent(for: index) }

    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 340
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Chapter \(index)")
                    .font(.caption)
                    .bold()
                    .tracking(1)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(accent.opacity(0.15), in: Capsule())
                    .overlay(Capsule().stroke(accent.opacity(0.3), lineWidth: 1))

                Text(title)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .minimumScaleFactor(0.8)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }
}

private struct ContentCard: View {
    let chapterIndex: Int
    let text: String
    @State private var appeared = false

    private var accent: Color { chapterAccent(for: chapterIndex) }

    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [accent.opacity(0.1), .clear],
                center: UnitPoint(x: 0.8, y: 0.1),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text(text)
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(5)
                    .padding(.horizontal, 28)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                Spacer()
            }
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
