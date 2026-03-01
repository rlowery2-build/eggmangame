import SwiftUI

struct HUDView: View {
    var gameState: GameState

    var body: some View {
        HStack {
            // Score display
            GlassCard {
                HStack(spacing: 8) {
                    Text("Score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(gameState.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }

            Spacer()

            // Eggs eaten counter
            GlassCard {
                HStack(spacing: 8) {
                    Text("\(gameState.eggsEaten)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Image(systemName: "fork.knife")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

/// Reusable Liquid Glass card container (iOS 26+)
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .liquidGlass(in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ZStack {
        Color(red: 0.95, green: 0.92, blue: 0.85)
            .ignoresSafeArea()

        HUDView(gameState: GameState())
            .padding()
    }
}
