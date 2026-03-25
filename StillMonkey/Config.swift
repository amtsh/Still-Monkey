//
//  Config.swift
//  Still Monkey
//
//  Created by Amit Shinde on 2026-03-04.
//

import Foundation
import SwiftUI

enum Config {
    static let openRouterEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    static let openRouterModel = "x-ai/grok-4.1-fast"
    static let apiKeyUserDefaultsKey = "openRouterAPIKey"

    /// Shared with Pravah: dark canvas, accents, and semantic fills.
    enum Brand {
        static let focusColor = Color(red: 0.96, green: 0.72, blue: 0.22)
        static let shortBreakColor = Color.green
        static let longBreakColor = Color(red: 0.68, green: 0.58, blue: 0.94)
        /// Soft violet for Story mode — calm, relaxing (composer pills, suggested rows).
        static let storyVioletColor = Color(red: 0.58, green: 0.48, blue: 0.92)

        static let backgroundDark = Color(red: 0.05, green: 0.04, blue: 0.07)
        static let backgroundSheet = Color(red: 0.14, green: 0.12, blue: 0.18)

        static let destructiveTint = Color(red: 0.24, green: 0.04, blue: 0.08)
        static let actionTint = Color(red: 0.04, green: 0.16, blue: 0.12)

        static let startButtonTextColor = Color.green
        static let startButtonFill = Color(red: 0.04, green: 0.18, blue: 0.05)

        static let readableSecondaryText = Color.white.opacity(0.68)
        static let readableTertiaryText = Color.white.opacity(0.52)

        static let accentColorOptions: [Color] = [
            Color(red: 1.0, green: 0.42, blue: 0.322),
            Color(red: 0.96, green: 0.72, blue: 0.22),
            Color(red: 0.18, green: 0.80, blue: 0.44),
            Color(red: 0.20, green: 0.78, blue: 0.75),
            Color(red: 0.35, green: 0.68, blue: 0.98),
            Color(red: 0.45, green: 0.45, blue: 0.95),
            Color(red: 0.68, green: 0.58, blue: 0.94),
            Color(red: 0.94, green: 0.35, blue: 0.48),
            Color(red: 1.0, green: 0.58, blue: 0.22),
            Color(red: 0.50, green: 0.93, blue: 0.78),
        ]

        static func accentColor(at index: Int) -> Color {
            let i = max(0, min(index, accentColorOptions.count - 1))
            return accentColorOptions[i]
        }
    }

    static let accentColor: Color = Brand.focusColor
}

extension ContentMode {
    /// Matches mode pills in `FloatingSearchBar` (Learn / Story / Path).
    var modeAccentColor: Color {
        switch self {
        case .learn:
            Config.Brand.focusColor
        case .story:
            Config.Brand.storyVioletColor
        case .path:
            Config.Brand.shortBreakColor
        }
    }

    var suggestedRowIconName: String {
        switch self {
        case .learn:
            "book"
        case .story:
            "moon.zzz"
        case .path:
            "point.3.connected.trianglepath.dotted"
        }
    }
}
