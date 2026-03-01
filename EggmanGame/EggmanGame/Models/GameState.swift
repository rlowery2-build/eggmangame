import SwiftUI

/// Main game state - observable for SwiftUI
@Observable
final class GameState: Codable {
    var score: Int = 0
    var eggsEaten: Int = 0
    var eggCounts: [EggType: Int] = [
        .white: 10,
        .brown: 5,
        .golden: 2
    ]

    /// Whether Egg Man's mouth is currently open (egg hovering over it)
    var isMouthOpen: Bool = true

    /// Whether Egg Man is currently doing his eating celebration dance
    var isEating: Bool = false

    /// Currency
    var diamonds: Int = 50

    /// Health state
    var eggManIsSick: Bool = false

    /// Last login date for daily rewards
    var lastLoginDate: Date?

    /// Current active task
    var currentGameTask: GameTask?

    /// When the current task started
    var taskStartTime: Date?

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case score, eggsEaten, eggCounts, diamonds, eggManIsSick, lastLoginDate, currentGameTask, taskStartTime
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
        eggsEaten = try container.decodeIfPresent(Int.self, forKey: .eggsEaten) ?? 0
        eggCounts = try container.decodeIfPresent([EggType: Int].self, forKey: .eggCounts) ?? [.white: 10, .brown: 5, .golden: 2]
        diamonds = try container.decodeIfPresent(Int.self, forKey: .diamonds) ?? 50
        eggManIsSick = try container.decodeIfPresent(Bool.self, forKey: .eggManIsSick) ?? false
        lastLoginDate = try container.decodeIfPresent(Date.self, forKey: .lastLoginDate)
        currentGameTask = try container.decodeIfPresent(GameTask.self, forKey: .currentGameTask)
        taskStartTime = try container.decodeIfPresent(Date.self, forKey: .taskStartTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(eggsEaten, forKey: .eggsEaten)
        try container.encode(eggCounts, forKey: .eggCounts)
        try container.encode(diamonds, forKey: .diamonds)
        try container.encode(eggManIsSick, forKey: .eggManIsSick)
        try container.encodeIfPresent(lastLoginDate, forKey: .lastLoginDate)
        try container.encodeIfPresent(currentGameTask, forKey: .currentGameTask)
        try container.encodeIfPresent(taskStartTime, forKey: .taskStartTime)
    }

    // MARK: - Factory

    static func createNew() -> GameState {
        GameState()
    }

    // MARK: - Egg Operations

    /// Feed an egg to Egg Man
    func feedEgg(type: EggType) -> Bool {
        guard let count = eggCounts[type], count > 0 else {
            return false
        }

        eggCounts[type] = count - 1
        score += type.points
        eggsEaten += 1
        return true
    }

    /// Get count for a specific egg type
    func count(for type: EggType) -> Int {
        eggCounts[type] ?? 0
    }

    /// Alias for count(for:) used by EconomyManager
    func eggCount(for type: EggType) -> Int {
        count(for: type)
    }

    /// Check if any eggs are available
    var hasEggs: Bool {
        eggCounts.values.contains { $0 > 0 }
    }

    /// Total eggs across all types
    var totalEggs: Int {
        eggCounts.values.reduce(0, +)
    }

    /// Add eggs (for rewards)
    func addEggs(type: EggType, count: Int) {
        eggCounts[type, default: 0] += count
    }

    /// Remove one egg of given type
    func removeEgg(type: EggType) -> Bool {
        guard let count = eggCounts[type], count > 0 else {
            return false
        }
        eggCounts[type] = count - 1
        return true
    }

    // MARK: - Diamond Operations

    func addDiamonds(_ count: Int) {
        diamonds += count
    }

    func spendDiamonds(_ count: Int) -> Bool {
        guard diamonds >= count else {
            return false
        }
        diamonds -= count
        return true
    }
}
