import AppKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var storeManager: StoreManager

    private let proFeatures: [(icon: String, title: LocalizedStringKey)] = [
        ("clock.arrow.circlepath", "Unlimited History"),
        ("magnifyingglass", "Advanced Search"),
        ("doc.plaintext", "Plain Text Quick Paste"),
        ("icloud.fill", "CloudKit Private Sync"),
        ("paintpalette.fill", "Multiple Themes"),
        ("slider.horizontal.3", "Custom Rules")
    ]

    var body: some View {
        ZStack {
            ambientBackground

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(glassStrokeColor, lineWidth: 0.8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.55), lineWidth: 0.5)
                        .padding(1)
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.14), radius: 40, y: 20)

            VStack(spacing: 0) {
                topBar
                header
                featureList
                priceHero
                footer
            }
            .padding(.horizontal, 30)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .frame(width: 480)
        .padding(22)
        .onChange(of: storeManager.isProUnlocked) { _, unlocked in
            if unlocked {
                close()
            }
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.28 : 0.24))
                .frame(width: 280, height: 280)
                .blur(radius: 110)
                .offset(x: -170, y: -160)

            Circle()
                .fill(Color.indigo.opacity(colorScheme == .dark ? 0.24 : 0.2))
                .frame(width: 260, height: 260)
                .blur(radius: 120)
                .offset(x: 185, y: -110)

            Circle()
                .fill(Color.cyan.opacity(colorScheme == .dark ? 0.16 : 0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 120)
                .offset(x: 120, y: 210)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
    }

    // MARK: - Top Bar (Close)

    private var topBar: some View {
        HStack {
            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(glassStrokeColor, lineWidth: 0.6)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Header (Icon + Title)

    private var header: some View {
        VStack(spacing: 14) {
            appIconHero

            VStack(spacing: 6) {
                Text("Clipaste Pro Lifetime Membership")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.8)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(storeManager.accessHeadline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 24)
    }

    private var appIconHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.85),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(glassStrokeColor, lineWidth: 0.8)
                )

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 78, height: 78)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .accentColor.opacity(0.4), radius: 30, x: 0, y: 10)
        }
    }

    // MARK: - Feature List (Compact Vertical)

    private var featureList: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(proFeatures, id: \.icon) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentColor)

                    Text(feature.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 28)
    }

    // MARK: - Price Hero (Prominent ¥49)

    private var priceHero: some View {
        VStack(spacing: 6) {
            Text(storeManager.localizedLifetimePrice)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .tracking(-1.5)
                .foregroundStyle(Color.accentColor)

            Text(storeManager.lifetimePriceSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Footer (CTA + Restore + Error)

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await storeManager.purchasePro()
                }
            } label: {
                HStack(spacing: 10) {
                    if storeManager.isPurchaseInProgress {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }

                    Text(storeManager.purchaseButtonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(PaywallCTAButtonStyle())
            .disabled(storeManager.isPurchaseInProgress || storeManager.isRestoreInProgress)

            Button {
                Task {
                    await storeManager.restorePurchases()
                }
            } label: {
                HStack(spacing: 8) {
                    if storeManager.isRestoreInProgress {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text("Restore Purchase")
                        .font(.caption.weight(.semibold))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(storeManager.isPurchaseInProgress || storeManager.isRestoreInProgress)

            Text(storeManager.accessFootnote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            if let storeErrorMessage = storeManager.storeErrorMessage {
                Text(storeErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
    }

    // MARK: - Helpers

    private var glassStrokeColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.14 : 0.34)
    }

    private func close() {
        storeManager.dismissPaywall()
        dismiss()
    }
}

// MARK: - CTA Button Style

private struct PaywallCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.22, blue: 0.55),
                        Color(red: 0.12, green: 0.41, blue: 0.86),
                        Color(red: 0.33, green: 0.67, blue: 0.98)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.24), lineWidth: 0.7)
            )
            .shadow(color: Color.blue.opacity(configuration.isPressed ? 0.18 : 0.34), radius: 22, y: 14)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager.shared)
}
