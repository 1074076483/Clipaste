import SwiftUI
import AppKit

struct NativeTextView: NSViewRepresentable {
    var text: String
    var attributedText: NSAttributedString?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        // 核心配置：只读、可选中
        textView.isEditable = false
        textView.isSelectable = true

        // 极其关键：开启非连续布局，允许巨量文本在后台分块渲染
        textView.layoutManager?.allowsNonContiguousLayout = true

        textView.textContainerInset = NSSize(width: 20, height: 20)

        configureTextView(textView)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        configureTextView(textView)
    }

    private func configureTextView(_ textView: NSTextView) {
        if let attrText = attributedText {
            // 语法高亮模式：根据系统深浅模式动态选择背景色
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            textView.drawsBackground = true
            textView.backgroundColor = isDark
                ? NSColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1.0) // atom-one-dark 背景色
                : NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0) // xcode 浅色背景
            textView.textStorage?.setAttributedString(attrText)
        } else {
            // 纯文本降级模式
            textView.drawsBackground = false
            textView.font = .systemFont(ofSize: 14, weight: .regular)
            textView.textColor = NSColor.labelColor
            textView.string = text
        }
    }
}
