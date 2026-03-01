import Foundation

@MainActor
protocol TaskManagerDelegate: AnyObject {
    func taskDidUpdate(_ task: GameTask?)
    func taskCompleted(reward: Int)
    func taskExpired()
}

@MainActor
final class TaskManager {
    weak var delegate: TaskManagerDelegate?

    private var gameState: GameState
    private let persistenceManager: PersistenceManager
    private var timer: Timer?

    init(gameState: GameState, persistenceManager: PersistenceManager = .shared) {
        self.gameState = gameState
        self.persistenceManager = persistenceManager
        checkTaskExpiration()
    }

    var currentGameTask: GameTask? {
        gameState.currentGameTask
    }

    var taskStartTime: Date? {
        gameState.taskStartTime
    }

    var timeRemaining: TimeInterval? {
        guard let task = gameState.currentGameTask,
              let startTime = gameState.taskStartTime else {
            return nil
        }
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = task.duration - elapsed
        return max(0, remaining)
    }

    var timeRemainingText: String {
        guard let remaining = timeRemaining else {
            return "No active task"
        }
        if remaining <= 0 {
            return "Expired"
        }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }

    func getGameState() -> GameState {
        gameState
    }

    func updateGameState(_ state: GameState) {
        self.gameState = state
        save()
    }

    // MARK: - Task Logic

    func feedEgg(type: EggType) {
        guard var task = gameState.currentGameTask else { return }
        guard !task.isCompleted else { return }

        if task.eggType == type {
            task.incrementProgress()
            gameState.currentGameTask = task
            save()
            delegate?.taskDidUpdate(task)

            if task.isCompleted {
                completeCurrentTask()
            }
        }
    }

    private func completeCurrentTask() {
        guard let task = gameState.currentGameTask, task.isCompleted else { return }

        let reward = task.diamondReward
        delegate?.taskCompleted(reward: reward)

        generateNewTask()
    }

    func generateNewTask() {
        let newTask = GameTask.generateRandom()
        gameState.currentGameTask = newTask
        gameState.taskStartTime = Date()
        save()
        delegate?.taskDidUpdate(newTask)
    }

    func checkTaskExpiration() {
        guard let _ = gameState.currentGameTask,
              let remaining = timeRemaining else {
            if gameState.currentGameTask == nil {
                generateNewTask()
            }
            return
        }

        if remaining <= 0 {
            delegate?.taskExpired()
            generateNewTask()
        }
    }

    func startExpirationTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTaskExpiration()
            }
        }
    }

    func stopExpirationTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Persistence

    private func save() {
        persistenceManager.save(gameState)
    }
}
