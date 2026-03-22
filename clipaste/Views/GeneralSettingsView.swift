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
    let subtitle: LocalizedStringKey?
    @ViewBuilder let trailing: Trailing

    init(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            trailing
        }
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var preferencesStore: AppPreferencesStore
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    @State private var showingClearAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                launchAndLanguageCard
                windowCard
                feedbackCard
                historyCard
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .frame(minWidth: 360, idealWidth: 420, maxWidth: .infinity, minHeight: 440, alignment: .top)
        .onAppear {
            preferencesStore.refreshLaunchAtLoginStatus()
        }
    }
}

// MARK: - Card 1: Launch & Language

private extension GeneralSettingsView {
    var launchAndLanguageCard: some View {
        SettingsCard(title: "启动与语言", systemImage: "globe") {
            VStack(spacing: 0) {
                SettingRow(
                    icon: "power",
                    title: "登录时启动 Clipaste"
                ) {
                    Toggle("", isOn: launchAtLoginBinding)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                cardDivider

                SettingRow(
                    icon: "paintbrush",
                    title: "外观"
                ) {
                    Picker("", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                }

                cardDivider

                SettingRow(
                    icon: "character.bubble",
                    title: "语言"
                ) {
                    Picker("", selection: $viewModel.appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
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

// MARK: - Card 2: Window

private extension GeneralSettingsView {
    var windowCard: some View {
        SettingsCard(title: "窗口", systemImage: "macwindow") {
            VStack(spacing: 0) {
                SettingRow(
                    icon: "rectangle.split.2x1",
                    title: "使用竖向列表布局",
                    subtitle: "横向卡片适合浏览，竖向列表适合快速切换和搜索"
                ) {
                    Toggle("", isOn: $viewModel.isVerticalLayout)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                if viewModel.isVerticalLayout {
                    cardDivider

                    SettingRow(
                        icon: "arrow.up.and.down",
                        title: "显示位置"
                    ) {
                        Picker("", selection: $viewModel.verticalFollowMode) {
                            ForEach(VerticalFollowMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .fixedSize()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isVerticalLayout)
        }
    }
}

// MARK: - Card 3: Feedback & Sound

private extension GeneralSettingsView {
    var feedbackCard: some View {
        SettingsCard(title: "反馈与声音", systemImage: "speaker.wave.2") {
            SettingRow(
                icon: "speaker.badge.exclamationmark",
                title: "复制提示音",
                subtitle: "复制内容到剪贴板后播放短促提示音"
            ) {
                Toggle("", isOn: $viewModel.isCopySoundEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Card 4: History

private extension GeneralSettingsView {
    var historyCard: some View {
        SettingsCard(title: "历史记录", systemImage: "clock.arrow.circlepath") {
            VStack(spacing: 0) {
                SettingRow(
                    icon: "calendar",
                    title: "保留时长"
                ) {
                    Picker("", selection: $viewModel.historyRetention) {
                        ForEach(HistoryRetention.allCases) { retention in
                            Text(retention.displayName).tag(retention)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                }

                cardDivider

                HStack {
                    Spacer()

                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        Label("清除历史记录…", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Text("永久删除所有剪贴板记录和图片缓存，此操作不可撤销")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
        }
        .alert("清除所有历史记录？", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("全部清除", role: .destructive) {
                StorageManager.shared.clearAllHistory()
            }
        } message: {
            Text("永久删除所有剪贴板记录和图片缓存，此操作不可撤销")
        }
    }
}

// MARK: - Shared UI

private extension GeneralSettingsView {
    var cardDivider: some View {
        Divider()
            .padding(.vertical, 10)
    }
}

// MARK: - Helpers

private extension GeneralSettingsView {
    var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { preferencesStore.launchAtLogin },
            set: { preferencesStore.updateLaunchAtLogin($0) }
        )
    }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(AppPreferencesStore.shared)
}
