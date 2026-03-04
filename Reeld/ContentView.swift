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
                HomeView(viewModel: viewModel)
            }
            Tab("Reels", systemImage: "play.fill", value: 1) {
                ReelsView(viewModel: viewModel)
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                SettingsView()
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
