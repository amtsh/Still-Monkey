import SwiftUI

struct DuolingoCourseView: View {
    @Bindable var viewModel: DuolingoCourseViewModel
    var onOpenLesson: (String) -> Void

    @State private var lastAutoScrolledLessonID: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.58, blue: 0.35).opacity(0.34),
                    Color(red: 0.87, green: 0.78, blue: 0.28).opacity(0.16),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

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
    }

    @ViewBuilder
    private var content: some View {
        if let course = viewModel.course {
            VStack(spacing: 0) {
                ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                    lessonNode(lesson, isLast: index == course.lessons.count - 1)
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

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duolingo Mode")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.85, green: 0.94, blue: 0.68))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())

            Text(viewModel.course?.courseTitle ?? "Build a new lesson path")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text(viewModel.topic.isEmpty ? "Search a topic to create a step-by-step course." : viewModel.topic.localizedCapitalized)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private func lessonNode(_ lesson: DuolingoLessonSummary, isLast: Bool) -> some View {
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
                            Text("\(lesson.order)")
                                .font(.system(size: 13, weight: .heavy))
                        }
                        .foregroundStyle(state == .locked ? .white.opacity(0.45) : .white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(state == .locked)
                .accessibilityLabel(lesson.title)

                VStack(alignment: .leading, spacing: 8) {
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundStyle(.white)

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
                                Color.white.opacity(0.04)
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
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .glassCard(cornerRadius: 24)
    }

    private func errorState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: UIIconSize.hero))
                .foregroundStyle(.orange.opacity(0.8))

            Text(message)
                .font(.headline)
                .foregroundStyle(.white)

            Button("Try again") {
                Task { await viewModel.startCourse(for: viewModel.topic, forceRefresh: true) }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.black)
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
            Text("Search a topic from the home screen in Duolingo mode to create a vertical lesson map.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.64))
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

    private func iconName(for state: DuolingoLessonAccessState) -> String {
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

    private func circleFill(for state: DuolingoLessonAccessState) -> Color {
        switch state {
        case .locked:
            return Color.white.opacity(0.08)
        case .completed:
            return Color(red: 0.25, green: 0.72, blue: 0.41)
        case .current:
            return Color(red: 0.96, green: 0.68, blue: 0.26)
        case .unlocked:
            return Color(red: 0.27, green: 0.58, blue: 0.97)
        }
    }

    private func circleStroke(for state: DuolingoLessonAccessState) -> Color {
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

    private func shadowColor(for state: DuolingoLessonAccessState) -> Color {
        switch state {
        case .locked:
            return .clear
        case .completed:
            return Color.green.opacity(0.26)
        case .current:
            return Color.orange.opacity(0.28)
        case .unlocked:
            return Color.blue.opacity(0.24)
        }
    }

    private func statusLabel(for lesson: DuolingoLessonSummary, state: DuolingoLessonAccessState) -> String {
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

    private func statusColor(for state: DuolingoLessonAccessState) -> Color {
        switch state {
        case .locked:
            return .white.opacity(0.45)
        case .completed:
            return .green
        case .current:
            return .orange
        case .unlocked:
            return .blue
        }
    }
}
