//
//  ContentView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = TopicViewModel()
    @State private var isShowingFeed = false
    @State private var isShowingSettings = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            if isShowingFeed {
                NavigationStack {
                    ReelsView(
                        viewModel: viewModel,
                        onBack: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                isShowingFeed = false
                            }
                        }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
                .transition(.opacity)
            } else {
                NavigationStack {
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
                    .toolbar(.hidden, for: .navigationBar)
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isShowingFeed)
        .safeAreaInset(edge: .bottom) {
            if !isShowingFeed {
                FloatingSearchBar(viewModel: viewModel, isSearchFocused: $isSearchFocused) {
                    Task { await viewModel.generateContent() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if isLoading {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isShowingFeed = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
