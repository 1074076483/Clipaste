import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private let preferencesStore: AppPreferencesStore
    private var cancellables = Set<AnyCancellable>()
    private var isApplyingSharedState = false

    var launchAtLogin: Bool {
        willSet { objectWillChange.send() }
        didSet {
            guard !isApplyingSharedState, launchAtLogin != oldValue else { return }
            preferencesStore.updateLaunchAtLogin(launchAtLogin)
            applySharedState {
                launchAtLogin = preferencesStore.launchAtLogin
            }
        }
    }

    @AppStorage("appLanguage") var appLanguage: AppLanguage = .auto {
        willSet { objectWillChange.send() }
        didSet { updateAppLanguage(language: appLanguage) }
    }

    @AppStorage("isVerticalLayout") var isVerticalLayout: Bool = false {
        willSet { objectWillChange.send() }
        didSet {
            // 保持 clipboardLayout 与 isVerticalLayout 同步
            layoutMode = isVerticalLayout ? .vertical : .horizontal
            NotificationCenter.default.post(
                name: .clipboardLayoutModeChanged,
                object: isVerticalLayout ? AppLayoutMode.vertical : AppLayoutMode.horizontal
            )
        }
    }

    @AppStorage("verticalFollowMode") var verticalFollowMode: VerticalFollowMode = .mouse {
        willSet { objectWillChange.send() }
    }

    @AppStorage("historyRetention") var historyRetention: HistoryRetention = .oneMonth {
        willSet { objectWillChange.send() }
    }

    @AppStorage(ModifierKey.quickPasteDefaultsKey) var quickPasteModifier: ModifierKey = .command {
        willSet { objectWillChange.send() }
    }

    @AppStorage(ModifierKey.plainTextDefaultsKey) var plainTextModifier: ModifierKey = .shift {
        willSet { objectWillChange.send() }
    }

    @AppStorage("playSound") var playSound: Bool = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("clipboardLayout") var layoutMode: AppLayoutMode = .horizontal {
        willSet { objectWillChange.send() }
    }

    @AppStorage("pasteBehavior") var pasteBehavior: PasteBehavior = .direct {
        willSet { objectWillChange.send() }
    }

    @AppStorage("pasteAsPlainText") var pasteAsPlainText: Bool = false {
        willSet { objectWillChange.send() }
    }

    // MARK: - 高级：粘贴与行为
    @AppStorage("autoPasteToActiveApp") var autoPasteToActiveApp: Bool = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("moveToTopAfterPaste") var moveToTopAfterPaste: Bool = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("pasteTextFormat") var pasteTextFormat: PasteTextFormat = .original {
        willSet { objectWillChange.send() }
    }

    @AppStorage("historyLimit") var historyLimit: HistoryLimit = .month {
        willSet { objectWillChange.send() }
    }

    convenience init() {
        self.init(preferencesStore: AppPreferencesStore.shared)
    }

    init(preferencesStore: AppPreferencesStore) {
        self.preferencesStore = preferencesStore
        self.launchAtLogin = preferencesStore.launchAtLogin

        ModifierKey.migrateStoredPreferences()
        quickPasteModifier = ModifierKey.quickPastePreference()
        plainTextModifier = ModifierKey.plainTextPreference()
        bindPreferences()
        preferencesStore.refreshLaunchAtLoginStatus()
        applySharedState {
            launchAtLogin = preferencesStore.launchAtLogin
        }
    }

    // MARK: - 语言切换

    private func updateAppLanguage(language: AppLanguage) {
        // 覆盖 AppleLanguages 让 AppKit 层在下次启动时生效
        if language == .auto {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }

    private func bindPreferences() {
        preferencesStore.$launchAtLogin
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }
                self.applySharedState {
                    self.launchAtLogin = isEnabled
                }
            }
            .store(in: &cancellables)
    }

    private func applySharedState(_ updates: () -> Void) {
        isApplyingSharedState = true
        updates()
        isApplyingSharedState = false
    }
}
