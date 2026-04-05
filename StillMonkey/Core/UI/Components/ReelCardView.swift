import SwiftUI

private enum ReelCardPalette {
    static let chapterAccents = stride(from: 1, through: 9, by: 2).map { Config.Brand.accentColor(at: $0) }
}

private func chapterAccent(for chapterIndex: Int) -> Color {
    let palette = ReelCardPalette.chapterAccents
    return palette[max(0, chapterIndex - 1) % palette.count]
}

struct ReelCardView: View {
    let reel: Reel
    let currentIndex: Int
    let cardIndex: Int
    let totalCount: Int
    let chapterTitle: String?
    let topicTitle: String
    let showsProgressBar: Bool
    var progressAccent: Color

    var body: some View {
        GeometryReader { proxy in
            cardContent
                .overlay(alignment: .bottom) {
                    ReelProgressBar(totalSegments: totalCount, currentIndex: currentIndex, progressAccent: progressAccent)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .offset(y: reelBarOffset(for: proxy))
                        .opacity(
                            showsProgressBar ? reelBarVisibility(for: proxy) : 0
                        )
                        .allowsHitTesting(false)
                }
                .clipped()
        }
        .clipShape(Rectangle())
        .clipped()
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
            AppScreenBackground.standard

            VStack(spacing: 18) {
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
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .minimumScaleFactor(0.8)

                Text(topicTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Config.Brand.readableSecondaryText)
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

private func sentences(from text: String) -> [String] {
    let pattern = "(?<=[.!?])\\s+"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [text] }
    let range = NSRange(text.startIndex..., in: text)
    let modified = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "\n")
    return modified.components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

private struct ContentCard: View {
    let chapterIndex: Int
    let chapterTitle: String?
    let topicTitle: String
    private let sentenceParagraphs: [String]
    @State private var appeared = false

    init(chapterIndex: Int, chapterTitle: String?, topicTitle: String, text: String) {
        self.chapterIndex = chapterIndex
        self.chapterTitle = chapterTitle
        self.topicTitle = topicTitle
        sentenceParagraphs = sentences(from: text)
    }

    var body: some View {
        ZStack {
            AppScreenBackground.standard

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(sentenceParagraphs.indices, id: \.self) { index in
                        Text(sentenceParagraphs[index])
                            .font(.system(size: ReadingTypography.bodySize))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .lineSpacing(ReadingTypography.bodyLineSpacing)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(chapterIndex). \(chapterTitle ?? "Chapter \(chapterIndex)")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                    Text(topicTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Config.Brand.readableTertiaryText)
                        .lineLimit(1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 56)
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
