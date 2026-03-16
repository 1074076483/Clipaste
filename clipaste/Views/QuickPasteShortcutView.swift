import SwiftUI

struct QuickPasteShortcutBadge: View {
    let modifierKey: ModifierKey
    let number: Int
    var color: Color = .secondary

    var body: some View {
        Text("\(modifierKey.symbol) \(number)")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .allowsHitTesting(false)
    }
}

struct QuickPasteShortcutHost: View {
    let shortcutIndex: Int
    let modifierKey: ModifierKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear
                .frame(width: 1, height: 1)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(
            KeyEquivalent(Character(String(shortcutIndex + 1))),
            modifiers: modifierKey.eventModifiers
        )
        .opacity(0.001)
        .accessibilityHidden(true)
    }
}
