import SwiftUI

struct ClipboardHorizontalView: View {
    @ObservedObject var viewModel: ClipboardViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 20) {
                ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                    ClipboardCardView(
                        item: item,
                        viewModel: viewModel,
                        quickPasteIndex: index < 9 ? index : nil
                    )
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
    ClipboardHorizontalView(viewModel: ClipboardViewModel())
}
