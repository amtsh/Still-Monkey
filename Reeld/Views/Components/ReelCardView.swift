import SwiftUI

private let chapterColors: [Color] = [.blue, .purple, .pink, .orange]

private func chapterAccent(for chapterIndex: Int) -> Color {
    chapterColors[max(0, chapterIndex - 1) % chapterColors.count]
}

struct ReelCardView: View {
    let reel: Reel
    let currentIndex: Int
    let cardIndex: Int
    let totalCount: Int
    let chapterTitle: String?
    let topicTitle: String

    var body: some View {
        GeometryReader { proxy in
            cardContent
                .overlay(alignment: .bottom) {
                    ReelProgressBar(totalSegments: totalCount, currentIndex: currentIndex)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .offset(y: reelBarOffset(for: proxy))
                        .opacity(reelBarVisibility(for: proxy))
                        .allowsHitTesting(false)
                }
                .clipped()
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch reel.content {
        case let .chapterTitle(index, title):
            ChapterTitleCard(index: index, title: title, topicTitle: topicTitle)
        case let .content(chapterIndex, text):
            ContentCard(
                chapterIndex: chapterIndex,
                chapterTitle: chapterTitle,
                topicTitle: topicTitle,
                text: text
            )
        }
    }

    private func reelBarVisibility(for proxy: GeometryProxy) -> Double {
        let minY = proxy.frame(in: .scrollView).minY
        let pageHeight = max(proxy.size.height, 1)
        let restingMinY = CGFloat(cardIndex - currentIndex) * pageHeight
        let distanceFromRest = abs(minY - restingMinY)
        return min(max(distanceFromRest / 120, 0), 1)
    }

    private func reelBarOffset(for proxy: GeometryProxy) -> CGFloat {
        let hiddenOffset: CGFloat = 36
        let visibility = reelBarVisibility(for: proxy)
        return hiddenOffset * (1 - visibility)
    }
}

private struct ChapterTitleCard: View {
    let index: Int
    let title: String
    let topicTitle: String
    @State private var appeared = false

    private var accent: Color {
        chapterAccent(for: index)
    }

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
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .minimumScaleFactor(0.8)

                Text(topicTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .padding(.horizontal, 32)
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
    let chapterTitle: String?
    let topicTitle: String
    let text: String
    @State private var appeared = false

    private var accent: Color {
        chapterAccent(for: chapterIndex)
    }

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
                Spacer(minLength: 86)

                Text(text)
                    .font(.system(size: 25, weight: .regular))
                    .foregroundStyle(.white)
                    .lineSpacing(5)
                    .padding(.horizontal, 28)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)
                    .lineLimit(16)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                Spacer(minLength: 170)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(chapterIndex). \(chapterTitle ?? "Chapter \(chapterIndex)")")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                    Text(topicTitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 72)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
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
