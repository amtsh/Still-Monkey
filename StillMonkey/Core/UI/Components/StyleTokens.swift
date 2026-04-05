import SwiftUI

enum HomeLayout {
    static let horizontalContentInset: CGFloat = 20
    static let scrollHorizontalPadding: CGFloat = 16
    static let scrollTopPadding: CGFloat = 14
    static let scrollBottomPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 24
    static let groupedSectionInnerSpacing: CGFloat = 16
    static let sectionHeaderSpacing: CGFloat = 12
    static let heroCardHeight: CGFloat = 112
    static let homeRowAvatarSize: CGFloat = 56
    static let homeRowAvatarCornerRadius: CGFloat = 4
    static let listRowLeadingIconWidth: CGFloat = 20
    static let modePillWidth: CGFloat = 76
    static let trailingPillChevronSpacing: CGFloat = 4
    static let listRowIconTitleSpacing: CGFloat = 12
    static var homeRowDividerLeadingInset: CGFloat {
        homeRowAvatarSize + listRowIconTitleSpacing
    }

    static let listRowMinHeight: CGFloat = 44
    static let listRowVerticalPadding: CGFloat = 11

    static let suggestionsRowHeight: CGFloat = 44
    static let suggestionsPillSpacing: CGFloat = 8
    static let suggestionsRowSpacing: CGFloat = 6
}

enum ReadingTypography {
    static let bodySize: CGFloat = 20
    static let bodyLineSpacing: CGFloat = 10
    static let footnoteTitleSize: CGFloat = 14
    static let footnoteTopicSize: CGFloat = 13
}

enum UIIconSize {
    static let inline: CGFloat = 14
    static let navAction: CGFloat = 16
    static let hero: CGFloat = 48
}

enum UITouchTarget {
    static let minimum: CGFloat = 44
}

enum UIStatusIndicator {
    static let dot: CGFloat = 6
}
