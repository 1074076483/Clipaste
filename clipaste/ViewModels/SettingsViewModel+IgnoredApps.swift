import AppKit
import UniformTypeIdentifiers

extension SettingsViewModel {
    func addAppToIgnoreList() {
        let openPanel = NSOpenPanel()
        openPanel.title = String(localized: "Choose an App to Ignore")
        openPanel.message = String(localized: "Copied content from the following apps won't be recorded.")
        openPanel.prompt = String(localized: "Add Ignored App")
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.resolvesAliases = true
        openPanel.allowedContentTypes = [UTType.applicationBundle]

        guard openPanel.runModal() == .OK, let applicationURL = openPanel.url else {
            return
        }

        do {
            try IgnoredAppsService.addIgnoredApp(from: applicationURL)
            reloadIgnoredApps()
        } catch {
            print("❌ Failed to add ignored app: \(error.localizedDescription)")
        }
    }

    func removeAppFromIgnoreList(at offsets: IndexSet) {
        let bundleIdentifiers: [String] = offsets.compactMap { index -> String? in
            guard ignoredApps.indices.contains(index) else { return nil }
            return ignoredApps[index].bundleIdentifier
        }

        guard bundleIdentifiers.isEmpty == false else { return }

        IgnoredAppsService.removeIgnoredBundleIdentifiers(bundleIdentifiers)
        reloadIgnoredApps()
    }

    func reloadIgnoredApps() {
        ignoredApps = IgnoredAppsService.resolveIgnoredApps()
    }
}
