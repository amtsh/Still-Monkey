import SwiftUI

struct ContentView: View {
    private enum Route: Hashable {
        case reels
        case pathCourse
        case pathLesson(String)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = TopicViewModel()
    @State private var courseViewModel = PathCourseViewModel()
    @State private var path: [Route] = []
    @State private var isShowingSettings = false
    @State private var generationRequestID: UUID?
    @State private var pathCourseRequestID: UUID?
    /// Captured when starting path / feed so async work does not see an empty topic after search dismiss clears bindings.
    @State private var pathCourseStartTopic: String?
    @State private var feedStartTopic: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                viewModel: viewModel,
                courseViewModel: courseViewModel,
                isSearchFocused: $isSearchFocused,
                onOpenSettings: {
                    isShowingSettings = true
                },
                onOpenFeed: {
                    isSearchFocused = false
                    showReelsIfNeeded()
                },
                onOpenCourseMap: {
                    isSearchFocused = false
                    showPathCourseIfNeeded()
                },
                onStartLearning: {
                    startCurrentMode()
                    isSearchFocused = false
                },
                onStartSuggestion: { topic, mode in
                    startMode(mode, topic: topic)
                    isSearchFocused = false
                }
            )
            .safeAreaInset(edge: .bottom) {
                if path.isEmpty {
                    FloatingSearchBar(viewModel: viewModel, isSearchFocused: $isSearchFocused)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .reels:
                    ReelsView(viewModel: viewModel)
                case .pathCourse:
                    PathCourseView(viewModel: courseViewModel) { lessonID in
                        showPathLesson(lessonID)
                    }
                case .pathLesson(let lessonID):
                    PathLessonSessionView(
                        viewModel: PathLessonSessionViewModel(
                            courseViewModel: courseViewModel,
                            lessonID: lessonID
                        )
                    )
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task(id: generationRequestID) {
                guard generationRequestID != nil else { return }
                let topicOverride = feedStartTopic
                feedStartTopic = nil
                await viewModel.generateContent(topicOverride: topicOverride)
                generationRequestID = nil
            }
            .task(id: pathCourseRequestID) {
                guard pathCourseRequestID != nil else { return }
                let topic = pathCourseStartTopic ?? viewModel.topic
                pathCourseStartTopic = nil
                await courseViewModel.startCourse(for: topic)
                pathCourseRequestID = nil
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading {
                    showReelsIfNeeded()
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Config.accentColor)
    }

    private func showReelsIfNeeded() {
        guard path.last != .reels else { return }
        withAnimation(reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.82)) {
            path.append(.reels)
        }
    }

    private func showPathCourseIfNeeded() {
        if let courseIndex = path.firstIndex(of: .pathCourse) {
            path = Array(path.prefix(courseIndex + 1))
            return
        }

        if path.contains(.reels) {
            path.removeAll()
        }

        guard path.last != .pathCourse else { return }
        withAnimation(reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.82)) {
            path.append(.pathCourse)
        }
    }

    private func showPathLesson(_ lessonID: String) {
        if let courseIndex = path.firstIndex(of: .pathCourse) {
            path = Array(path.prefix(courseIndex + 1))
        } else {
            showPathCourseIfNeeded()
        }

        let route = Route.pathLesson(lessonID)
        guard path.last != route else { return }
        withAnimation(reduceMotion ? .none : .spring(response: 0.42, dampingFraction: 0.82)) {
            path.append(route)
        }
    }

    private func startCurrentMode() {
        startMode(viewModel.contentMode, topic: viewModel.topic)
    }

    private func startMode(_ mode: ContentMode, topic rawTopic: String) {
        let trimmed = rawTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        viewModel.contentMode = mode
        viewModel.topic = trimmed

        switch mode {
        case .learn, .story:
            viewModel.error = nil
            feedStartTopic = trimmed
            generationRequestID = UUID()
        case .path:
            pathCourseStartTopic = trimmed
            courseViewModel.prepareForPathRequest(topic: trimmed)
            showPathCourseIfNeeded()
            pathCourseRequestID = UUID()
        }
    }
}

#Preview {
    ContentView()
}
