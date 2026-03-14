import SwiftUI
import AppKit

// ⚠️ AI DEV WARNING: PERFORMANCE GUARD - DO NOT REMOVE
// 异步富文本渲染引擎。严禁在主线程同步解析 RTF，严禁移除底层长度截断逻辑，否则会导致极其严重的 OOM 和 UI 掉帧。
struct AsyncRichTextRenderer: View {
    let rtfData: Data?
    let plainText: String
    let itemId: String
    let maxLength: Int // 控制渲染上限：列表用 300，预览面板用 2000

    @State private var renderedText: AttributedString?

    var body: some View {
        Group {
            if let text = renderedText {
                Text(text)
            } else {
                // 极速占位兜底：在后台解析 RTF 时，先瞬间展示纯文本，实现 0 延迟首屏渲染
                Text(plainText.prefix(maxLength))
            }
        }
        .task(id: rtfData) {
            // ⚠️ 侦测 RTF 数据变化：保存编辑后列表自动刷新
            // 清空缓存：当 rtfData 变化时，必须重新解析（否则保存后列表不更新）
            renderedText = nil

            let rtf = self.rtfData
            let plain = self.plainText
            let limit = self.maxLength

            // ⚠️ 物理隔离：将极其耗时的 RTF 词法解析剥离到后台线程执行
            let result = await Task.detached(priority: .userInitiated) {
                if let data = rtf,
                   let nsAttrString = try? NSAttributedString(
                       data: data,
                       options: [.documentType: NSAttributedString.DocumentType.rtf],
                       documentAttributes: nil
                   ) {
                    // 1. 底层物理截断：绝不把多余的数据扔给 SwiftUI 的排版引擎
                    let safeLength = min(limit, nsAttrString.length)
                    let truncatedNS = nsAttrString.attributedSubstring(
                        from: NSRange(location: 0, length: safeLength)
                    )

                    do {
                        var swiftUIAttr = try AttributedString(truncatedNS, including: \.appKit)
                        // 强制约束字号，防止编辑器里的巨大字号破坏列表 UI
                        swiftUIAttr.font = .system(size: 13)

                        // 预览模式下的尾部截断提示
                        if safeLength == limit && nsAttrString.length > limit {
                            var warning = AttributedString("\n... [文本过长已截断，请编辑查看]")
                            warning.foregroundColor = .secondary
                            warning.font = .system(size: 12, weight: .bold)
                            swiftUIAttr.append(warning)
                        }

                        return swiftUIAttr
                    } catch {
                        return AttributedString(String(plain.prefix(limit)))
                    }
                }
                return AttributedString(String(plain.prefix(limit)))
            }.value

            // 丝滑过渡
            withAnimation(.easeIn(duration: 0.15)) {
                self.renderedText = result
            }
        }
    }
}
