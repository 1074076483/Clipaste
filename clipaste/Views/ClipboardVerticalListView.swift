import SwiftUI

struct ClipboardVerticalListView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    let items: [ClipboardItem]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ClipboardVerticalItemView(
                        item: item,
                        viewModel: viewModel,
                        quickPasteIndex: index < 9 ? index : nil
                    )
                        .id(item.id)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: .infinity)
        // 材质由 ClipboardMainView 最外层统一提供，此处不做局部 background
    }
}
