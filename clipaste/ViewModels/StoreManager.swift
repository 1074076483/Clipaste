import Combine
import Foundation
import StoreKit

enum ProAccessFeature: String, Identifiable {
    case unlimitedHistory
    case globalSearch
    case plainTextPaste
    case smartGroups
    case cloudSync

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedHistory:
            return String(localized: "Unlimited History")
        case .globalSearch:
            return String(localized: "Global Search")
        case .plainTextPaste:
            return String(localized: "Plain Text Quick Paste")
        case .smartGroups:
            return String(localized: "Smart Group Switching")
        case .cloudSync:
            return String(localized: "CloudKit Private Sync")
        }
    }
}

enum PaywallPresentationSource: String {
    case panel
    case settings
}

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    static let proLifetimeProductID = "com.gangz1o.clipaste.pro.lifetime"
    static let trialDuration: TimeInterval = 3 * 24 * 60 * 60
    static let historyPreviewLimit = 10

    @Published private(set) var remainingTrialDays: Int
    @Published private(set) var isTrialExpired: Bool
    @Published private(set) var isProUnlocked: Bool = false
    @Published private(set) var proProduct: Product?
    @Published private(set) var firstLaunchDate: Date
    @Published private(set) var highlightedFeature: ProAccessFeature?
    @Published private(set) var paywallSource: PaywallPresentationSource?
    @Published private(set) var isPurchaseInProgress = false
    @Published private(set) var isRestoreInProgress = false
    @Published var shouldShowPaywall = false
    @Published var storeErrorMessage: String?

    private let defaults: UserDefaults
    private var transactionUpdatesTask: Task<Void, Never>?
    private var trialClockTask: Task<Void, Never>?

    private enum Keys {
        static let firstLaunchDate = "clipaste.store.firstLaunchDate"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let resolvedFirstLaunchDate: Date

        if let storedDate = defaults.object(forKey: Keys.firstLaunchDate) as? Date {
            resolvedFirstLaunchDate = storedDate
        } else {
            let now = Date()
            resolvedFirstLaunchDate = now
            defaults.set(now, forKey: Keys.firstLaunchDate)
        }

        self.firstLaunchDate = resolvedFirstLaunchDate

        let initialRemaining = Self.trialDuration - max(0, Date().timeIntervalSince(resolvedFirstLaunchDate))
        let initialExpired = initialRemaining <= 0
        self.remainingTrialDays = initialExpired ? 0 : max(1, Int(ceil(initialRemaining / 86_400)))
        self.isTrialExpired = initialExpired

        recalculateTrialState()
        transactionUpdatesTask = makeTransactionUpdatesTask()
        trialClockTask = makeTrialClockTask()

        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
        trialClockTask?.cancel()
    }

    var hasFullAccess: Bool {
        isProUnlocked || !isTrialExpired
    }

    var historyLimitForFreeTier: Int? {
        hasFullAccess ? nil : Self.historyPreviewLimit
    }

    /// StoreKit resolved price (e.g. "¥49.00") or hardcoded fallback.
    var localizedLifetimePrice: String {
        proProduct?.displayPrice ?? "¥49"
    }

    var lifetimePriceSubtitle: String {
        String(localized: "Lifetime purchase, pay once, free updates forever.")
    }

    var purchaseButtonTitle: String {
        String(localized: "Confirm Payment (\(localizedLifetimePrice))")
    }

    var accessHeadline: String {
        if isProUnlocked {
            return String(localized: "Clipaste Pro Unlocked")
        }

        if isTrialExpired {
            return String(localized: "3-Day Trial Has Ended")
        }

        return String(localized: "\(remainingTrialDays) Trial Days Remaining")
    }

    var accessFootnote: String {
        if isProUnlocked {
            return String(localized: "Purchase verified with your current Apple ID.")
        }

        if isTrialExpired {
            return String(localized: "Unlock Pro for unlimited history, advanced search, and sync.")
        }

        return String(localized: "Purchase once, unlock all premium features of Clipaste forever.")
    }

    func requestAccess(
        to feature: ProAccessFeature,
        from source: PaywallPresentationSource
    ) -> Bool {
        guard hasFullAccess else {
            presentPaywall(from: source, highlighting: feature)
            return false
        }

        return true
    }

    func presentPaywall(
        from source: PaywallPresentationSource,
        highlighting feature: ProAccessFeature? = nil
    ) {
        guard !isProUnlocked else { return }
        paywallSource = source
        highlightedFeature = feature
        shouldShowPaywall = true
    }

    func dismissPaywall() {
        shouldShowPaywall = false
        paywallSource = nil
        highlightedFeature = nil
        storeErrorMessage = nil
    }

    func purchasePro() async {
        storeErrorMessage = nil

        if proProduct == nil {
            await loadProducts()
        }

        guard let proProduct else {
            storeErrorMessage = String(localized: "Unable to load purchase info. Please try again later.")
            return
        }

        isPurchaseInProgress = true
        defer { isPurchaseInProgress = false }

        do {
            let result = try await proProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()

                if isProUnlocked {
                    dismissPaywall()
                }
            case .pending:
                storeErrorMessage = String(localized: "Purchase is pending Apple confirmation.")
            case .userCancelled:
                break
            @unknown default:
                storeErrorMessage = String(localized: "An unrecognized purchase result occurred.")
            }
        } catch {
            storeErrorMessage = String(localized: "Purchase failed: \(error.localizedDescription)")
        }
    }

    func restorePurchases() async {
        storeErrorMessage = nil
        isRestoreInProgress = true
        defer { isRestoreInProgress = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()

            if isProUnlocked {
                dismissPaywall()
            } else {
                storeErrorMessage = String(localized: "No restorable Pro purchase found for this Apple ID.")
            }
        } catch {
            storeErrorMessage = String(localized: "Restore failed: \(error.localizedDescription)")
        }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proLifetimeProductID])
            proProduct = products.first(where: { $0.id == Self.proLifetimeProductID })
            if proProduct != nil {
                storeErrorMessage = nil
            }
        } catch {
            if proProduct == nil {
                storeErrorMessage = String(localized: "Product info failed to load: \(error.localizedDescription)")
            }
        }
    }

    func refreshEntitlements() async {
        var unlocked = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            guard transaction.productID == Self.proLifetimeProductID else {
                continue
            }

            if transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }

        isProUnlocked = unlocked
        recalculateTrialState()

        if unlocked {
            storeErrorMessage = nil
        }
    }

    private func recalculateTrialState(referenceDate: Date = Date()) {
        let elapsed = max(0, referenceDate.timeIntervalSince(firstLaunchDate))
        let remaining = max(0, Self.trialDuration - elapsed)
        let expired = remaining <= 0

        remainingTrialDays = expired ? 0 : max(1, Int(ceil(remaining / 86_400)))
        isTrialExpired = expired

        if isProUnlocked {
            shouldShowPaywall = false
            paywallSource = nil
            highlightedFeature = nil
        }
    }

    private func makeTransactionUpdatesTask() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }

            for await update in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(update)
                    await transaction.finish()
                    await self.refreshEntitlements()
                } catch {
                    self.storeErrorMessage = String(localized: "Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func makeTrialClockTask() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                self.recalculateTrialState()

                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    break
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.verificationFailed
        }
    }
}

extension StoreManager {
    enum StoreError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed:
                return String(localized: "StoreKit transaction verification failed.")
            }
        }
    }
}
