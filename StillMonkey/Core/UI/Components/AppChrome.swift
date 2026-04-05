import SwiftUI

enum ReadingNavigationChrome {
    static let titleOpacity: Double = 0.42
    static let toolbarActionOpacity: Double = 0.45
    static let toolbarActionDisabledOpacity: Double = 0.24
    static let toolbarBookmarkFilledOpacity: Double = 0.78
}

extension View {
    func appBlendedNavigationBar() -> some View {
        toolbarBackground(AppScreenBackground.standard, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .background(NavigationBarCanvasBlend())
    }
}

enum AppScreenBackground {
    static var standard: Color {
        Config.Brand.backgroundDark
    }

    static func accentWash(
        topLeading: Color = Config.Brand.longBreakColor.opacity(0.14),
        topTrailing: Color = Config.Brand.learnAccentColor.opacity(0.08)
    ) -> LinearGradient {
        LinearGradient(
            colors: [topLeading, topTrailing, .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AppScreenCanvas<Content: View>: View {
    enum Wash {
        case none
        case pathDefault
        case custom(topLeading: Color, topTrailing: Color)
    }

    var wash: Wash = .none
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            AppScreenBackground.standard
                .ignoresSafeArea()

            switch wash {
            case .none:
                EmptyView()
            case .pathDefault:
                AppScreenBackground.accentWash()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            case let .custom(topLeading, topTrailing):
                AppScreenBackground.accentWash(topLeading: topLeading, topTrailing: topTrailing)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            content()
        }
    }
}
