import SwiftUI

struct ContentView: View {
    @State private var viewModel = TopicViewModel()
    @State private var isShowingFeed = false
    @State private var isShowingSettings = false
    @State private var generationRequestID: UUID?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                if isShowingFeed {
                    ReelsView(
                        viewModel: viewModel,
                        onBack: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                isShowingFeed = false
                            }
                        }
                    )
                    .transition(.opacity)
                } else {
                    HomeView(
                        viewModel: viewModel,
                        onOpenSettings: {
                            isShowingSettings = true
                        },
                        onOpenFeed: {
                            isSearchFocused = false
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                isShowingFeed = true
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isShowingFeed)
            .safeAreaInset(edge: .bottom) {
                if !isShowingFeed {
                    FloatingSearchBar(viewModel: viewModel, isSearchFocused: $isSearchFocused) {
                        generationRequestID = UUID()
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar(.hidden, for: .navigationBar)
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
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        isShowingFeed = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
