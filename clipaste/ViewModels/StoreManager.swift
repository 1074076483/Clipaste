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

    var title: LocalizedStringResource {
        switch self {
        case .unlimitedHistory:
            return "Unlimited History"
        case .globalSearch:
            return "Global Search"
        case .plainTextPaste:
            return "Plain Text Quick Paste"
        case .smartGroups:
            return "Smart Group Switching"
        case .cloudSync:
            return "CloudKit Private Sync"
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

    static let proProductID = "com.gangz1o.clipaste.pro"
    static let trialDuration: TimeInterval = 3 * 24 * 60 * 60
    static let historyPreviewLimit = 10

    @Published private(set) var remainingTrialDays: Int
    @Published private(set) var isTrialExpired: Bool
    @Published private(set) var isProUnlocked: Bool = false
    @Published var proProduct: Product?
    @Published private(set) var firstLaunchDate: Date
    @Published private(set) var highlightedFeature: ProAccessFeature?
    @Published private(set) var paywallSource: PaywallPresentationSource?
    @Published var shouldShowPaywall = false

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
            try? await fetchProducts()
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

    var lifetimePriceSubtitle: LocalizedStringResource {
        "Lifetime purchase, pay once, free updates forever."
    }

    var accessHeadline: LocalizedStringResource {
        if isProUnlocked {
            return "Clipaste Pro Unlocked"
        }

        if isTrialExpired {
            return "3-Day Trial Has Ended"
        }

        return LocalizedStringResource("\(remainingTrialDays) Trial Days Remaining")
    }

    var accessFootnote: LocalizedStringResource {
        if isProUnlocked {
            return "Purchase verified with your current Apple ID."
        }

        if isTrialExpired {
            return "Unlock Pro for unlimited history, advanced search, and sync."
        }

        return "Purchase once, unlock all premium features of Clipaste forever."
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
    }

    func fetchProducts() async throws {
        let products = try await Product.products(for: [Self.proProductID])
        guard let resolvedProduct = products.first(where: { $0.id == Self.proProductID }) else {
            proProduct = nil
            throw StoreError.productUnavailable
        }

        proProduct = resolvedProduct
    }

    func purchase() async throws {
        if proProduct == nil {
            try await fetchProducts()
        }

        guard let proProduct else {
            throw StoreError.productUnavailable
        }

        let result = try await proProduct.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()

            if isProUnlocked {
                dismissPaywall()
            }
        case .userCancelled:
            return
        case .pending:
            throw StoreError.purchasePending
        @unknown default:
            throw StoreError.unrecognizedPurchaseResult
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()

        if isProUnlocked {
            dismissPaywall()
        }
    }

    func refreshEntitlements() async {
        var unlocked = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            guard transaction.productID == Self.proProductID else {
                continue
            }

            if transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }

        isProUnlocked = unlocked
        recalculateTrialState()
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
                    print("❌ StoreKit transaction update handling failed: \(error.localizedDescription)")
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
        case productUnavailable
        case purchasePending
        case unrecognizedPurchaseResult
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .productUnavailable:
                return String(localized: "Unable to load purchase info. Please try again later.")
            case .purchasePending:
                return String(localized: "Purchase is pending Apple confirmation.")
            case .unrecognizedPurchaseResult:
                return String(localized: "An unrecognized purchase result occurred.")
            case .verificationFailed:
                return String(localized: "StoreKit transaction verification failed.")
            }
        }

        var localizedResource: LocalizedStringResource {
            switch self {
            case .productUnavailable:
                return "Unable to load purchase info. Please try again later."
            case .purchasePending:
                return "Purchase is pending Apple confirmation."
            case .unrecognizedPurchaseResult:
                return "An unrecognized purchase result occurred."
            case .verificationFailed:
                return "StoreKit transaction verification failed."
            }
        }
    }
}
