//
//  HomeHeroCardView.swift
//  Still Monkey
//

import SwiftUI

struct HomeHeroCardView: View {
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12:
            return "Good morning"
        case 12 ..< 17:
            return "Good afternoon"
        case 17 ..< 22:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(greeting)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.85)

            Text("What do you want to learn?")
                .font(.subheadline.weight(.regular))
                .foregroundStyle(Config.Brand.readableSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: HomeLayout.heroCardHeight, alignment: .center)
    }
}
