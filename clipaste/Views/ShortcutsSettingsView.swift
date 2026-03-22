import KeyboardShortcuts
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

// MARK: - Shortcuts Settings View

struct ShortcutsSettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                globalShortcutsCard
                navigationCard
                modifiersCard
                resetButton
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .frame(minWidth: 360, idealWidth: 420, maxWidth: .infinity, minHeight: 440, alignment: .top)
    }
}

// MARK: - Card 1: Global Shortcuts

private extension ShortcutsSettingsView {
    var globalShortcutsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsCard(title: "全局快捷键", systemImage: "command") {
                VStack(spacing: 0) {
                    ShortcutRecorderRow("显示 / 隐藏剪贴板面板", name: .toggleClipboardPanel)

                    cardDivider

                    ShortcutRecorderRow("切换竖向剪贴板", name: .toggleVerticalClipboard)
                }
            }

            Text("如果快捷键无法生效，请在系统设置 > 隐私与安全 > 辅助功能中允许 Clipaste。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }
}

// MARK: - Card 2: Navigation & Operations

private extension ShortcutsSettingsView {
    var navigationCard: some View {
        SettingsCard(title: "导航与操作", systemImage: "arrow.left.arrow.right") {
            VStack(spacing: 0) {
                ShortcutRecorderRow("下一个列表", name: .nextList)

                cardDivider

                ShortcutRecorderRow("上一个列表", name: .prevList)

                cardDivider

                ShortcutRecorderRow("清空剪贴板历史", name: .clearHistory)
            }
        }
    }
}

// MARK: - Card 3: Modifiers

private extension ShortcutsSettingsView {
    var modifiersCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsCard(title: "修饰键", systemImage: "option") {
                VStack(spacing: 0) {
                    ModifierPickerView(
                        title: "快速粘贴",
                        suffix: "+ 1…9",
                        selection: $viewModel.quickPasteModifier
                    )

                    cardDivider

                    ModifierPickerView(
                        title: "纯文本模式",
                        suffix: "",
                        selection: $viewModel.plainTextModifier
                    )
                }
            }

            Text("按住快速粘贴修饰键可显示 1…9 快捷编号；按住纯文本修饰键复制或粘贴时自动去除格式。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }
}

// MARK: - Reset Button

private extension ShortcutsSettingsView {
    var resetButton: some View {
        Button {
            KeyboardShortcuts.reset(
                .toggleClipboardPanel,
                .toggleVerticalClipboard,
                .nextList,
                .prevList,
                .clearHistory
            )
        } label: {
            Label("恢复默认快捷键", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .controlSize(.regular)
        .buttonStyle(.bordered)
    }
}

// MARK: - Shared UI

private extension ShortcutsSettingsView {
    var cardDivider: some View {
        Divider()
            .padding(.vertical, 10)
    }
}

// MARK: - Shortcut Recorder Row

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
        HStack {
            Text(title)
                .font(.body)

            Spacer()

            HStack(spacing: 8) {
                shortcutRecorder

                if name.defaultShortcut != nil {
                    Button("Restore Default Shortcut", systemImage: "arrow.uturn.backward") {
                        KeyboardShortcuts.reset(name)
                        shortcut = name.shortcut
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(!canRestoreDefault)
                }
            }
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

#Preview {
    ShortcutsSettingsView()
        .environmentObject(SettingsViewModel())
}
