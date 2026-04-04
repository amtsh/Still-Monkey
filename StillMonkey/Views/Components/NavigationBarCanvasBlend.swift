//
//  NavigationBarCanvasBlend.swift
//  Still Monkey
//
//  SwiftUI’s `toolbarBackgroundVisibility(.hidden)` alone often still leaves a material / glass bar on
//  recent iOS versions. This anchors into the navigation controller and applies an opaque appearance
//  that matches `Config.Brand.backgroundDark` so the bar matches `AppScreenBackground`.
//

import SwiftUI
import UIKit

private extension UIColor {
    /// Matches `Config.Brand.backgroundDark` (#0D0D0D).
    static let appCanvas = UIColor(red: 0.051, green: 0.051, blue: 0.051, alpha: 1)
}

/// Calls back when the hosting controller joins a `UINavigationController` (needed because `navigationController` can be nil on first layout).
final class NavigationBarBlendAnchorViewController: UIViewController {
    var onNavigationController: ((UINavigationController?) -> Void)?

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        onNavigationController?(navigationController)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onNavigationController?(navigationController)
    }
}

struct NavigationBarCanvasBlend: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> NavigationBarBlendAnchorViewController {
        let vc = NavigationBarBlendAnchorViewController()
        vc.view.backgroundColor = .clear
        vc.view.isUserInteractionEnabled = false
        vc.onNavigationController = { nav in
            context.coordinator.apply(to: nav)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: NavigationBarBlendAnchorViewController, context: Context) {
        context.coordinator.apply(to: uiViewController.navigationController)
    }

    final class Coordinator {
        func apply(to nav: UINavigationController?) {
            guard let nav else { return }
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .appCanvas
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            let bar = nav.navigationBar
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
            bar.compactScrollEdgeAppearance = appearance
            bar.isTranslucent = false
        }
    }
}
