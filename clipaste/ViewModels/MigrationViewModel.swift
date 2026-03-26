import Combine
import Foundation
import SwiftData

@MainActor
final class MigrationViewModel: ObservableObject {
    typealias MigrationSource = MigrationManager.MigrationSource

    @Published var isMigrating: Bool = false
    @Published private(set) var statusSource: MigrationSource?
    @Published var migrationProgress: LocalizedStringResource?

    private let migrationManager: MigrationManager

    init(migrationManager: MigrationManager? = nil) {
        self.migrationManager = migrationManager ?? MigrationManager()
    }

    func importData(from fileURL: URL, source: MigrationSource, context: ModelContext) async {
        guard !isMigrating else { return }

        isMigrating = true
        statusSource = source
        migrationProgress = LocalizedStringResource("正在读取 \(source.displayName) 数据...")

        defer {
            isMigrating = false
        }

        do {
            let importedRows = try await migrationManager.loadRows(from: fileURL, source: source)

            guard importedRows.isEmpty == false else {
                migrationProgress = LocalizedStringResource("\(source.displayName) 文件中没有找到可导入记录。")
                return
            }

            migrationProgress = LocalizedStringResource("已解析 \(importedRows.count) 条 \(source.displayName) 记录，正在写入 Clipaste...")
            let report = try migrationManager.persistRows(importedRows, source: source, into: context)

            migrationProgress = LocalizedStringResource("\(source.displayName) 迁移完成：导入 \(report.importedCount) 条，跳过 \(report.skippedCount) 条重复记录。")
        } catch {
            migrationProgress = LocalizedStringResource("\(source.displayName) 迁移失败：\(error.localizedDescription)")
        }
    }
}
