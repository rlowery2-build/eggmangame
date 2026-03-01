import Foundation
import Observation

@MainActor
protocol GameManagerDelegate: AnyObject {
    func gameStateDidUpdate()
    func showDailyReward(diamonds: Int)
    func showTaskCompleted(reward: Int)
    func showTaskExpired()
    func eggManBecameSick()
    func eggManHealed()
    func transactionFailed(reason: String)
}

@MainActor
@Observable
final class GameManager {
    static let shared = GameManager()

    weak var delegate: GameManagerDelegate?

    private(set) var economyManager: EconomyManager!
    private(set) var taskManager: TaskManager!
    private let persistenceManager = PersistenceManager.shared

    private init() {
        loadGame()
    }

    private func loadGame() {
        let gameState = persistenceManager.loadOrCreate()
        economyManager = EconomyManager(gameState: gameState, persistenceManager: persistenceManager)
        taskManager = TaskManager(gameState: gameState, persistenceManager: persistenceManager)

        economyManager.delegate = self
        taskManager.delegate = self
    }

    // MARK: - Game Actions

    func startGame() {
        taskManager.startExpirationTimer()
        checkDailyLogin()
    }

    func pauseGame() {
        taskManager.stopExpirationTimer()
    }

    func checkDailyLogin() {
        if economyManager.checkDailyLogin() {
            delegate?.showDailyReward(diamonds: EconomyManager.dailyLoginReward)
            syncGameState()
        }
    }

    func feedEgg(type: EggType) -> Bool {
        guard !economyManager.isSick else {
            delegate?.transactionFailed(reason: "Egg Man is sick! Heal him first.")
            return false
        }

        guard economyManager.consumeEgg(type: type) else {
            return false
        }

        taskManager.feedEgg(type: type)

        if economyManager.shouldGetSick() {
            economyManager.makeSick()
            delegate?.eggManBecameSick()
        }

        syncGameState()
        return true
    }

    func healEggMan() -> Bool {
        if economyManager.heal() {
            delegate?.eggManHealed()
            syncGameState()
            return true
        }
        return false
    }

    func buyEggs(type: EggType) -> Bool {
        let success = economyManager.buyEggs(type: type)
        if success {
            syncGameState()
        }
        return success
    }

    func purchaseDiamonds(count: Int) {
        economyManager.addDiamonds(count)
        syncGameState()
    }

    // MARK: - State Accessors

    var diamonds: Int {
        economyManager.diamonds
    }

    var totalEggs: Int {
        economyManager.totalEggs
    }

    func eggCount(for type: EggType) -> Int {
        economyManager.eggCount(for: type)
    }

    var currentTask: GameTask? {
        taskManager.currentGameTask
    }

    var taskTimeRemaining: String {
        taskManager.timeRemainingText
    }

    var isSick: Bool {
        economyManager.isSick
    }

    // MARK: - State Synchronization

    private func syncGameState() {
        let economyState = economyManager.getGameState()
        taskManager.updateGameState(economyState)
        delegate?.gameStateDidUpdate()
    }
}

// MARK: - EconomyManagerDelegate

extension GameManager: EconomyManagerDelegate {
    func economyDidUpdate() {
        delegate?.gameStateDidUpdate()
    }

    func economyTransactionFailed(reason: String) {
        delegate?.transactionFailed(reason: reason)
    }
}

// MARK: - TaskManagerDelegate

extension GameManager: TaskManagerDelegate {
    func taskDidUpdate(_ task: GameTask?) {
        delegate?.gameStateDidUpdate()
    }

    func taskCompleted(reward: Int) {
        economyManager.addDiamonds(reward)
        syncGameState()
        delegate?.showTaskCompleted(reward: reward)
    }

    func taskExpired() {
        delegate?.showTaskExpired()
    }
}
