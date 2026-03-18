import Foundation
import SwiftData
import SwiftUI

struct MigrationView: View {
    private struct ImporterStatus {
        let source: MigrationManager.MigrationSource
        let message: String
    }

    @Environment(\.modelContext) private var modelContext
    @StateObject private var migrationManager = MigrationManager()
    @State private var isImporterPresented = false
    @State private var importerStatus: ImporterStatus?
    @State private var selectedSource: MigrationManager.MigrationSource = .paste

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Data Source", selection: $selectedSource) {
                    ForEach(MigrationManager.MigrationSource.allCases) { source in
                        Text(source.displayName).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(migrationManager.isMigrating)

                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedSource.titleText)
                        .font(.system(size: 14, weight: .semibold))

                    Text(selectedSource.guidanceText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(selectedSource.detailText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if migrationManager.isMigrating {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(statusMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(statusColor)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    isImporterPresented = true
                } label: {
                    Label(
                        migrationManager.isMigrating ? String(localized: "Migration in Progress…") : selectedSource.fileButtonTitle,
                        systemImage: "externaldrive.badge.plus"
                    )
                }
                .disabled(migrationManager.isMigrating)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Migration Assistant")
        } footer: {
            Text("The View layer handles source selection, file picking, and status display; all parsing and routing is managed by MigrationManager.")
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: selectedSource.allowedContentTypes,
            allowsMultipleSelection: false,
            onCompletion: handleImportSelection
        )
        .fileDialogDefaultDirectory(defaultDirectoryURL)
        .fileDialogBrowserOptions(fileDialogBrowserOptions)
    }

    private var statusColor: Color {
        if let importerStatus, importerStatus.source == selectedSource {
            return .red
        }

        if migrationManager.statusSource == selectedSource,
           migrationManager.migrationProgress.contains(String(localized: "Failed")) {
            return .red
        }

        return migrationManager.isMigrating ? .primary : .secondary
    }

    private var statusMessage: String {
        if let importerStatus, importerStatus.source == selectedSource {
            return importerStatus.message
        }

        if migrationManager.statusSource == selectedSource,
           migrationManager.migrationProgress.isEmpty == false {
            return migrationManager.migrationProgress
        }

        return selectedSource.idleStatusText
    }

    private var defaultDirectoryURL: URL? {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

        switch selectedSource {
        case .paste:
            return homeDirectory
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Containers", isDirectory: true)
                .appendingPathComponent("com.wiheads.paste", isDirectory: true)
                .appendingPathComponent("Data", isDirectory: true)
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("Paste", isDirectory: true)

        case .iCopy:
            return homeDirectory
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Containers", isDirectory: true)
                .appendingPathComponent("cn.better365.iCopy", isDirectory: true)
                .appendingPathComponent("Data", isDirectory: true)
                .appendingPathComponent("Documents", isDirectory: true)

        case .pasteNow:
            return nil
        }
    }

    private var fileDialogBrowserOptions: FileDialogBrowserOptions {
        let source = selectedSource
        return source == .paste || source == .iCopy ? [.includeHiddenFiles] : []
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else { return }
            importerStatus = nil
            let source = selectedSource
            Task {
                await migrationManager.importData(
                    from: fileURL,
                    source: source,
                    context: modelContext
                )
            }

        case .failure(let error):
            guard (error as NSError).code != NSUserCancelledError else { return }
            importerStatus = ImporterStatus(
                source: selectedSource,
                message: String(localized: "File selection failed: \(error.localizedDescription)")
            )
        }
    }
}
