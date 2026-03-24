import SwiftUI

enum ReeldScreenBackground {
    /// Pravah-style full-screen base: black into deep violet-black.
    static var standard: LinearGradient {
        LinearGradient(
            colors: [.black, Config.Brand.backgroundDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Optional wash for feature areas (Duolingo, etc.): stays subtle on the same base.
    static func accentWash(
        topLeading: Color = Config.Brand.longBreakColor.opacity(0.14),
        topTrailing: Color = Config.Brand.focusColor.opacity(0.08)
    ) -> LinearGradient {
        LinearGradient(
            colors: [topLeading, topTrailing, .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Spacing and insets for `HomeView` scroll content, hero, and sections.
enum HomeLayout {
    static let horizontalContentInset: CGFloat = 20
    /// Outer `ScrollView` horizontal padding (matches section rows).
    static let scrollHorizontalPadding: CGFloat = 16
    static let scrollTopPadding: CGFloat = 14
    static let scrollBottomPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 24
    static let groupedSectionInnerSpacing: CGFloat = 16
    static let sectionHeaderSpacing: CGFloat = 12
    static let heroCardHeight: CGFloat = 210
    static let dividerLeadingInset: CGFloat = 30
}

/// Long-form reading (matches reel body / quiz copy rhythm).
enum ReadingTypography {
    static let bodySize: CGFloat = 20
    static let bodyLineSpacing: CGFloat = 10
    static let footnoteTitleSize: CGFloat = 14
    static let footnoteTopicSize: CGFloat = 13
}

enum UIIconSize {
    static let small: CGFloat = 11
    static let inline: CGFloat = 14
    static let navAction: CGFloat = 16
    static let prominentAction: CGFloat = 22
    static let hero: CGFloat = 48
}

enum UITouchTarget {
    static let minimum: CGFloat = 44
}

enum UIStatusIndicator {
    static let dot: CGFloat = 6
}
