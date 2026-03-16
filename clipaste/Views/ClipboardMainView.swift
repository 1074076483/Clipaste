import SwiftUI

struct ClipboardMainView: View {
    @EnvironmentObject private var runtimeStore: ClipboardRuntimeStore
    @Environment(\.openSettings) private var openSettings
    @StateObject var viewModel = ClipboardViewModel()
    @AppStorage("clipboardLayout") private var clipboardLayout: AppLayoutMode = .horizontal
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @FocusState private var isSearchFocused: Bool

    @State private var viewRebuildToken: Bool = false
    private let searchService = TypeToSearchService.shared

    var body: some View {
        Group {
            if clipboardLayout == .horizontal {
                VStack(spacing: 0) {
                    ClipboardHeaderView(viewModel: viewModel, isSearchFocused: _isSearchFocused)
                    mainContent
                }
            } else {
                mainContent
                    .safeAreaInset(edge: .top, spacing: 0) {
                        ClipboardHeaderView(viewModel: viewModel, isSearchFocused: _isSearchFocused)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        HStack {
                            Text("\(viewModel.filteredItems.count) 个项目")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .padding(.top, 4)
                        .background(.regularMaterial)
                    }
            }
        }
        .id("\(runtimeStore.rootIdentity)-\(viewRebuildToken)")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .background(
            ClipboardPanelWindowObserver(
                onWindowDidBecomeKey: activatePanelInputHandling,
                onWindowDidResignKey: deactivatePanelInputHandling
            )
        )
        .background(WindowAppearanceObserver(theme: appTheme))
        .clipShape(RoundedRectangle(cornerRadius: clipboardLayout == .vertical ? 14 : 0))
        .preferredColorScheme(appTheme.colorScheme)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: clipboardLayout) {
            NotificationCenter.default.post(
                name: .clipboardLayoutModeChanged,
                object: clipboardLayout
            )
            DispatchQueue.main.async {
                viewRebuildToken.toggle()
            }
        }
        // ── 智能失焦：用户点选卡片后自动将搜索框失焦 ─────────────────
        .onChange(of: viewModel.selectedItemIDs) { _, newValue in
            if !newValue.isEmpty {
                isSearchFocused = false
            }
        }
        // ── 实时同步焦点状态给盲打服务 ─────────────────────────
        .onChange(of: isSearchFocused) { _, newValue in
            searchService.isTextFieldFocused = newValue
        }
        .onChange(of: viewModel.quickPasteModifier) { _, _ in
            syncReservedSearchModifiers()
        }
        .onChange(of: viewModel.plainTextModifier) { _, _ in
            syncReservedSearchModifiers()
        }
        .onAppear {
            searchService.onCapture = { [weak viewModel] char in
                viewModel?.appendBlindTypedCharacter(char)
            }
            searchService.onRequireFocus = { isSearchFocused = true }
            syncReservedSearchModifiers()
        }
        .onDisappear {
            deactivatePanelInputHandling()
        }
        // ── ⌘, 意图通知 → 调用 SwiftUI 原生 openSettings ───────────
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsIntent)) { _ in
            SettingsWindowCoordinator.open {
                openSettings()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchFieldIntent)) { _ in
            focusSearchField()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.filteredItems.isEmpty {
            ClipboardEmptyStateView(viewModel: viewModel)
        } else {
            switch clipboardLayout {
            case .horizontal:
                ClipboardHorizontalView(viewModel: viewModel)
            case .vertical:
                ClipboardVerticalListView(viewModel: viewModel)
            }
        }
    }

    private func focusSearchField() {
        DispatchQueue.main.async { isSearchFocused = true }
    }

    private func activatePanelInputHandling() {
        viewModel.startKeyboardMonitoring()
        syncReservedSearchModifiers()
        // 先启动面板级键盘监听，再启动盲打搜索，确保特殊按键优先被 ViewModel 消费。
        searchService.start()
        searchService.isTextFieldFocused = isSearchFocused
    }

    private func deactivatePanelInputHandling() {
        searchService.stop()
        viewModel.stopKeyboardMonitoring()
    }

    private func syncReservedSearchModifiers() {
        searchService.reservedModifierFlags = viewModel.reservedSearchModifierFlags
    }
}

#Preview {
    ClipboardMainView()
        .environmentObject(ClipboardRuntimeStore.shared)
}
