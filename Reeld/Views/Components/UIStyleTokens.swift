import SwiftUI

/// Navigation bar styling while reading long-form content: bar stays visible but blends with the canvas and uses lower-contrast chrome.
enum ReadingNavigationChrome {
    static let barBackground = Config.Brand.backgroundDark
    static let titleOpacity: Double = 0.42
    static let toolbarActionOpacity: Double = 0.45
    static let toolbarActionDisabledOpacity: Double = 0.24
}

extension View {
    /// Keeps the navigation bar visible with a dark fill that matches `ReeldScreenBackground` so it does not read as a separate bright strip.
    func deemphasizedReadingNavigationBar() -> some View {
        toolbarBackground(ReadingNavigationChrome.barBackground, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    }
}

enum ReeldScreenBackground {
    /// Pravah-style full-screen base: black into deep violet-black.
    static var standard: LinearGradient {
        LinearGradient(
            colors: [.black, Config.Brand.backgroundDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Optional wash for feature areas (lesson path, etc.): stays subtle on the same base.
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
    /// Leading icon column + `HStack` spacing before title (aligns dividers with text).
    static let listRowLeadingIconWidth: CGFloat = 20
    /// Fixed width for Learn / Story / Path pills (composer, path header).
    static let modePillWidth: CGFloat = 76
    /// Space between trailing pill (“Last seen”, mode pill) and chevron (tighter than `listRowIconTitleSpacing`).
    static let trailingPillChevronSpacing: CGFloat = 4
    static let listRowIconTitleSpacing: CGFloat = 12
    static var dividerLeadingInset: CGFloat { listRowLeadingIconWidth + listRowIconTitleSpacing }

    /// HIG minimum touch target (44pt); with 11pt vertical padding, single-line rows read as standard list density.
    static let listRowMinHeight: CGFloat = 44
    static let listRowVerticalPadding: CGFloat = 11
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
