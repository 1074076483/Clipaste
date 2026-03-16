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
            return "无限历史记录"
        case .globalSearch:
            return "全局搜索"
        case .plainTextPaste:
            return "纯文本快捷粘贴"
        case .smartGroups:
            return "智能分组切换"
        case .cloudSync:
            return "CloudKit 私有库同步"
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

    var purchaseButtonTitle: String {
        if let proProduct {
            return "立即解锁 \(proProduct.displayPrice)"
        }

        return "立即解锁 Clipaste Pro"
    }

    var accessHeadline: String {
        if isProUnlocked {
            return "Clipaste Pro 已解锁"
        }

        if isTrialExpired {
            return "3 天试用已结束"
        }

        return "试用剩余 \(remainingTrialDays) 天"
    }

    var accessFootnote: String {
        if isProUnlocked {
            return "购买记录已通过当前 Apple ID 验证。"
        }

        if isTrialExpired {
            return "继续使用无限历史记录、高级搜索和同步功能，需要解锁 Pro。"
        }

        return "一次购买，永久解锁全部高级功能。"
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
            storeErrorMessage = "暂时无法加载购买信息，请稍后再试。"
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
                storeErrorMessage = "购买正在等待 Apple 确认。"
            case .userCancelled:
                break
            @unknown default:
                storeErrorMessage = "出现了未识别的购买结果。"
            }
        } catch {
            storeErrorMessage = "购买失败：\(error.localizedDescription)"
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
                storeErrorMessage = "当前 Apple ID 下没有可恢复的 Pro 购买记录。"
            }
        } catch {
            storeErrorMessage = "恢复购买失败：\(error.localizedDescription)"
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
                storeErrorMessage = "商品信息加载失败：\(error.localizedDescription)"
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
                    self.storeErrorMessage = "交易校验失败：\(error.localizedDescription)"
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
                return "StoreKit 交易校验失败。"
            }
        }
    }
}
