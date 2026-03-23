import SwiftUI

struct ContentView: View {
    private enum Route: Hashable {
        case reels
        case duolingoCourse
        case duolingoLesson(String)
    }

    @State private var viewModel = TopicViewModel()
    @State private var courseViewModel = DuolingoCourseViewModel()
    @State private var path: [Route] = []
    @State private var isShowingSettings = false
    @State private var generationRequestID: UUID?
    @State private var duolingoCourseRequestID: UUID?
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
                    showDuolingoCourseIfNeeded()
                },
                onStartLearning: {
                    isSearchFocused = false
                    startCurrentMode()
                }
            )
            .safeAreaInset(edge: .bottom) {
                if path.isEmpty {
                    FloatingSearchBar(viewModel: viewModel)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .reels:
                    ReelsView(viewModel: viewModel)
                case .duolingoCourse:
                    DuolingoCourseView(viewModel: courseViewModel) { lessonID in
                        showDuolingoLesson(lessonID)
                    }
                case .duolingoLesson(let lessonID):
                    DuolingoLessonSessionView(
                        viewModel: DuolingoLessonSessionViewModel(
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
                await viewModel.generateContent()
                generationRequestID = nil
            }
            .task(id: duolingoCourseRequestID) {
                guard duolingoCourseRequestID != nil else { return }
                await courseViewModel.startCourse(for: viewModel.topic)
                duolingoCourseRequestID = nil
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
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            path.append(.reels)
        }
    }

    private func showDuolingoCourseIfNeeded() {
        if let courseIndex = path.firstIndex(of: .duolingoCourse) {
            path = Array(path.prefix(courseIndex + 1))
            return
        }

        if path.contains(.reels) {
            path.removeAll()
        }

        guard path.last != .duolingoCourse else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            path.append(.duolingoCourse)
        }
    }

    private func showDuolingoLesson(_ lessonID: String) {
        if let courseIndex = path.firstIndex(of: .duolingoCourse) {
            path = Array(path.prefix(courseIndex + 1))
        } else {
            showDuolingoCourseIfNeeded()
        }

        let route = Route.duolingoLesson(lessonID)
        guard path.last != route else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            path.append(route)
        }
    }

    private func startCurrentMode() {
        switch viewModel.contentMode {
        case .learn, .story:
            generationRequestID = UUID()
        case .duolingo:
            showDuolingoCourseIfNeeded()
            duolingoCourseRequestID = UUID()
        }
    }
}

#Preview {
    ContentView()
}
