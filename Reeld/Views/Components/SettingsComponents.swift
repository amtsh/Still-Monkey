import SwiftUI

struct SettingsStatusBadge: View {
    let isConfigured: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConfigured ? .green : .orange)
                .frame(width: 7, height: 7)
                .shadow(color: isConfigured ? .green.opacity(0.6) : .orange.opacity(0.5), radius: 4)

            Text(isConfigured ? "API token configured" : "API token required")
                .font(.caption.weight(.medium))
                .foregroundStyle(isConfigured ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background((isConfigured ? Color.green : Color.orange).opacity(0.1), in: Capsule())
        .overlay(
            Capsule().stroke((isConfigured ? Color.green : Color.orange).opacity(0.25), lineWidth: 1)
        )
        .contentTransition(.identity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isConfigured)
    }
}

struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .bold()
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

struct SettingsHelpRow: View {
    let icon: String
    let text: String
    var isLink = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isLink ? .blue : .white.opacity(0.35))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(isLink ? .blue : .white.opacity(0.7))
            Spacer()
            if isLink {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.blue.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
