import Foundation

@MainActor
protocol EconomyManagerDelegate: AnyObject {
    func economyDidUpdate()
    func economyTransactionFailed(reason: String)
}

@MainActor
final class EconomyManager {
    static let diamondCostForEggs = 10
    static let eggsPerPurchase = 10
    static let healCost = 5
    static let dailyLoginReward = 10
    static let sickProbability: Double = 0.15

    weak var delegate: EconomyManagerDelegate?

    private var gameState: GameState
    private let persistenceManager: PersistenceManager

    init(gameState: GameState, persistenceManager: PersistenceManager = .shared) {
        self.gameState = gameState
        self.persistenceManager = persistenceManager
    }

    var diamonds: Int {
        gameState.diamonds
    }

    var totalEggs: Int {
        gameState.totalEggs
    }

    func eggCount(for type: EggType) -> Int {
        gameState.eggCount(for: type)
    }

    func getGameState() -> GameState {
        gameState
    }

    func updateGameState(_ state: GameState) {
        self.gameState = state
        save()
    }

    // MARK: - Transactions

    func buyEggs(type: EggType) -> Bool {
        guard gameState.spendDiamonds(Self.diamondCostForEggs) else {
            delegate?.economyTransactionFailed(reason: "Not enough diamonds")
            return false
        }
        gameState.addEggs(type: type, count: Self.eggsPerPurchase)
        save()
        delegate?.economyDidUpdate()
        return true
    }

    func consumeEgg(type: EggType) -> Bool {
        guard gameState.removeEgg(type: type) else {
            delegate?.economyTransactionFailed(reason: "No eggs of this type available")
            return false
        }
        save()
        delegate?.economyDidUpdate()
        return true
    }

    func heal() -> Bool {
        guard gameState.eggManIsSick else {
            return true // Already healthy
        }
        guard gameState.spendDiamonds(Self.healCost) else {
            delegate?.economyTransactionFailed(reason: "Not enough diamonds to heal")
            return false
        }
        gameState.eggManIsSick = false
        save()
        delegate?.economyDidUpdate()
        return true
    }

    func makeSick() {
        gameState.eggManIsSick = true
        save()
        delegate?.economyDidUpdate()
    }

    var isSick: Bool {
        gameState.eggManIsSick
    }

    func shouldGetSick() -> Bool {
        Double.random(in: 0...1) < Self.sickProbability
    }

    func addDiamonds(_ count: Int) {
        gameState.addDiamonds(count)
        save()
        delegate?.economyDidUpdate()
    }

    /// Add eggs from external sources (e.g., side-scroller adventure mode)
    func addEggs(type: EggType, count: Int) {
        gameState.addEggs(type: type, count: count)
        save()
        delegate?.economyDidUpdate()
    }

    // MARK: - Daily Login

    func checkDailyLogin() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastLogin = gameState.lastLoginDate {
            let lastLoginDay = calendar.startOfDay(for: lastLogin)
            if lastLoginDay == today {
                return false // Already claimed today
            }
        }

        gameState.lastLoginDate = Date()
        gameState.addDiamonds(Self.dailyLoginReward)
        save()
        delegate?.economyDidUpdate()
        return true
    }

    // MARK: - Persistence

    private func save() {
        persistenceManager.save(gameState)
    }
}
