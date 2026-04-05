import SwiftUI

struct ContentView: View {
    private enum Route: Hashable {
        case reels
        case pathCourse
        case pathLesson(String)
        case bookmark(UUID)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = ReelFeedViewModel()
    @State private var courseViewModel = PathCourseViewModel()
    @State private var bookmarkStore = BookmarkStore()
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
                bookmarkStore: bookmarkStore,
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
                onOpenBookmark: { id in
                    isSearchFocused = false
                    showBookmarkIfNeeded(id)
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
                    ReelsView(viewModel: viewModel, bookmarkStore: bookmarkStore)
                case .pathCourse:
                    PathCourseView(
                        viewModel: courseViewModel,
                        onOpenLesson: { lessonID in
                            showPathLesson(lessonID)
                        },
                        onOpenSettings: {
                            isShowingSettings = true
                        }
                    )
                case .pathLesson(let lessonID):
                    PathLessonSessionView(
                        viewModel: PathLessonSessionViewModel(
                            courseViewModel: courseViewModel,
                            lessonID: lessonID
                        ),
                        bookmarkStore: bookmarkStore
                    )
                case .bookmark(let id):
                    bookmarkDestination(for: id)
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
                if let firstLessonID = courseViewModel.currentActionableLessonID {
                    _ = try? await courseViewModel.startOrRestoreLesson(lessonID: firstLessonID)
                }
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

    @ViewBuilder
    private func bookmarkDestination(for id: UUID) -> some View {
        if let entry = bookmarkStore.entries.first(where: { $0.id == id }) {
            BookmarkedContentView(entry: entry) {
                if case .bookmark(let bid) = path.last, bid == entry.id {
                    path.removeLast()
                }
                bookmarkStore.remove(id: entry.id)
            }
        } else {
            AppScreenCanvas(wash: .none) {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("This bookmark is no longer available.")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .appBlendedNavigationBar()
        }
    }

    private func showBookmarkIfNeeded(_ id: UUID) {
        let route = Route.bookmark(id)
        guard path.last != route else { return }
        withAnimation(reduceMotion ? .none : .spring(response: 0.42, dampingFraction: 0.82)) {
            path.append(route)
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
