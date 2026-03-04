//
//  ContentView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = TopicViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Learn", systemImage: "sparkles", value: 0) {
                NavigationStack {
                    HomeView(viewModel: viewModel)
                        .navigationTitle("Reeld")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            Tab("Reels", systemImage: "play.fill", value: 1) {
                NavigationStack {
                    ReelsView(
                        viewModel: viewModel,
                        onBack: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                selectedTab = 0
                            }
                        }
                    )
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Reeld")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
        }
        .tint(.white)
        .preferredColorScheme(.dark)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if isLoading {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    selectedTab = 1
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
