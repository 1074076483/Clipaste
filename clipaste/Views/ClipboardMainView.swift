import SwiftUI

struct ClipboardMainView: View {
    @EnvironmentObject private var runtimeStore: ClipboardRuntimeStore
    @EnvironmentObject private var storeManager: StoreManager
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
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if isShowingFreeTierHistoryPreview {
                        historyPreviewFooter
                    }
                }
            } else {
                mainContent
                    .safeAreaInset(edge: .top, spacing: 0) {
                        ClipboardHeaderView(viewModel: viewModel, isSearchFocused: _isSearchFocused)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        historyPreviewFooter
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
        .sheet(
            isPresented: Binding(
                get: {
                    storeManager.shouldShowPaywall && storeManager.paywallSource == .panel
                },
                set: { isPresented in
                    if !isPresented {
                        storeManager.dismissPaywall()
                    }
                }
            )
        ) {
            PaywallView()
                .environmentObject(storeManager)
        }
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
            searchService.onRequireFocus = requestSearchFocus
            syncReservedSearchModifiers()
            syncAccessState()
        }
        .onDisappear {
            deactivatePanelInputHandling()
        }
        .onChange(of: storeManager.isTrialExpired) { _, _ in
            syncAccessState()
        }
        .onChange(of: storeManager.isProUnlocked) { _, _ in
            syncAccessState()
        }
        // ── ⌘, 意图通知 → 调用 SwiftUI 原生 openSettings ───────────
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsIntent)) { _ in
            SettingsWindowCoordinator.open {
                openSettings()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchFieldIntent)) { _ in
            requestSearchFocus()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if displayedItems.isEmpty {
            ClipboardEmptyStateView(viewModel: viewModel)
        } else {
            switch clipboardLayout {
            case .horizontal:
                ClipboardHorizontalView(viewModel: viewModel, items: displayedItems)
            case .vertical:
                ClipboardVerticalListView(viewModel: viewModel, items: displayedItems)
            }
        }
    }

    private func focusSearchField() {
        DispatchQueue.main.async { isSearchFocused = true }
    }

    private func requestSearchFocus() {
        guard storeManager.requestAccess(to: .globalSearch, from: .panel) else {
            return
        }

        focusSearchField()
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

    private func syncAccessState() {
        viewModel.updateDisplayedHistoryLimit(storeManager.historyLimitForFreeTier)
        viewModel.handleAccessRestrictionChange(isRestricted: !storeManager.hasFullAccess)
    }

    private var displayedItems: [ClipboardItem] {
        if let historyLimit = storeManager.historyLimitForFreeTier {
            return Array(viewModel.filteredItems.prefix(historyLimit))
        }

        return viewModel.filteredItems
    }

    private var isShowingFreeTierHistoryPreview: Bool {
        (storeManager.historyLimitForFreeTier != nil) && (viewModel.filteredItems.count > displayedItems.count)
    }

    @ViewBuilder
    private var historyPreviewFooter: some View {
        HStack {
            if isShowingFreeTierHistoryPreview {
                Text("免费版当前仅显示最近 10 条记录")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text("\(displayedItems.count) 个项目")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isShowingFreeTierHistoryPreview {
                Button("解锁 Pro") {
                    storeManager.presentPaywall(from: .panel, highlighting: .unlimitedHistory)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .padding(.top, 4)
        .background(.regularMaterial)
    }
}

#Preview {
    ClipboardMainView()
        .environmentObject(ClipboardRuntimeStore.shared)
        .environmentObject(StoreManager.shared)
}
