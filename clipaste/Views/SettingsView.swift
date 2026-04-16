import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case general = "general"
    case shortcuts = "shortcuts"
    case ignoredApps = "ignoredApps"
    case advanced = "advanced"
    case about = "about"

    var id: String { self.rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .general: return "General"
        case .shortcuts: return "Shortcuts"
        case .ignoredApps: return "Ignored Apps"
        case .advanced: return "Advanced"
        case .about: return "About"
        }
    }

    var localizedTitle: LocalizedStringResource {
        switch self {
        case .general: return LocalizedStringResource("General")
        case .shortcuts: return LocalizedStringResource("Shortcuts")
        case .ignoredApps: return LocalizedStringResource("Ignored Apps")
        case .advanced: return LocalizedStringResource("Advanced")
        case .about: return LocalizedStringResource("About")
        }
    }

    var navigationTitle: LocalizedStringKey { title }

    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "keyboard"
        case .ignoredApps: return "nosign"
        case .advanced: return "slider.horizontal.3"
        case .about: return "info.circle"
        }
    }

}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @Environment(AppUpdateViewModel.self) private var appUpdateViewModel
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .auto

    var body: some View {
        let resolvedLocale = appLanguage.locale ?? .current

        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    NavigationLink(value: tab) {
                        SidebarLabel(
                            tab: tab,
                            showsUpdateBadge: tab == .about && appUpdateViewModel.shouldShowUpdateBadge
                        )
                    }
                    .tag(tab)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 10))
                }
            }
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 34)
            .font(.system(size: 14, weight: .medium))
            .settingsScrollChromeHidden()
            .navigationSplitViewColumnWidth(min: 184, ideal: 184, max: 184)
        } detail: {
            settingsDetailView(for: selectedTab)
                .background(Color(nsColor: .windowBackgroundColor))
                .frame(minWidth: 620, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .environment(\.locale, resolvedLocale)
        .animation(nil, value: appLanguage)
        .preferredColorScheme(appTheme.colorScheme)
        .toolbar(removing: .sidebarToggle)
        .frame(minWidth: 820, idealWidth: 900, maxWidth: .infinity,
               minHeight: 620, idealHeight: 700, maxHeight: .infinity)
        .background(SettingsWindowObserver())
        .background(WindowAppearanceObserver(theme: appTheme))
    }
}

// MARK: - Sidebar Label

private struct SidebarLabel: View {
    let tab: SettingsTab
    let showsUpdateBadge: Bool

    var body: some View {
        Label {
            Text(tab.localizedTitle)
                .lineLimit(1)
        } icon: {
            Image(systemName: tab.iconName)
                .font(.system(size: 14, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .overlay(alignment: .topTrailing) {
                    if showsUpdateBadge {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                            .offset(x: 2, y: -1)
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private extension SettingsView {
    @ViewBuilder
    func settingsDetailView(for tab: SettingsTab) -> some View {
        switch tab {
        case .general:
            GeneralSettingsView()
        case .shortcuts:
            ShortcutsSettingsView()
        case .ignoredApps:
            IgnoredAppsSettingsView()
        case .advanced:
            AdvancedSettingsView()
        case .about:
            AboutSettingsView()
        }
    }
}
