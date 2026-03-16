import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {
        Form {
            // ── 全局唤醒 ──
            Section {
                ShortcutRecorderRow("Show / Hide Clipboard Panel", name: .toggleClipboardPanel)
                ShortcutRecorderRow("Toggle Vertical Clipboard", name: .toggleVerticalClipboard)
            } header: {
                Text("Global Shortcuts")
            } footer: {
                Text("If the shortcut doesn't work, allow Clipaste in System Settings > Privacy & Security > Accessibility.")
            }

            // ── 导航与操作 ──
            Section {
                ShortcutRecorderRow("Next List", name: .nextList)
                ShortcutRecorderRow("Previous List", name: .prevList)
                ShortcutRecorderRow("Clear Clipboard History", name: .clearHistory)
            } header: {
                Text("Navigation & Actions")
            }

            // ── 修饰键 ──
            Section {
                ModifierPickerView(
                    title: String(localized: "Quick Paste"),
                    suffix: "+ 1…9",
                    selection: $viewModel.quickPasteModifier
                )
                ModifierPickerView(
                    title: String(localized: "Plain Text Mode"),
                    suffix: "",
                    selection: $viewModel.plainTextModifier
                )
            } header: {
                Text("Modifier Keys")
            } footer: {
                Text("Hold the quick paste modifier to reveal 1…9 shortcuts. Hold the plain text modifier while copying or pasting to strip formatting.")
            }

            // ── 重置 ──
            Section {
                Button {
                    KeyboardShortcuts.reset(
                        .toggleClipboardPanel,
                        .toggleVerticalClipboard,
                        .nextList,
                        .prevList,
                        .clearHistory
                    )
                } label: {
                    Label("Reset Shortcuts to Defaults", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.regular)
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.hidden)
        .frame(minWidth: 360, idealWidth: 420, maxWidth: .infinity, minHeight: 440, alignment: .top)
    }
}

#Preview {
    ShortcutsSettingsView()
        .environmentObject(SettingsViewModel())
}

private struct ShortcutRecorderRow: View {
    let title: LocalizedStringKey
    let name: KeyboardShortcuts.Name

    @State private var shortcut: KeyboardShortcuts.Shortcut?

    init(_ title: LocalizedStringKey, name: KeyboardShortcuts.Name) {
        self.title = title
        self.name = name
        _shortcut = State(initialValue: name.shortcut)
    }

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) {
                shortcutRecorder

                if name.defaultShortcut != nil {
                    Button {
                        KeyboardShortcuts.reset(name)
                        shortcut = name.shortcut
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .help(String(localized: "Restore Default Shortcut"))
                    .accessibilityLabel(Text("Restore Default Shortcut"))
                    .disabled(!canRestoreDefault)
                }

            }
        } label: {
            Text(title)
        }
    }

    private var canRestoreDefault: Bool {
        guard let defaultShortcut = name.defaultShortcut else {
            return false
        }

        return shortcut != defaultShortcut
    }

    private var shortcutRecorder: some View {
        KeyboardShortcuts.Recorder(for: name) { newShortcut in
            shortcut = newShortcut
        }
        .frame(minWidth: 140)
        .overlay(alignment: .trailing) {
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor))
                .frame(width: 28, height: 22)
                .padding(.trailing, 6)
                .allowsHitTesting(false)
        }
    }
}
