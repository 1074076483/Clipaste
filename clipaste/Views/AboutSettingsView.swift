import AppKit
import SwiftUI

// MARK: - Settings Card Container

private struct SettingsCard<Content: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .settingsSectionTitle()

            content
                .liquidGlassCard()
        }
        .padding(.bottom, 16)
    }
}

// MARK: - About Settings View

struct AboutSettingsView: View {
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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                brandSection
                featureOverviewCard
                linksCard
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .settingsScrollChromeHidden()
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

            HStack(spacing: 0) {
                Text("Version")
                Text(verbatim: " \(shortVersion)")
            }
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Quickly review, search, and re-paste recently copied content.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
                .padding(.top, 4)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Card 1: Feature Overview

private extension AboutSettingsView {
    var featureOverviewCard: some View {
        SettingsCard(
            title: "Feature Overview",
            systemImage: "sparkles"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("All core capabilities are available in the open-source build.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 24) {
                    featureItem(icon: "clock.arrow.circlepath", title: "Unlimited History")
                    featureItem(icon: "magnifyingglass", title: "Search")
                    featureItem(icon: "icloud.fill", title: "iCloud Sync")
                }
                .padding(.vertical, 2)

                HStack(spacing: 24) {
                    featureItem(icon: "doc.plaintext", title: "Plain Text Paste")
                    featureItem(icon: "slider.horizontal.3", title: "Custom Rules")
                    featureItem(icon: "paintpalette.fill", title: "Multiple Themes")
                }
                .padding(.vertical, 2)
            }
        }
    }

    func featureItem(icon: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.accentColor)
            Text(title)
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
        SettingsCard(title: "About & Support", systemImage: "info.circle") {
            VStack(spacing: 0) {
                Button(action: sendFeedback) {
                    linkRow(
                        title: "Send Feedback",
                        systemImage: "paperplane"
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 10)

                Link(destination: privacyPolicyURL) {
                    linkRow(
                        title: "Privacy Policy",
                        systemImage: "lock.doc"
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 10)

                Link(destination: termsOfServiceURL) {
                    linkRow(
                        title: "Terms of Service",
                        systemImage: "doc.text"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    func linkRow(title: LocalizedStringKey, systemImage: String) -> some View {
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
}
