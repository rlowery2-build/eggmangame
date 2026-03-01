import SpriteKit

/// GameScene variant that works with SwiftUI HUD overlay.
/// HUD elements are handled by SwiftUI, this scene only renders game content.
class GameSceneWithHUD: SKScene {

    private var gameManager: GameManager!
    private var eggMan: EggMan!
    private var eggBasket: EggBasket!

    // Callbacks for SwiftUI navigation
    var onStorePressed: (() -> Void)?

    // Touch tracking
    private var draggedEgg: Egg?

    override func didMove(to view: SKView) {
        gameManager = GameManager.shared
        gameManager.delegate = self

        backgroundColor = SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)

        setupEggMan()
        setupEggBasket()

        gameManager.startGame()
    }

    override func willMove(from view: SKView) {
        gameManager.pauseGame()
    }

    // MARK: - Setup

    private func setupEggMan() {
        eggMan = EggMan()
        eggMan.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        addChild(eggMan)

        if gameManager.isSick {
            eggMan.setState(.sick)
        }
    }

    private func setupEggBasket() {
        eggBasket = EggBasket()
        eggBasket.position = CGPoint(x: size.width / 2, y: 150)
        eggBasket.delegate = self
        addChild(eggBasket)
        eggBasket.updateEggCounts(from: gameManager)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check for egg dragging
        if let egg = eggBasket.eggAt(point: location) {
            if gameManager.eggCount(for: egg.eggType) > 0 {
                draggedEgg = egg
                eggBasket.startDraggingEgg(egg)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, draggedEgg != nil else { return }
        let location = touch.location(in: self)

        eggBasket.updateDragPosition(location)

        // Check if egg is near mouth
        if eggMan.isPointInMouth(location) {
            if eggMan.currentState != .mouthOpen && eggMan.currentState != .sick {
                eggMan.setState(.mouthOpen)
            }
        } else {
            if eggMan.currentState == .mouthOpen {
                eggMan.setState(.idle)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let egg = draggedEgg else { return }
        let location = touch.location(in: self)

        draggedEgg = nil
        eggBasket.stopDragging(at: location)

        // Check if dropped on mouth
        if eggMan.isPointInMouth(location) && !gameManager.isSick {
            feedEgg(egg)
        } else {
            eggBasket.snapEggBack(egg)
            if eggMan.currentState == .mouthOpen {
                eggMan.setState(.idle)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let egg = draggedEgg {
            eggBasket.snapEggBack(egg)
            draggedEgg = nil
        }
        if eggMan.currentState == .mouthOpen {
            eggMan.setState(.idle)
        }
    }

    // MARK: - Game Actions

    private func feedEgg(_ egg: Egg) {
        let eggType = egg.eggType

        eggBasket.consumeEgg(egg) { [weak self] in
            guard let self = self else { return }

            if self.gameManager.feedEgg(type: eggType) {
                self.eggMan.playEatingAnimation {
                    self.eggBasket.updateEggCounts(from: self.gameManager)
                }
            }
        }
    }
}

// MARK: - EggBasketDelegate

extension GameSceneWithHUD: EggBasketDelegate {
    func eggBasket(_ basket: EggBasket, didStartDragging egg: Egg) {
        // Visual feedback when starting to drag
    }

    func eggBasket(_ basket: EggBasket, didStopDragging egg: Egg, at position: CGPoint) {
        // Handled in touchesEnded
    }
}

// MARK: - GameManagerDelegate

extension GameSceneWithHUD: GameManagerDelegate {
    func gameStateDidUpdate() {
        eggBasket.updateEggCounts(from: gameManager)
    }

    func showDailyReward(diamonds: Int) {
        // Handled by SwiftUI HUD
    }

    func showTaskCompleted(reward: Int) {
        // Handled by SwiftUI HUD
    }

    func showTaskExpired() {
        // Handled by SwiftUI HUD
    }

    func eggManBecameSick() {
        eggMan.playSickAnimation()
    }

    func eggManHealed() {
        eggMan.playHealAnimation {
            // Animation complete
        }
    }

    func transactionFailed(reason: String) {
        // Handled by SwiftUI HUD
    }
}
