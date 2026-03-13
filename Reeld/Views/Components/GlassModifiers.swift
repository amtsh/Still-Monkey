import SwiftUI

struct GlassBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S
    var interactive: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            content
                .background(.white.opacity(0.1), in: shape)
        }
    }
}

struct SubmitButtonBackgroundModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        content
            .background(
                Circle().fill(enabled ? Color.white.opacity(0.92) : Color.white.opacity(0.4))
            )
            .overlay(
                Circle().stroke(.white.opacity(enabled ? 0.35 : 0.2), lineWidth: 1)
            )
    }
}

struct SettingsSectionGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isConfigured: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(isConfigured ? Color.green.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var showBorder: Bool = true

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.white.opacity(showBorder ? 0.08 : 0), lineWidth: 1)
                )
        }
    }
}

extension View {
    func glassBackground<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        modifier(GlassBackgroundModifier(shape: shape, interactive: interactive))
    }

    func glassCard(cornerRadius: CGFloat = 14, showBorder: Bool = true) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, showBorder: showBorder))
    }
}
