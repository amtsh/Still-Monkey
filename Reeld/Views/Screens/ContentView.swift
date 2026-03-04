import SwiftUI

struct ContentView: View {
    private enum Route: Hashable {
        case reels
    }

    @State private var viewModel = TopicViewModel()
    @State private var path: [Route] = []
    @State private var isShowingSettings = false
    @State private var generationRequestID: UUID?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                viewModel: viewModel,
                isSearchFocused: $isSearchFocused,
                onOpenSettings: {
                    isShowingSettings = true
                },
                onOpenFeed: {
                    isSearchFocused = false
                    showReelsIfNeeded()
                },
                onStartLearning: {
                    isSearchFocused = false
                    generationRequestID = UUID()
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
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading {
                    showReelsIfNeeded()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func showReelsIfNeeded() {
        guard path.last != .reels else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            path.append(.reels)
        }
    }
}

#Preview {
    ContentView()
}
