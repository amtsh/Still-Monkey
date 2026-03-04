//
//  SettingsView.swift
//  Reeld
//
//  Created by Amit Shinde on 2026-03-04.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(Config.apiKeyUserDefaultsKey) private var apiKey: String = ""
    @State private var isTokenVisible = false
    @State private var showClearConfirm = false

    private var isConfigured: Bool { !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    introSection
                    statusBadge
                    apiKeySection
                    helpSection
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .top) {
            topHeader
        }
    }

    private var topHeader: some View {
        HStack {
            Text("Reeld")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(.black.opacity(0.94))
    }

    private var introSection: some View {
        Text("Connect your OpenRouter API key to generate learning reels. Your key stays on this device.")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.55))
    }

    // MARK: – Status badge

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConfigured ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
                .shadow(color: isConfigured ? .green.opacity(0.6) : .orange.opacity(0.5), radius: 4)

            Text(isConfigured ? "API token configured" : "API token required")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isConfigured ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            (isConfigured ? Color.green : Color.orange).opacity(0.1),
            in: Capsule()
        )
        .overlay(
            Capsule().stroke(
                (isConfigured ? Color.green : Color.orange).opacity(0.25),
                lineWidth: 1
            )
        )
        .contentTransition(.identity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isConfigured)
    }

    // MARK: – API key section

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("OpenRouter API Key")

            VStack(spacing: 0) {
                tokenField
                if isConfigured {
                    Divider().background(.white.opacity(0.07))
                    clearRow
                }
            }
            .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isConfigured ? Color.green.opacity(0.2) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isConfigured)

            HStack(spacing: 6) {
                Image(systemName: isConfigured ? "checkmark.circle.fill" : "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(isConfigured ? .green : .white.opacity(0.3))
                Text(
                    isConfigured
                        ? "Token saved automatically on this device"
                        : "Stored locally on your device only"
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
            }
            .contentTransition(.identity)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isConfigured)
        }
    }

    private var tokenField: some View {
        HStack(spacing: 0) {
            Group {
                if isTokenVisible {
                    TextField("sk-or-v1-…", text: $apiKey)
                        .font(.system(.body, design: .monospaced))
                } else {
                    SecureField("sk-or-v1-…", text: $apiKey)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
            .padding(.leading, 16)
            .padding(.vertical, 15)

            HStack(spacing: 4) {
                Button {
                    isTokenVisible.toggle()
                } label: {
                    Image(systemName: isTokenVisible ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.trailing, 4)
        }
    }

    private var clearRow: some View {
        Button(role: .destructive) {
            showClearConfirm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                Text("Remove token")
                    .font(.subheadline)
            }
            .foregroundStyle(.red.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .confirmationDialog("Remove API Token?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    apiKey = ""
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to re-enter your token to generate content.")
        }
    }

    // MARK: – Help section

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("How to get your token")

            VStack(spacing: 0) {
                helpRow(icon: "1.circle.fill", text: "Sign in to openrouter.ai")
                Divider().background(.white.opacity(0.07))
                helpRow(icon: "2.circle.fill", text: "Go to Settings → Keys")
                Divider().background(.white.opacity(0.07))
                Link(destination: URL(string: "https://openrouter.ai/settings/keys")!) {
                    helpRow(icon: "arrow.up.right.square", text: "Open OpenRouter API keys", isLink: true)
                }
            }
            .background(.white.opacity(0.05), in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.07), lineWidth: 1)
            )
        }
    }

    // MARK: – Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .bold()
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func helpRow(icon: String, text: String, isLink: Bool = false) -> some View {
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
