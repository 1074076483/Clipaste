import SwiftUI

struct AdvancedSettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section {
                // 1. 自动粘贴设置块
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("粘贴至当前激活的 App", isOn: $viewModel.autoPasteToActiveApp)
                        .toggleStyle(.switch)
                    
                    Text("双击卡片时，自动将内容直接写入目标应用，无需手动 ⌘V。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.autoPasteToActiveApp {
                        Button("检查\u{201C}辅助功能\u{201D}权限...") {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                
                // 2. 排序行为块
                Toggle("粘贴后将项目移至列表最前", isOn: $viewModel.moveToTopAfterPaste)
                    .toggleStyle(.switch)
                    .padding(.vertical, 4)
                
                // 3. 格式化块
                VStack(alignment: .leading, spacing: 6) {
                    Picker("文本粘贴默认格式", selection: $viewModel.pasteTextFormat) {
                        ForEach(PasteTextFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text("提示：在列表中按住 ⌥ Option 键双击，可临时反转此设置。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        // 彻底隐藏默认滚动条
        .scrollIndicators(.hidden)
        .padding()
        .frame(minWidth: 400, idealWidth: 450, maxWidth: .infinity, minHeight: 300, alignment: .top)
    }
}
