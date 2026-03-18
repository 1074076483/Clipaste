import AppKit
import SwiftUI

struct AdvancedSettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var runtimeStore: ClipboardRuntimeStore
    @EnvironmentObject private var storeManager: StoreManager
    @AppStorage("enable_smart_groups") private var isSmartGroupsEnabled: Bool = true
    @State private var showsDiagnostics = false
    @State private var copiedDiagnostics = false

    var body: some View {
        Form {
            // ── Paste ──
            Section {
                Toggle("Auto-Paste to Active App on Double-Click", isOn: $viewModel.autoPasteToActiveApp)
                    .toggleStyle(.switch)

                if viewModel.autoPasteToActiveApp {
                    Button("Open Accessibility Settings…") {
                        viewModel.openAccessibilitySettings()
                    }
                    .buttonStyle(.link)
                }
            } header: {
                Text("Paste")
            } footer: {
                Text("When disabled, double-clicking an item only copies it to the clipboard without sending the paste shortcut.")
            }

            // ── Sort & Behavior ──
            Section {
                Toggle("Move Item to Top After Pasting", isOn: $viewModel.moveToTopAfterPaste)
                    .toggleStyle(.switch)
            } header: {
                Text("Sort & Behavior")
            } footer: {
                Text("Useful when you repeatedly paste the same content.")
            }

            // ── Text Format ──
            Section {
                Picker("Default Text Format", selection: $viewModel.pasteTextFormat) {
                    ForEach(PasteTextFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Text Format")
            } footer: {
                Text("Hold \(viewModel.plainTextModifier.pickerLabel) while copying or pasting to force plain text output.")
            }

            MigrationView()

            // ── Interface ──
            Section {
                Toggle("Show Smart Groups", isOn: $isSmartGroupsEnabled)
                    .toggleStyle(.switch)
            } header: {
                Text("Interface")
            } footer: {
                Text("Display preset category tabs like Text, Links, and Images in the navigation bar.")
            }

            // ── iCloud Sync ──
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: syncEnabledBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sync via iCloud")
                                .font(.system(size: 14, weight: .medium))

                            Text("Seamlessly sync clipboard history across all Macs signed in with the same Apple ID.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                    }
                    .toggleStyle(.switch)
                    .disabled(runtimeStore.isSyncing)

                    if !storeManager.hasFullAccess {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)

                            Text("CloudKit Private Database sync requires Clipaste Pro after the trial ends.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Unlock Pro") {
                                storeManager.presentPaywall(from: .settings, highlighting: .cloudSync)
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                        }
                    }

                    // Show advanced console panel when sync is enabled
                    if runtimeStore.isSyncEnabled {
                        Divider()
                            .padding(.vertical, 4)

                        HStack {
                            // Status indicator
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

                            // Sync Now button
                            Button {
                                runtimeStore.refreshCurrentRoute()
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12, weight: .semibold))
                                    .rotationEffect(Angle(degrees: runtimeStore.isSyncing ? 360 : 0))
                                    .animation(
                                        runtimeStore.isSyncing
                                            ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                                            : .default,
                                        value: runtimeStore.isSyncing
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(runtimeStore.isSyncing ? .secondary : .accentColor)
                            .disabled(runtimeStore.isSyncing)
                            .help(String(localized: "Check iCloud Connection Status"))
                        }
                    }

                    diagnosticsPanel
                }
                .padding(.vertical, 4)
            } header: {
                Text("Data Sync")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.hidden)
        .frame(minWidth: 360, idealWidth: 420, maxWidth: .infinity, minHeight: 440, alignment: .top)
    }

    // MARK: - Helpers

    private var syncEnabledBinding: Binding<Bool> {
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

    private var syncStatusColor: Color {
        if runtimeStore.isSyncing { return .blue }
        if runtimeStore.syncError != nil { return .red }
        return .green
    }

    @ViewBuilder
    private var syncStatusText: some View {
        if runtimeStore.isSyncing {
            Text("Syncing…")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        } else if let error = runtimeStore.syncError {
            Text("Sync Failed: \(error)")
                .font(.system(size: 12))
                .foregroundColor(.red)
        } else if let date = runtimeStore.lastSyncDate {
            Text("Last Sync: \(date, format: .dateTime.month().day().hour().minute())")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        } else {
            Text("Waiting for First Sync…")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private var diagnosticsPanel: some View {
        DisclosureGroup(isExpanded: $showsDiagnostics) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Active Route")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.activeRoute == "cloud" ? String(localized: "iCloud") : String(localized: "Local"))
                }

                HStack {
                    Text("Current Toggle State")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.currentSyncEnabled ? String(localized: "On") : String(localized: "Off"))
                }

                HStack {
                    Text("Pending Toggle")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(pendingSyncDescription)
                }

                HStack {
                    Text("Local Runtime")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.localRuntimeReady ? String(localized: "Initialized") : String(localized: "Not Initialized"))
                }

                HStack {
                    Text("Cloud Runtime")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.cloudRuntimeReady ? String(localized: "Initialized") : String(localized: "Not Initialized"))
                }

                HStack {
                    Text("Runtime Generation")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(runtimeStore.diagnosticsSnapshot.runtimeGeneration)
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Local Store")
                        .foregroundColor(.secondary)
                    Text(runtimeStore.diagnosticsSnapshot.localStorePath)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cloud Store")
                        .foregroundColor(.secondary)
                    Text(runtimeStore.diagnosticsSnapshot.cloudStorePath)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }

                if let error = runtimeStore.diagnosticsSnapshot.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent Error")
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .textSelection(.enabled)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Recent Events")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(copiedDiagnostics ? String(localized: "Copied") : String(localized: "Copy Diagnostics")) {
                            copyDiagnosticsToPasteboard()
                        }
                        .buttonStyle(.borderless)
                        .disabled(runtimeStore.diagnosticsEntries.isEmpty)
                    }

                    if runtimeStore.diagnosticsEntries.isEmpty {
                        Text("No Events Recorded")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(runtimeStore.diagnosticsEntries.prefix(8)) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.timestamp, format: .dateTime.hour().minute().second())
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)

                                Text(entry.level.rawValue)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(color(for: entry.level))

                                Text(entry.message)
                                    .font(.system(size: 11))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Text("Sync Diagnostics")
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.top, 2)
    }

    private var pendingSyncDescription: String {
        guard let pending = runtimeStore.diagnosticsSnapshot.pendingSyncEnabled else {
            return String(localized: "None")
        }

        return pending ? String(localized: "Pending Enable") : String(localized: "Pending Disable")
    }

    private func color(for level: ClipboardSyncDiagnosticLevel) -> Color {
        switch level {
        case .info:
            return .secondary
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    private func copyDiagnosticsToPasteboard() {
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
