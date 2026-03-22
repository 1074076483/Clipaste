import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: StoreManager

    var body: some View {
        SubscriptionModalView(onClose: close)
            .environmentObject(storeManager)
    }

    private func close() {
        storeManager.dismissPaywall()
        dismiss()
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager.shared)
}
