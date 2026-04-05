import SwiftUI

struct LearnModeEndScreenView: View {
    let topicTitle: String
    let totalSegments: Int
    let currentIndex: Int
    let showsProgressBar: Bool
    let isLoading: Bool
    let progressAccent: Color
    let onGoDeeper: () -> Void
    let onDone: () -> Void

    @State private var didEmitSuccessHaptic = false

    var body: some View {
        ZStack {
            AppScreenBackground.standard

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(progressAccent)
                    .accessibilityHidden(true)

                Text("End of lesson")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 10) {
                    Text(topicTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text(
                        "You can continue to learn more about this topic by going deeper."
                    )
                    .font(.body)
                    .foregroundStyle(Config.Brand.readableSecondaryText)
                    .lineSpacing(ReadingTypography.bodyLineSpacing)
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Button {
                        HapticsFeedback.impactMedium()
                        onGoDeeper()
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                                    .accessibilityHidden(true)
                            }
                            Text(isLoading ? "Loading …" : "Go deeper")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Config.Brand.startButtonFill)
                    .foregroundStyle(Config.Brand.startButtonTextColor)
                    .disabled(isLoading)
                    .accessibilityLabel(isLoading ? "Generating deeper lesson" : "Go deeper on this topic")

                    Button("Close") {
                        HapticsFeedback.impactSoft()
                        onDone()
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(Config.Brand.readableSecondaryText)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close feed")
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, showsProgressBar ? 52 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottom) {
            ReelProgressBar(totalSegments: totalSegments, currentIndex: currentIndex, progressAccent: progressAccent)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .opacity(showsProgressBar ? 1 : 0)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            guard !didEmitSuccessHaptic else { return }
            didEmitSuccessHaptic = true
            HapticsFeedback.lessonSuccess()
        }
    }
}
