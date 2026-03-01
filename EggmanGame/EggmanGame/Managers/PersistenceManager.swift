import Foundation

// MARK: - Side-Scroller Progress

struct SideScrollerProgress: Codable {
    var highestLevelCompleted: Int = 0
    var totalEggsCollected: [String: Int] = [:]  // EggType.rawValue -> count
    var bestTimePerLevel: [Int: TimeInterval] = [:]  // levelNumber -> time
    var unlockedAbilities: [String] = []

    mutating func recordLevelComplete(level: Int, time: TimeInterval, eggs: [EggType: Int]) {
        if level > highestLevelCompleted {
            highestLevelCompleted = level
        }

        if let bestTime = bestTimePerLevel[level] {
            if time < bestTime {
                bestTimePerLevel[level] = time
            }
        } else {
            bestTimePerLevel[level] = time
        }

        for (type, count) in eggs {
            totalEggsCollected[type.rawValue, default: 0] += count
        }
    }

    mutating func unlockAbility(_ ability: String) {
        if !unlockedAbilities.contains(ability) {
            unlockedAbilities.append(ability)
        }
    }

    func hasAbility(_ ability: String) -> Bool {
        unlockedAbilities.contains(ability)
    }
}

// MARK: - Persistence Manager

@MainActor
final class PersistenceManager {
    static let shared = PersistenceManager()

    private let gameStateKey = "com.eggmangame.gamestate"
    private let sideScrollerProgressKey = "com.eggmangame.sidescroller.progress"
    private let defaults = UserDefaults.standard

    private init() {}

    func save(_ gameState: GameState) {
        do {
            let data = try JSONEncoder().encode(gameState)
            defaults.set(data, forKey: gameStateKey)
        } catch {
            print("Failed to save game state: \(error)")
        }
    }

    func load() -> GameState? {
        guard let data = defaults.data(forKey: gameStateKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            print("Failed to load game state: \(error)")
            return nil
        }
    }

    func loadOrCreate() -> GameState {
        if let existingState = load() {
            return existingState
        }
        let newState = GameState.createNew()
        save(newState)
        return newState
    }

    func reset() {
        let newState = GameState.createNew()
        save(newState)
    }

    // MARK: - Side-Scroller Progress

    func saveSideScrollerProgress(_ progress: SideScrollerProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            defaults.set(data, forKey: sideScrollerProgressKey)
        } catch {
            print("Failed to save side-scroller progress: \(error)")
        }
    }

    func loadSideScrollerProgress() -> SideScrollerProgress? {
        guard let data = defaults.data(forKey: sideScrollerProgressKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(SideScrollerProgress.self, from: data)
        } catch {
            print("Failed to load side-scroller progress: \(error)")
            return nil
        }
    }

    func loadOrCreateSideScrollerProgress() -> SideScrollerProgress {
        if let existingProgress = loadSideScrollerProgress() {
            return existingProgress
        }
        let newProgress = SideScrollerProgress()
        saveSideScrollerProgress(newProgress)
        return newProgress
    }

    func resetSideScrollerProgress() {
        let newProgress = SideScrollerProgress()
        saveSideScrollerProgress(newProgress)
    }
}
