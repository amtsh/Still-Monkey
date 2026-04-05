//
//  SuggestionsWallView.swift
//  Still Monkey
//

import SwiftUI

private struct SuggestionPill: Identifiable {
    let id: String
    let topic: String
    let mode: ContentMode
}

private enum SuggestionPillData {
    static let learnRow1: [SuggestionPill] = [
        SuggestionPill(id: "s1", topic: "How black holes form", mode: .learn),
        SuggestionPill(id: "s2", topic: "DNA and genetics", mode: .learn),
        SuggestionPill(id: "s3", topic: "Photosynthesis basics", mode: .learn),
        SuggestionPill(id: "s4", topic: "Machine learning for beginners", mode: .learn),
    ]

    static let learnRow2: [SuggestionPill] = [
        SuggestionPill(id: "s5", topic: "Climate change explained", mode: .learn),
        SuggestionPill(id: "s6", topic: "Neuroscience of memory", mode: .learn),
        SuggestionPill(id: "s7", topic: "Ancient Roman history", mode: .learn),
        SuggestionPill(id: "s8", topic: "Quantum computing basics", mode: .learn),
    ]

    static let storyRow1: [SuggestionPill] = [
        SuggestionPill(id: "s9", topic: "A detective in Tokyo", mode: .story),
        SuggestionPill(id: "s10", topic: "Midnight train to nowhere", mode: .story),
        SuggestionPill(id: "s11", topic: "The last astronaut", mode: .story),
        SuggestionPill(id: "s12", topic: "A dragon who hates fire", mode: .story),
    ]

    static let storyRow2: [SuggestionPill] = [
        SuggestionPill(id: "s13", topic: "A lighthouse keeper's journal", mode: .story),
        SuggestionPill(id: "s14", topic: "Letters from the ocean floor", mode: .story),
        SuggestionPill(id: "s15", topic: "The clockmaker's apprentice", mode: .story),
        SuggestionPill(id: "s16", topic: "A village that forgot music", mode: .story),
    ]

    static let pathRow1: [SuggestionPill] = [
        SuggestionPill(id: "s17", topic: "Road to data science", mode: .path),
        SuggestionPill(id: "s18", topic: "Master Python from zero", mode: .path),
        SuggestionPill(id: "s19", topic: "Understand personal finance", mode: .path),
        SuggestionPill(id: "s20", topic: "Spanish for travelers", mode: .path),
    ]

    static let pathRow2: [SuggestionPill] = [
        SuggestionPill(id: "s21", topic: "Public speaking with confidence", mode: .path),
        SuggestionPill(id: "s22", topic: "Learn piano fundamentals", mode: .path),
        SuggestionPill(id: "s23", topic: "Build a habit system", mode: .path),
        SuggestionPill(id: "s24", topic: "Become better at time management", mode: .path),
    ]
}

private enum SuggestionPillChrome {
    static let modeIconSize: CGFloat = 14
}

private struct GlassPillView: View {
    let pill: SuggestionPill
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: pill.mode.modeRowIconName)
                    .font(.system(size: SuggestionPillChrome.modeIconSize, weight: .regular))
                    .foregroundStyle(pill.mode.modeAccentColor)
                    .symbolRenderingMode(.monochrome)
                Text(pill.topic)
                    .font(.caption.weight(.regular))
                    .foregroundStyle(.white.opacity(0.96))
                    .lineLimit(1)
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
            .frame(minHeight: UITouchTarget.minimum)
            .glassBackground(in: Capsule(), interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pill.mode.tabLabel): \(pill.topic)")
    }
}

private struct PillsRowView: View {
    let pills: [SuggestionPill]
    let onSelect: (SuggestionPill) -> Void

    var body: some View {
        HStack(spacing: HomeLayout.suggestionsPillSpacing) {
            ForEach(pills) { pill in
                GlassPillView(pill: pill) {
                    HapticsFeedback.impactSoft()
                    onSelect(pill)
                }
            }
        }
        .frame(height: HomeLayout.suggestionsRowHeight)
    }
}

struct SuggestionsWallView: View {
    var onSelect: (String, ContentMode) -> Void

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: HomeLayout.suggestionsRowSpacing) {
                    wallContent
                }
            } else {
                wallContent
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, HomeLayout.suggestionsRowSpacing)
        .clipped()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Suggested topics")
    }

    private var wallContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: HomeLayout.suggestionsRowSpacing) {
                PillsRowView(pills: SuggestionPillData.learnRow1, onSelect: handleSelect)
                PillsRowView(pills: SuggestionPillData.learnRow2, onSelect: handleSelect)
                PillsRowView(pills: SuggestionPillData.storyRow1, onSelect: handleSelect)
                PillsRowView(pills: SuggestionPillData.storyRow2, onSelect: handleSelect)
                PillsRowView(pills: SuggestionPillData.pathRow1, onSelect: handleSelect)
                PillsRowView(pills: SuggestionPillData.pathRow2, onSelect: handleSelect)
            }
        }
    }

    private func handleSelect(_ pill: SuggestionPill) {
        onSelect(pill.topic, pill.mode)
    }
}

#Preview {
    ZStack {
        AppScreenBackground.standard
        SuggestionsWallView { _, _ in }
    }
    .preferredColorScheme(.dark)
}
