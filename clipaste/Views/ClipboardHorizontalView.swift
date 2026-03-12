import SwiftUI

struct ClipboardHorizontalView: View {
    let items: [ClipboardItem]
    let onSelect: (ClipboardItem) -> Void
    var viewModel: ClipboardViewModel? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 20) {
                ForEach(items) { item in
                    ClipboardCardView(item: item, onSelect: {
                        onSelect(item)
                    }, viewModel: viewModel)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .help("点击后粘贴到当前应用")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    ClipboardHorizontalView(items: [], onSelect: { _ in })
}
