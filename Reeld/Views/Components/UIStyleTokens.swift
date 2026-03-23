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

/// `HomeView` hero card inner padding (large title / recent lists use scroll margin only).
enum HomeLayout {
    static let horizontalContentInset: CGFloat = 20
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
