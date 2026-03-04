import SwiftUI

struct SettingsView: View {
    @AppStorage(Config.apiKeyUserDefaultsKey) private var apiKey: String = ""
    @State private var isTokenVisible = false
    @State private var showClearConfirm = false

    private var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    apiKeySection
                    helpSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .top) {
            topHeader
        }
    }

    private var topHeader: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(.black.opacity(0.94))
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OpenRouter API Key")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                Circle()
                    .fill(isConfigured ? .green : .orange)
                    .frame(width: 6, height: 6)
                Text(isConfigured ? "Configured" : "Required")
                    .font(.caption)
                    .foregroundStyle(isConfigured ? .green : .orange)
            }

            VStack(spacing: 0) {
                tokenField
                if isConfigured {
                    Divider().background(.white.opacity(0.07))
                    clearRow
                }
            }
            .modifier(SettingsSectionGlassModifier(cornerRadius: 14, isConfigured: isConfigured))

            Text("Stored locally on this device.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
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
                HapticsFeedback.impactMedium()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to re-enter your token to generate content.")
        }
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Need a key?")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                SettingsHelpRow(icon: "person.crop.circle", text: "Sign in to openrouter.ai")
                Divider().background(.white.opacity(0.06))
                SettingsHelpRow(icon: "key", text: "Open Settings -> Keys")
                Divider().background(.white.opacity(0.06))
                Link(destination: URL(string: "https://openrouter.ai/settings/keys")!) {
                    SettingsHelpRow(icon: "arrow.up.right.square", text: "Open API Keys page", isLink: true)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
}
