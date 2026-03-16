import AppKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: StoreManager

    var body: some View {
        VStack(spacing: 0) {
            header
            featureGrid
            footer
        }
        .frame(width: 520)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(24)
        .onChange(of: storeManager.isProUnlocked) { _, unlocked in
            if unlocked {
                close()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()

                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 14, y: 8)

            VStack(spacing: 6) {
                Text("解锁 Clipaste Pro")
                    .font(.system(size: 28, weight: .bold))

                Text(storeManager.accessHeadline)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(featureHighlightText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 26)
    }

    private var featureGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                featureCard(
                    title: "无限历史记录",
                    subtitle: "不再只保留最近 10 条，完整浏览所有剪贴板历史。"
                )
                featureCard(
                    title: "高级搜索",
                    subtitle: "即时搜索文本、链接和代码片段，定位更快。"
                )
            }

            HStack(spacing: 12) {
                featureCard(
                    title: "纯文本快捷粘贴",
                    subtitle: "一键去除格式，保持清爽输出。"
                )
                featureCard(
                    title: "CloudKit 私有库同步",
                    subtitle: "在同一 Apple ID 的多台 Mac 间同步历史记录。"
                )
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await storeManager.purchasePro()
                }
            } label: {
                HStack(spacing: 8) {
                    if storeManager.isPurchaseInProgress {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }

                    Text(storeManager.purchaseButtonTitle)
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
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

                    Text("恢复购买")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(storeManager.isPurchaseInProgress || storeManager.isRestoreInProgress)

            Text(storeManager.accessFootnote)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            if let storeErrorMessage = storeManager.storeErrorMessage {
                Text(storeErrorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
    }

    private var featureHighlightText: String {
        if let highlightedFeature = storeManager.highlightedFeature {
            return "继续使用“\(highlightedFeature.title)”需要解锁 Pro。"
        }

        return "一次购买，永久解锁 Clipaste 的全部高级能力。"
    }

    private func featureCard(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func close() {
        storeManager.dismissPaywall()
        dismiss()
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager.shared)
}
