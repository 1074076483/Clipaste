import AppKit
import SwiftUI

// MARK: - Settings Card Container

private struct SettingsCard<Content: View>: View {
    let title: LocalizedStringKey
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

// MARK: - Setting Row

private struct SettingRow<Trailing: View>: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            trailing
        }
    }
}

// MARK: - Advanced Settings View

struct AdvancedSettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var runtimeStore: ClipboardRuntimeStore
    @EnvironmentObject private var storeManager: StoreManager
    @AppStorage("enable_smart_groups") private var isSmartGroupsEnabled: Bool = true
    @State private var showsDiagnostics = false
    @State private var copiedDiagnostics = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                coreInteractionCard
                interfaceCard
                migrationCard
                dataSyncCard
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .frame(minWidth: 360, idealWidth: 420, maxWidth: .infinity, minHeight: 440, alignment: .top)
    }
}

// MARK: - Card 1: Core Interaction & Behavior

private extension AdvancedSettingsView {
    var coreInteractionCard: some View {
        SettingsCard(title: "交互与行为", systemImage: "hand.tap") {
            VStack(spacing: 0) {
                // Paste Setting
                VStack(alignment: .leading, spacing: 8) {
                    SettingRow(
                        icon: "doc.on.clipboard",
                        title: "Auto-Paste to Active App on Double-Click",
                        subtitle: "关闭自动粘贴，仅复制"
                    ) {
                        Toggle("", isOn: $viewModel.autoPasteToActiveApp)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if viewModel.autoPasteToActiveApp {
                        Button("Open Accessibility Settings…", action: viewModel.openAccessibilitySettings)
                            .buttonStyle(.link)
                            .font(.subheadline)
                            .padding(.leading, 32)
                    }
                }

                cardDivider

                // Sort Setting
                SettingRow(
                    icon: "arrow.up.to.line",
                    title: "Move Item to Top After Pasting",
                    subtitle: "适合频繁重复使用刚粘贴过的内容"
                ) {
                    Toggle("", isOn: $viewModel.moveToTopAfterPaste)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                cardDivider

                // Text Format Setting
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "textformat")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Text Format")
                            .font(.body)
                        Text("按住 \(viewModel.plainTextModifier.pickerLabel) 可强制输出纯文本")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Picker("", selection: $viewModel.pasteTextFormat) {
                        ForEach(PasteTextFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                }
            }
        }
    }
}

// MARK: - Card 2: Interface

private extension AdvancedSettingsView {
    var interfaceCard: some View {
        SettingsCard(title: "界面", systemImage: "macwindow") {
            SettingRow(
                icon: "rectangle.3.group",
                title: "Show Smart Groups",
                subtitle: "在导航栏显示文本、链接、图片等分类标签"
            ) {
                Toggle("", isOn: $isSmartGroupsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Card 3: Migration Assistant

private extension AdvancedSettingsView {
    var migrationCard: some View {
        SettingsCard(title: "迁移助手", systemImage: "shippingbox") {
            MigrationView()
        }
    }
}

// MARK: - Card 4: Data Sync

private extension AdvancedSettingsView {
    var dataSyncCard: some View {
        SettingsCard(title: "数据同步", systemImage: "icloud") {
            VStack(alignment: .leading, spacing: 12) {
                // iCloud Sync Toggle
                Toggle(isOn: syncEnabledBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync via iCloud")
                            .font(.body)
                        Text("在使用同一 Apple ID 登录的所有 Mac 间无缝同步剪贴板历史")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                .disabled(runtimeStore.isSyncing)

                // Pro Lock Notice
                if !storeManager.hasFullAccess {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)

                        Text("CloudKit Private Database sync requires Clipaste Pro after the trial ends.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Unlock Pro") {
                            storeManager.presentPaywall(from: .settings, highlighting: .cloudSync)
                        }
                        .buttonStyle(.plain)
                        .font(.subheadline)
                        .bold()
                    }
                }

                // Sync Console
                if runtimeStore.isSyncEnabled {
                    Divider()

                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(syncStatusColor)
                                .frame(width: 8, height: 8)
                                .opacity(runtimeStore.isSyncing ? 0.5 : 1.0)
                                .animation(
                                    runtimeStore.isSyncing
                                        ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                        : .default,
                                    value: runtimeStore.isSyncing
                                )

                            syncStatusText
                        }

                        Spacer()

                        Button("Check iCloud Connection Status", systemImage: "arrow.triangle.2.circlepath") {
                            runtimeStore.refreshCurrentRoute()
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .font(.subheadline)
                        .bold()
                        .rotationEffect(Angle(degrees: runtimeStore.isSyncing ? 360 : 0))
                        .animation(
                            runtimeStore.isSyncing
                                ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: runtimeStore.isSyncing
                        )
                        .foregroundStyle(runtimeStore.isSyncing ? .secondary : Color.accentColor)
                        .disabled(runtimeStore.isSyncing)
                    }
                }

                diagnosticsPanel
            }
        }
    }
}

// MARK: - Shared UI Components

private extension AdvancedSettingsView {
    var cardDivider: some View {
        Divider()
            .padding(.vertical, 10)
    }
}

// MARK: - Helpers

private extension AdvancedSettingsView {
    var syncEnabledBinding: Binding<Bool> {
        Binding(
            get: { runtimeStore.isSyncEnabled },
            set: { newValue in
                if !newValue {
                    runtimeStore.setSyncEnabled(false)
                    return
                }

                guard storeManager.requestAccess(to: .cloudSync, from: .settings) else {
                    return
                }

                runtimeStore.setSyncEnabled(true)
            }
        )
    }

    var syncStatusColor: Color {
        if runtimeStore.isSyncing { return .blue }
        if runtimeStore.syncError != nil { return .red }
        return .green
    }

    @ViewBuilder
    var syncStatusText: some View {
        if runtimeStore.isSyncing {
            Text("Syncing…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if let error = runtimeStore.syncError {
            Text("Sync Failed: \(error)")
                .font(.subheadline)
                .foregroundStyle(.red)
        } else if let date = runtimeStore.lastSyncDate {
            Text("Last Sync: \(date, format: .dateTime.month().day().hour().minute())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("Waiting for First Sync…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var diagnosticsPanel: some View {
        DisclosureGroup(isExpanded: $showsDiagnostics) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Active Route")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.activeRoute == "cloud" ? String(localized: "iCloud") : String(localized: "Local"))
                }

                HStack {
                    Text("Current Toggle State")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.currentSyncEnabled ? String(localized: "On") : String(localized: "Off"))
                }

                HStack {
                    Text("Pending Toggle")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(pendingSyncDescription)
                }

                HStack {
                    Text("Local Runtime")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.localRuntimeReady ? String(localized: "Initialized") : String(localized: "Not Initialized"))
                }

                HStack {
                    Text("Cloud Runtime")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.cloudRuntimeReady ? String(localized: "Initialized") : String(localized: "Not Initialized"))
                }

                HStack {
                    Text("Runtime Generation")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.runtimeGeneration)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Local Store")
                        .foregroundStyle(.secondary)
                    Text(runtimeStore.diagnosticsSnapshot.localStorePath)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cloud Store")
                        .foregroundStyle(.secondary)
                    Text(runtimeStore.diagnosticsSnapshot.cloudStorePath)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                if let error = runtimeStore.diagnosticsSnapshot.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent Error")
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Recent Events")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(copiedDiagnostics ? String(localized: "Copied") : String(localized: "Copy Diagnostics")) {
                            copyDiagnosticsToPasteboard()
                        }
                        .buttonStyle(.borderless)
                        .disabled(runtimeStore.diagnosticsEntries.isEmpty)
                    }

                    if runtimeStore.diagnosticsEntries.isEmpty {
                        Text("No Events Recorded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(runtimeStore.diagnosticsEntries.prefix(8)) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.timestamp, format: .dateTime.hour().minute().second())
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)

                                Text(entry.level.rawValue)
                                    .font(.caption2.monospaced())
                                    .bold()
                                    .foregroundStyle(color(for: entry.level))

                                Text(entry.message)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Sync Diagnostics", systemImage: "stethoscope")
                .font(.subheadline)
        }
        .padding(.top, 2)
    }

    var pendingSyncDescription: String {
        guard let pending = runtimeStore.diagnosticsSnapshot.pendingSyncEnabled else {
            return String(localized: "None")
        }

        return pending ? String(localized: "Pending Enable") : String(localized: "Pending Disable")
    }

    func color(for level: ClipboardSyncDiagnosticLevel) -> Color {
        switch level {
        case .info:
            return .secondary
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    func copyDiagnosticsToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(runtimeStore.diagnosticsReport(), forType: .string)
        copiedDiagnostics = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedDiagnostics = false
        }
    }
}

#Preview {
    AdvancedSettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(ClipboardRuntimeStore.shared)
        .environmentObject(StoreManager.shared)
}
