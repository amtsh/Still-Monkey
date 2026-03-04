import UIKit

@MainActor
enum HapticsFeedback {
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)

    static func impactSoft() {
        soft.impactOccurred()
        soft.prepare()
    }

    static func impactMedium() {
        medium.impactOccurred()
        medium.prepare()
    }
}
