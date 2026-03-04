//
//  ReelCardView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

// MARK: – Chapter accent palette

private let chapterColors: [Color] = [.blue, .purple, .pink, .orange]

private func chapterAccent(for chapterIndex: Int) -> Color {
    chapterColors[max(0, chapterIndex - 1) % chapterColors.count]
}

// MARK: – Progress bar

struct ReelProgressBar: View {
    let reels: [Reel]
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(reels.enumerated()), id: \.element.id) { offset, _ in
                Capsule()
                    .fill(segmentColor(at: offset))
                    .frame(height: 2.5)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentIndex)
            }
        }
        .padding(.horizontal, 16)
    }

    private func segmentColor(at index: Int) -> Color {
        if index < currentIndex { return .white.opacity(0.7) }
        if index == currentIndex { return .white }
        return .white.opacity(0.22)
    }
}

// MARK: – Main card dispatcher

struct ReelCardView: View {
    let reel: Reel
    let reels: [Reel]
    let currentIndex: Int

    private var isFirst: Bool { currentIndex == 0 }
    private var total: Int { reels.count }

    var body: some View {
        ZStack(alignment: .top) {
            switch reel.content {
            case .chapterTitle(let index, let title):
                ChapterTitleCard(index: index, title: title)
            case .content(let chapterIndex, let text):
                ContentCard(chapterIndex: chapterIndex, text: text)
            }

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    ReelProgressBar(reels: reels, currentIndex: currentIndex)
                    HStack {
                        Text("REEL \(currentIndex + 1) OF \(total)")
                            .font(.caption2.weight(.semibold))
                            .tracking(0.9)
                            .foregroundStyle(.white.opacity(0.55))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.top, 16)
                Spacer()
            }
        }
    }
}

// MARK: – Chapter title card

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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: – Content card

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
                chapterPill
                    .padding(.top, 52)
                    .padding(.leading, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text(text)
                    .font(.system(size: 33, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(8)
                    .padding(.horizontal, 28)
                    .multilineTextAlignment(.leading)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }

    private var chapterPill: some View {
        Text("Ch. \(chapterIndex)")
            .font(.caption2)
            .bold()
            .tracking(0.5)
            .foregroundStyle(accent.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(accent.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(accent.opacity(0.25), lineWidth: 1))
    }
}

// MARK: – Swipe hint overlay (used by ReelsView on first reel)

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
