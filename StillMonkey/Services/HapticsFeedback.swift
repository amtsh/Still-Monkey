import UIKit

@MainActor
enum HapticsFeedback {
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func impactSoft() {
        soft.impactOccurred()
        soft.prepare()
    }

    static func impactMedium() {
        medium.impactOccurred()
        medium.prepare()
    }

    static func notifySuccess() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    static func notifyWarning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    static func notifyError() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    static func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }

    /// After a reel feed finishes generating successfully.
    static func generationSucceeded() {
        notifySuccess()
    }

    /// Quiz passed or lesson completed successfully.
    static func lessonSuccess() {
        notifySuccess()
    }

    /// Quiz failed or lesson gate not passed.
    static func lessonNeedsRetry() {
        notifyWarning()
    }
}
