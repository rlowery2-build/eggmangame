import StoreKit

@MainActor
protocol IAPManagerDelegate: AnyObject {
    func purchaseSucceeded(productId: String, diamonds: Int)
    func purchaseFailed(error: String)
    func purchaseCancelled()
}

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    struct ProductID {
        static let diamonds100 = "com.eggmangame.diamonds100"
        static let diamonds500 = "com.eggmangame.diamonds500"
        static let diamonds1500 = "com.eggmangame.diamonds1500"

        static let all = [diamonds100, diamonds500, diamonds1500]
    }

    private static let diamondAmounts: [String: Int] = [
        ProductID.diamonds100: 100,
        ProductID.diamonds500: 500,
        ProductID.diamonds1500: 1500
    ]

    weak var delegate: IAPManagerDelegate?

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private var updateListenerTask: _Concurrency.Task<Void, Never>?
    
    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: ProductID.all)
            products.sort { product1, product2 in
                guard let amount1 = Self.diamondAmounts[product1.id],
                      let amount2 = Self.diamondAmounts[product2.id] else {
                    return false
                }
                return amount1 < amount2
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(productId: String) async {
        guard let product = products.first(where: { $0.id == productId }) else {
            delegate?.purchaseFailed(error: "Product not found")
            return
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleSuccessfulPurchase(transaction: transaction)

            case .userCancelled:
                delegate?.purchaseCancelled()

            case .pending:
                delegate?.purchaseFailed(error: "Purchase is pending approval")

            @unknown default:
                delegate?.purchaseFailed(error: "Unknown purchase result")
            }
        } catch {
            delegate?.purchaseFailed(error: error.localizedDescription)
        }
    }

    // MARK: - Transaction Handling

    private func listenForTransactions() -> _Concurrency.Task<Void, Never> {
        return _Concurrency.Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    if let transaction = transaction {
                        await self?.handleSuccessfulPurchase(transaction: transaction)
                    }
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func handleSuccessfulPurchase(transaction: Transaction) async {
        let productId = transaction.productID

        if let diamonds = Self.diamondAmounts[productId] {
            delegate?.purchaseSucceeded(productId: productId, diamonds: diamonds)
        }

        await transaction.finish()
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            delegate?.purchaseFailed(error: "Failed to restore purchases: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func priceString(for productId: String) -> String? {
        product(for: productId)?.displayPrice
    }

    func diamondAmount(for productId: String) -> Int {
        Self.diamondAmounts[productId] ?? 0
    }
}
