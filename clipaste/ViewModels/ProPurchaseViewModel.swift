import Combine
import Foundation

@MainActor
final class ProPurchaseViewModel: ObservableObject {
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published var errorMessage: String?

    private var storeManager: StoreManager?

    func connect(to storeManager: StoreManager) {
        guard self.storeManager !== storeManager else { return }
        self.storeManager = storeManager
    }

    func prepareProducts() async {
        guard let storeManager else { return }
        guard storeManager.proProduct == nil else { return }

        do {
            try await storeManager.fetchProducts()
        } catch {
            errorMessage = String(localized: "Product info failed to load: \(error.localizedDescription)")
        }
    }

    func purchase() async {
        guard let storeManager else { return }

        errorMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await storeManager.purchase()
        } catch {
            errorMessage = purchaseMessage(for: error)
        }
    }

    func restorePurchases() async {
        guard let storeManager else { return }

        errorMessage = nil
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await storeManager.restorePurchases()

            if storeManager.isProUnlocked == false {
                errorMessage = String(localized: "No restorable Pro purchase found for this Apple ID.")
            }
        } catch {
            errorMessage = String(localized: "Restore failed: \(error.localizedDescription)")
        }
    }

    private func purchaseMessage(for error: Error) -> String {
        if let storeError = error as? StoreManager.StoreError,
           let description = storeError.errorDescription {
            return description
        }

        return String(localized: "Purchase failed: \(error.localizedDescription)")
    }
}
