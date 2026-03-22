import AppKit
import StoreKit
import SwiftUI

// MARK: - Settings Card Container

private struct SettingsCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            content
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color(.windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }
}

// MARK: - About Settings View

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
            VStack(spacing: 20) {
                brandSection
                proUpgradeCard
                linksCard
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Brand Header

private extension AboutSettingsView {
    var brandSection: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 84, height: 84)
                .clipShape(.rect(cornerRadius: 22))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

            Text(appName)
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.8)

            Text("\(String(localized: "Version")) \(shortVersion) (\(buildNumber))")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            Text("快速查看、搜索和重新粘贴最近复制的内容")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
                .padding(.top, 4)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Card 1: Pro Status

private extension AboutSettingsView {
    var proUpgradeCard: some View {
        SettingsCard(title: storeManager.isProUnlocked ? String(localized: "Clipaste Pro 已解锁") : "Clipaste Pro", systemImage: "sparkles") {
            VStack(alignment: .leading, spacing: 14) {
                // Subtitle
                Text(storeManager.isProUnlocked ? String(localized: "所有核心功能已就绪") : String(localized: "享受完整的 Clipaste Pro 体验"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Core features
                HStack(spacing: 24) {
                    featureItem(icon: "paintpalette.fill", text: String(localized: "Multiple Themes"))
                    featureItem(icon: "slider.horizontal.3", text: String(localized: "Custom Rules"))
                    featureItem(icon: "clock.arrow.circlepath", text: String(localized: "Unlimited History"))
                }
                .padding(.vertical, 2)

                // Action Button / Unlocked Badge
                if storeManager.isProUnlocked {
                    Text("已解锁")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: 6))
                } else {
                    Button {
                        storeManager.presentPaywall(from: .settings)
                    } label: {
                        if let proProduct = storeManager.proProduct {
                            Text(String(localized: "Unlock Pro Experience (\(proProduct.displayPrice) Lifetime)"))
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text(String(localized: "Unlock Pro"))
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .shadow(color: Color.accentColor.opacity(0.2), radius: 4, y: 2)
                }
            }
        }
    }

    func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Card 2: Links

private extension AboutSettingsView {
    var linksCard: some View {
        SettingsCard(title: String(localized: "关于与支持"), systemImage: "info.circle") {
            VStack(spacing: 0) {
                Button(action: sendFeedback) {
                    linkRow(
                        title: String(localized: "Send Feedback"),
                        systemImage: "paperplane"
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 10)

                Link(destination: privacyPolicyURL) {
                    linkRow(
                        title: String(localized: "Privacy Policy"),
                        systemImage: "lock.doc"
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 10)

                Link(destination: termsOfServiceURL) {
                    linkRow(
                        title: String(localized: "Terms of Service"),
                        systemImage: "doc.text"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    func linkRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    func sendFeedback() {
        guard let url = URL(string: "mailto:your_email@example.com?subject=Clipaste%20Feedback") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    AboutSettingsView()
        .environmentObject(StoreManager.shared)
}
