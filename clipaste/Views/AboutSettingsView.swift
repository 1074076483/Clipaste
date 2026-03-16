import SwiftUI
import AppKit

struct AboutSettingsView: View {
    @EnvironmentObject private var storeManager: StoreManager
    private let privacyPolicyURL = URL(string: "https://legal.clipaste.com/?page=privacy")!
    private let termsOfServiceURL = URL(string: "https://legal.clipaste.com/?page=terms")!

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Clipaste"
    }

    private var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 82, height: 82)
                        .clipShape(.rect(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)

                    Text(appName)
                        .font(.title.weight(.bold))

                    Text("\(String(localized: "Version")) \(shortVersion) (\(buildNumber))")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text("Quickly recall, search and re-paste recently copied content.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                        .padding(.top, 6)
                }

                VStack(spacing: 0) {
                    commerceCard

                    Divider()
                        .padding(.leading, 48)

                    Button(action: sendFeedback) {
                        actionRowLabel(
                            title: String(localized: "Send Feedback"),
                            systemImage: "paperplane"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 48)

                    Link(destination: privacyPolicyURL) {
                        actionRowLabel(
                            title: "Privacy Policy",
                            systemImage: "lock.doc"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 48)

                    Link(destination: termsOfServiceURL) {
                        actionRowLabel(
                            title: "Terms of Service",
                            systemImage: "doc.text"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 420)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.75))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.top, 36)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var commerceCard: some View {
        HStack(spacing: 12) {
            Image(systemName: storeManager.isProUnlocked ? "checkmark.seal.fill" : "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(storeManager.isProUnlocked ? .green : .accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(storeManager.isProUnlocked ? "Clipaste Pro 已解锁" : storeManager.accessHeadline)
                    .font(.system(size: 13, weight: .semibold))

                Text(storeManager.isProUnlocked ? "当前 Apple ID 已拥有买断授权。" : "一次购买，永久解锁无限历史记录、高级搜索和同步能力。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            if !storeManager.isProUnlocked {
                Button("解锁 Pro") {
                    storeManager.presentPaywall(from: .settings)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func sendFeedback() {
        guard let url = URL(string: "mailto:your_email@example.com?subject=Clipaste%20Feedback") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func actionRowLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.primary)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 12)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    AboutSettingsView()
        .environmentObject(StoreManager.shared)
}
