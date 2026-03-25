//
//  HomeHeroCardView.swift
//  Still Monkey
//

import SwiftUI

struct HomeHeroCardView: View {
    var body: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - 40, 0)
            let leftWidth = contentWidth * 0.7
            let rightWidth = contentWidth * 0.3

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Feed your curiosity.")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Config.Brand.focusColor,
                                    Config.Brand.longBreakColor,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Learn something real.")
                        .font(.subheadline)
                        .foregroundStyle(Config.Brand.readableSecondaryText)
                        .lineSpacing(2)
                }
                .frame(width: leftWidth, alignment: .leading)

                LottieView(name: "flower_plant", speed: 0.9)
                    .frame(width: rightWidth, height: proxy.size.height - 40)
                    .opacity(0.95)
            }
            .padding(.horizontal, HomeLayout.horizontalContentInset)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .frame(height: HomeLayout.heroCardHeight)
        .glassCard(cornerRadius: 24)
    }
}
