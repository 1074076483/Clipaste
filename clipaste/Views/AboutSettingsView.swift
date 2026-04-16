import AppKit
import SwiftUI

struct AboutSettingsView: View {
    @Environment(AppUpdateViewModel.self) private var updateViewModel
    private let privacyPolicyURL = URL(string: "https://legal.clipaste.com/?page=privacy")!
    private let termsOfServiceURL = URL(string: "https://legal.clipaste.com/?page=terms")!

    var body: some View {
        @Bindable var updateViewModel = updateViewModel

        Form {
            brandSection
            softwareUpdateSection(
                viewModel: updateViewModel,
                automaticallyChecksForUpdates: $updateViewModel.automaticallyChecksForUpdates,
                automaticallyDownloadsUpdates: $updateViewModel.automaticallyDownloadsUpdates
            )
            linksSection
        }
        .settingsPageChrome()
        .task {
            updateViewModel.start()
            updateViewModel.refreshAvailabilityIfNeeded()
        }
    }
}

// MARK: - Brand Header

private extension AboutSettingsView {
    var brandSection: some View {
        Section {
            VStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 84, height: 84)
                    .clipShape(.rect(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

                Text(AppMetadata.displayName)
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.8)

                HStack(spacing: 0) {
                    Text("Version")
                    Text(verbatim: " \(AppMetadata.displayVersion)")
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

                Text("Quickly review, search, and re-paste recently copied content.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }
}

// MARK: - Software Update

private extension AboutSettingsView {
    func softwareUpdateSection(
        viewModel: AppUpdateViewModel,
        automaticallyChecksForUpdates: Binding<Bool>,
        automaticallyDownloadsUpdates: Binding<Bool>
    ) -> some View {
        Section {
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .opacity(viewModel.shouldShowUpdateBadge ? 1 : 0)

                Text(verbatim: updateStatusMessage(for: viewModel))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(updateStatusColor(for: viewModel))
                    .lineLimit(2)

                Spacer(minLength: 12)
            }

            LabeledContent("Current Version") {
                Text(verbatim: viewModel.currentVersion)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            if let availableUpdate = viewModel.availableUpdate {
                LabeledContent("Latest Version") {
                    Text(verbatim: availableUpdate.version)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Toggle(isOn: automaticallyChecksForUpdates) {
                Text("Automatically Check for Updates")
            }

            Toggle(isOn: automaticallyDownloadsUpdates) {
                Text("Automatically Download Updates")
            }
            .disabled(!viewModel.automaticallyChecksForUpdates)

            HStack(spacing: 12) {
                if viewModel.isUpdateAvailable {
                    Button("Update Now") {
                        viewModel.installAvailableUpdate()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isCheckingForUpdates || !viewModel.canCheckForUpdates)
                } else {
                    Button("Check for Updates") {
                        viewModel.checkForUpdates()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isCheckingForUpdates || !viewModel.canCheckForUpdates)
                }

                if let releaseNotesURL = viewModel.availableUpdate?.releaseNotesURL {
                    Link("View Release Notes", destination: releaseNotesURL)
                        .buttonStyle(.link)
                }

                Spacer()
            }

            if let lastUpdateCheckDate = viewModel.lastUpdateCheckDate {
                Text(verbatim: lastCheckedText(for: lastUpdateCheckDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if case let .failed(message) = viewModel.phase {
                Text(verbatim: updateFailureText(message: message))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            SettingsSectionHeader(title: "Software Update")
        }
    }
}

// MARK: - Links

private extension AboutSettingsView {
    var linksSection: some View {
        Section {
            Button(action: sendFeedback) {
                linkRow(title: "Send Feedback", systemImage: "paperplane")
            }
            .buttonStyle(.plain)

            Link(destination: privacyPolicyURL) {
                linkRow(title: "Privacy Policy", systemImage: "lock.doc")
            }
            .buttonStyle(.plain)

            Link(destination: termsOfServiceURL) {
                linkRow(title: "Terms of Service", systemImage: "doc.text")
            }
            .buttonStyle(.plain)
        } header: {
            SettingsSectionHeader(title: "About & Support")
        }
    }

    func linkRow(title: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    func sendFeedback() {
        guard let url = URL(string: "mailto:your_email@example.com?subject=Clipaste%20Feedback") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Status Helpers

private extension AboutSettingsView {
    func updateStatusMessage(for viewModel: AppUpdateViewModel) -> String {
        switch viewModel.phase {
        case .idle:
            if !viewModel.automaticallyChecksForUpdates {
                return String(localized: "Automatic update checks are turned off")
            }
            return String(localized: "Ready to check for updates")
        case .checking:
            return String(localized: "Checking for updates…")
        case .updateAvailable:
            if let version = viewModel.availableUpdate?.version {
                return String(format: String(localized: "A new version is ready: %@"), version)
            }
            return String(localized: "A new version is available")
        case .downloading:
            return String(localized: "Downloading update…")
        case .installing:
            return String(localized: "Preparing update…")
        case .upToDate:
            return String(localized: "You're up to date")
        case .failed(let message):
            return updateFailureText(message: message)
        }
    }

    func updateStatusColor(for viewModel: AppUpdateViewModel) -> Color {
        switch viewModel.phase {
        case .updateAvailable: return .accentColor
        case .failed: return .red
        default: return .secondary
        }
    }

    func lastCheckedText(for date: Date) -> String {
        let formattedDate = date.formatted(date: .abbreviated, time: .shortened)
        return String(format: String(localized: "Last checked: %@"), formattedDate)
    }

    func updateFailureText(message: String) -> String {
        String(format: String(localized: "Update check failed: %@"), message)
    }
}

#Preview {
    AboutSettingsView()
        .environment(AppUpdateViewModel.preview)
}
