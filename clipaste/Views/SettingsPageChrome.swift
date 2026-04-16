import SwiftUI

struct SettingsSectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.primary)
            .textCase(nil)
            .padding(.bottom, 4)
    }
}

extension View {
    func settingsPageChrome() -> some View {
        self
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .settingsScrollChromeHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
