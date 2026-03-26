import SwiftUI

struct ClipboardVerticalView: View {
    let items: [ClipboardItem]
    @ObservedObject var viewModel: ClipboardViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    ClipboardCardView(item: item, viewModel: viewModel)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .help("Click to paste to the active app")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ClipboardVerticalView(items: [], viewModel: ClipboardViewModel())
}
