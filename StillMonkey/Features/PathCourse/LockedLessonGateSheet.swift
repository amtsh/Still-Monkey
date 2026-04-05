import SwiftUI

struct LockedLessonGateSheet: View {
    let lesson: PathLessonSummary
    let isPremiumMember: Bool
    let onConfirmOpenLesson: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        AppScreenCanvas(wash: .none) {
            VStack(spacing: 0) {
                Spacer(minLength: 6)

                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(lockBadgeFillColor)
                        .frame(width: 96, height: 96)
                        .overlay {
                            Image(systemName: lockBadgeSymbolName)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(lockBadgeIconColor)
                        }
                        .accessibilityHidden(true)

                    Text(lesson.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(bodyCopy)
                        .font(.body)
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 16)

                Button(action: onPrimaryAction) {
                    Text(primaryButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(primaryButtonFillColor)
                .foregroundStyle(primaryButtonTextColor)
                .accessibilityHint(primaryButtonHint)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var bodyCopy: String {
        if isPremiumMember {
            return "This lesson is locked until you complete earlier ones.\nAs a premium member, you can jump ahead any time."
        }
        return "Lessons unlock in order as you progress.\nUpgrade to premium to jump ahead whenever you need."
    }

    private var primaryButtonTitle: String {
        isPremiumMember ? "Jump to Lesson" : "Buy Premium to Unlock"
    }

    private var primaryButtonHint: String {
        isPremiumMember
            ? "Unlocks this lesson and starts it"
            : "Opens settings to enable premium membership"
    }

    private var primaryButtonFillColor: Color {
        isPremiumMember ? Config.Brand.startButtonFill : Color(red: 0.11, green: 0.10, blue: 0.0)
    }

    private var primaryButtonTextColor: Color {
        isPremiumMember ? Config.Brand.startButtonTextColor : Config.Brand.learnAccentColor
    }

    private var lockBadgeFillColor: Color {
        isPremiumMember
            ? Config.Brand.startButtonTextColor.opacity(0.14)
            : Config.Brand.learnAccentColor.opacity(0.14)
    }

    private var lockBadgeIconColor: Color {
        isPremiumMember ? Config.Brand.startButtonTextColor : Config.Brand.learnAccentColor
    }

    private var lockBadgeSymbolName: String {
        isPremiumMember ? "lock.open.fill" : "lock.fill"
    }

    private func onPrimaryAction() {
        HapticsFeedback.impactMedium()
        if isPremiumMember {
            onConfirmOpenLesson()
        } else {
            onOpenSettings()
        }
    }
}
