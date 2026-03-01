import Foundation
import SpriteKit
import SwiftUI

enum EggType: String, CaseIterable, Codable, Identifiable {
    case white
    case brown
    case golden
    case spotted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .white: return "White"
        case .brown: return "Brown"
        case .golden: return "Golden"
        case .spotted: return "Spotted"
        }
    }

    /// SpriteKit color
    var color: SKColor {
        switch self {
        case .white: return SKColor(red: 0.95, green: 0.95, blue: 0.90, alpha: 1.0)
        case .brown: return SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .golden: return SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        case .spotted: return SKColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 1.0)
        }
    }

    /// SwiftUI color
    var swiftUIColor: Color {
        switch self {
        case .white: return Color(red: 0.98, green: 0.96, blue: 0.90)
        case .brown: return Color(red: 0.65, green: 0.45, blue: 0.25)
        case .golden: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .spotted: return Color(red: 0.9, green: 0.9, blue: 0.85)
        }
    }

    var spotColor: SKColor? {
        switch self {
        case .spotted: return SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        default: return nil
        }
    }

    var emoji: String {
        switch self {
        case .white: return "⚪"
        case .brown: return "🟤"
        case .golden: return "🟡"
        case .spotted: return "⚫"
        }
    }

    var points: Int {
        switch self {
        case .white: return 1
        case .brown: return 2
        case .golden: return 5
        case .spotted: return 3
        }
    }
}
