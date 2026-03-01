import Foundation

struct PhysicsCategory {
    static let none:         UInt32 = 0
    static let player:       UInt32 = 0b1         // 1
    static let ground:       UInt32 = 0b10        // 2
    static let platform:     UInt32 = 0b100       // 4
    static let enemy:        UInt32 = 0b1000      // 8
    static let enemyAttack:  UInt32 = 0b10000     // 16
    static let playerAttack: UInt32 = 0b100000    // 32
    static let collectible:  UInt32 = 0b1000000   // 64
    static let wall:         UInt32 = 0b10000000  // 128
}
