import Foundation

struct GameTask: Codable, Equatable {
    let id: UUID
    let eggType: EggType
    let requiredCount: Int
    var currentProgress: Int
    let diamondReward: Int
    let duration: TimeInterval

    static let taskDuration: TimeInterval = 4 * 60 * 60 // 4 hours in seconds

    var isCompleted: Bool {
        currentProgress >= requiredCount
    }

    var progressText: String {
        "\(currentProgress)/\(requiredCount)"
    }

    var descriptionText: String {
        "Feed \(requiredCount) \(eggType.displayName.lowercased()) eggs"
    }

    init(eggType: EggType, requiredCount: Int, diamondReward: Int) {
        self.id = UUID()
        self.eggType = eggType
        self.requiredCount = requiredCount
        self.currentProgress = 0
        self.diamondReward = diamondReward
        self.duration = GameTask.taskDuration
    }

    static func generateRandom() -> GameTask {
        let eggType = EggType.allCases.randomElement()!
        let requiredCount = Int.random(in: 3...8)
        let diamondReward = Int.random(in: 15...25)
        return GameTask(eggType: eggType, requiredCount: requiredCount, diamondReward: diamondReward)
    }

    mutating func incrementProgress() {
        if currentProgress < requiredCount {
            currentProgress += 1
        }
    }
}
