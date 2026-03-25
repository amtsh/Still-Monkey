import SwiftUI

struct PathCourseView: View {
    @Bindable var viewModel: PathCourseViewModel
    var onOpenLesson: (String) -> Void

    @State private var lastAutoScrolledLessonID: String?

    var body: some View {
        AppScreenCanvas(wash: .pathDefault) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerCard
                        content
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
                .onAppear {
                    autoScrollIfNeeded(with: proxy)
                }
                .onChange(of: viewModel.currentActionableLessonID) { _, _ in
                    autoScrollIfNeeded(with: proxy)
                }
            }
        }
        .navigationTitle("Lesson Path")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.course != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refreshCurrentCourse() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: UIIconSize.navAction, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.85))
                    .accessibilityLabel("Refresh lesson path")
                }
            }
        }
        .appBlendedNavigationBar()
    }

    @ViewBuilder
    private var content: some View {
        if let course = viewModel.course {
            VStack(spacing: 0) {
                ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                    lessonNode(lesson, isLast: index == course.lessons.count - 1)
                }

                if viewModel.isPathFullyCompleted {
                    extendPathCallout
                        .padding(.top, 20)
                        .id("extendPathCallout")
                }
            }
        } else if viewModel.isLoading {
            loadingState
        } else if let error = viewModel.error {
            errorState(message: error)
        } else {
            placeholderState
        }
    }

    private var extendPathCallout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ContentMode.path.modeAccentColor)
                Text("Continue deeper")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Text("You've finished every lesson. Load more lessons to go deeper with advanced topics on the same path.")
                .font(.subheadline)
                .foregroundStyle(Config.Brand.readableSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                HapticsFeedback.impactMedium()
                lastAutoScrolledLessonID = nil
                Task { await viewModel.extendPathWithMoreLessons() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    }
                    Text(viewModel.isLoading ? "Loading…" : "Load more lessons")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Config.Brand.startButtonFill)
            .foregroundStyle(Config.Brand.startButtonTextColor)
            .disabled(viewModel.isLoading)
            .accessibilityLabel("Load more lessons")

            if let err = viewModel.error, viewModel.isPathFullyCompleted {
                Text(err)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ContentMode.path.tabLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 6)
                .frame(width: HomeLayout.modePillWidth)
                .background(
                    Capsule()
                        .fill(ContentMode.path.modeAccentColor.opacity(0.22))
                )
                .overlay(
                    Capsule()
                        .stroke(ContentMode.path.modeAccentColor.opacity(0.55), lineWidth: 1)
                )
                .glassBackground(in: Capsule(), interactive: false)

            Text(viewModel.course?.courseTitle ?? "Build a new lesson path")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text(courseSubtitle)
                .font(.subheadline)
                .foregroundStyle(Config.Brand.readableSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private func lessonNode(_ lesson: PathLessonSummary, isLast: Bool) -> some View {
        let state = viewModel.accessState(for: lesson)
        let horizontalOffset = pathOffset(for: lesson.order)

        return VStack(spacing: 0) {
            VStack(spacing: 12) {
                Button {
                    HapticsFeedback.impactSoft()
                    onOpenLesson(lesson.id)
                } label: {
                    ZStack {
                        Circle()
                            .fill(circleFill(for: state))
                            .frame(width: 92, height: 92)
                            .overlay(
                                Circle()
                                    .stroke(circleStroke(for: state), lineWidth: 2)
                            )
                            .shadow(color: shadowColor(for: state), radius: 18, y: 10)

                        VStack(spacing: 6) {
                            Image(systemName: iconName(for: state))
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundStyle(state == .locked ? .white.opacity(0.45) : .white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(state == .locked)
                .accessibilityLabel(lesson.title)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(lesson.order).")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white.opacity(0.72))

                        Text(lesson.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    Text(lesson.summary)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))

                    Text(statusLabel(for: lesson, state: state))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor(for: state))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor(for: state).opacity(0.12), in: Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassCard(cornerRadius: 20)
            }
            .frame(maxWidth: 300)
            .offset(x: horizontalOffset)
            .id(lesson.id)

            if !isLast {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.24),
                                Color.white.opacity(0.04),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 54)
                    .padding(.vertical, 8)
                    .offset(x: horizontalOffset)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            Text("Building your path...")
                .font(.headline)
                .foregroundStyle(Config.Brand.readableSecondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .glassCard(cornerRadius: 24)
    }

    private func errorState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: UIIconSize.hero))
                .foregroundStyle(Config.Brand.focusColor.opacity(0.9))

            Text(message)
                .font(.headline)
                .foregroundStyle(.white)

            Button("Try again") {
                Task { await viewModel.startCourse(for: viewModel.topic, forceRefresh: true) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Config.Brand.startButtonFill)
            .foregroundStyle(Config.Brand.startButtonTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private var placeholderState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No lesson path yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Search a topic from the home screen in Path mode to create a vertical lesson map.")
                .font(.subheadline)
                .foregroundStyle(Config.Brand.readableSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private func autoScrollIfNeeded(with proxy: ScrollViewProxy) {
        guard let target = viewModel.currentActionableLessonID, lastAutoScrolledLessonID != target else { return }
        lastAutoScrolledLessonID = target

        Task { @MainActor in
            await Task.yield()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }

    private func pathOffset(for order: Int) -> CGFloat {
        switch order % 3 {
        case 0: return -54
        case 1: return 0
        default: return 54
        }
    }

    private var courseSubtitle: String {
        if let course = viewModel.course {
            return "\(course.lessons.count) Lessons"
        }

        if viewModel.topic.isEmpty {
            return "Search a topic to create a step-by-step course."
        }

        return "Building a lesson path for \(viewModel.topic.localizedCapitalized)"
    }

    private func iconName(for state: PathLessonAccessState) -> String {
        switch state {
        case .locked:
            return "lock.fill"
        case .completed:
            return "checkmark"
        case .current:
            return "play.fill"
        case .unlocked:
            return "star.fill"
        }
    }

    private func circleFill(for state: PathLessonAccessState) -> Color {
        switch state {
        case .locked:
            return Color.white.opacity(0.08)
        case .completed:
            return Config.Brand.shortBreakColor.opacity(0.85)
        case .current:
            return ContentMode.path.modeAccentColor
        case .unlocked:
            return Config.Brand.accentColor(at: 4)
        }
    }

    private func circleStroke(for state: PathLessonAccessState) -> Color {
        switch state {
        case .locked:
            return .white.opacity(0.08)
        case .completed:
            return .white.opacity(0.18)
        case .current:
            return Color.white.opacity(0.2)
        case .unlocked:
            return Color.white.opacity(0.2)
        }
    }

    private func shadowColor(for state: PathLessonAccessState) -> Color {
        switch state {
        case .locked:
            return .clear
        case .completed:
            return Config.Brand.shortBreakColor.opacity(0.26)
        case .current:
            return ContentMode.path.modeAccentColor.opacity(0.35)
        case .unlocked:
            return Config.Brand.accentColor(at: 4).opacity(0.28)
        }
    }

    private func statusLabel(for lesson: PathLessonSummary, state: PathLessonAccessState) -> String {
        switch state {
        case .locked:
            return "Locked"
        case .completed:
            return "Completed"
        case .current:
            if viewModel.lessonProgress(for: lesson.id) != nil {
                return "Continue"
            }
            return "Start lesson"
        case .unlocked:
            if viewModel.lessonProgress(for: lesson.id) != nil {
                return "Continue"
            }
            return "Unlocked"
        }
    }

    private func statusColor(for state: PathLessonAccessState) -> Color {
        switch state {
        case .locked:
            return .white.opacity(0.45)
        case .completed:
            return Config.Brand.shortBreakColor
        case .current:
            return ContentMode.path.modeAccentColor
        case .unlocked:
            return Config.Brand.accentColor(at: 4)
        }
    }
}
