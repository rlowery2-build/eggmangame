import SwiftUI

struct GameView: View {
    @State private var gameState = GameState()
    @State private var draggedEgg: EggType?
    @State private var dragLocation: CGPoint = .zero
    @State private var eggManFrame: CGRect = .zero

    // Mouth detection zone (upper portion of EggMan)
    private var mouthZone: CGRect {
        CGRect(
            x: eggManFrame.midX - 50,
            y: eggManFrame.minY,
            width: 100,
            height: 80
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.92, blue: 0.85),
                        Color(red: 0.90, green: 0.87, blue: 0.80)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top HUD
                    HUDView(gameState: gameState)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer()

                    // Egg Man in the center
                    EggManView(
                        isMouthOpen: gameState.isMouthOpen,
                        isEating: gameState.isEating,
                        onFrameChange: { frame in
                            eggManFrame = frame
                        }
                    )
                    .frame(width: 150, height: 220)

                    Spacer()

                    // Egg tray at bottom
                    EggTrayView(
                        gameState: gameState,
                        onDragStarted: { type in
                            draggedEgg = type
                        },
                        onDragChanged: { location in
                            dragLocation = location
                            // Check if over mouth
                            gameState.isMouthOpen = mouthZone.contains(location)
                        },
                        onDragEnded: { type, location in
                            if mouthZone.contains(location) {
                                // Feed the egg!
                                withAnimation(.spring(duration: 0.3)) {
                                    _ = gameState.feedEgg(type: type)
                                }
                                // Start eating celebration
                                gameState.isMouthOpen = false
                                gameState.isEating = true

                                // After dance, return to hungry mouth open state
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    gameState.isEating = false
                                    gameState.isMouthOpen = true
                                }
                            } else {
                                gameState.isMouthOpen = true
                            }
                            draggedEgg = nil
                        }
                    )
                    .padding(.bottom, 40)
                }

                // Dragged egg overlay
                if let egg = draggedEgg {
                    EggView(type: egg, isDragging: true)
                        .frame(width: 60, height: 75)
                        .position(dragLocation)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

#Preview {
    GameView()
}
