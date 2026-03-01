import SpriteKit

class GameScene: SKScene {

    private var gameManager: GameManager!
    private var eggMan: EggMan!
    private var eggBasket: EggBasket!

    // HUD elements
    private var diamondLabel: SKLabelNode!
    private var eggLabel: SKLabelNode!
    private var taskBanner: SKNode!
    private var taskDescriptionLabel: SKLabelNode!
    private var taskProgressLabel: SKLabelNode!
    private var taskTimeLabel: SKLabelNode!
    private var healButton: SKShapeNode!
    private var storeButton: SKShapeNode!

    // Popup overlay
    private var popupOverlay: SKNode?

    // Touch tracking
    private var draggedEgg: Egg?

    override func didMove(to view: SKView) {
        gameManager = GameManager.shared
        gameManager.delegate = self

        backgroundColor = SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)

        setupHUD()
        setupEggMan()
        setupEggBasket()
        setupActionButtons()

        updateUI()
        gameManager.startGame()
    }

    override func willMove(from view: SKView) {
        gameManager.pauseGame()
    }

    // MARK: - Setup

    private func setupHUD() {
        // Diamond display with glass effect
        let diamondContainer = createGlassContainer(size: CGSize(width: 90, height: 44))
        diamondContainer.position = CGPoint(x: 60, y: size.height - 50)
        addChild(diamondContainer)

        let diamondIcon = SKLabelNode(text: "💎")
        diamondIcon.fontSize = 22
        diamondIcon.verticalAlignmentMode = .center
        diamondIcon.position = CGPoint(x: -20, y: 0)
        diamondContainer.addChild(diamondIcon)

        diamondLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        diamondLabel.fontSize = 18
        diamondLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        diamondLabel.horizontalAlignmentMode = .left
        diamondLabel.verticalAlignmentMode = .center
        diamondLabel.position = CGPoint(x: 0, y: 0)
        diamondContainer.addChild(diamondLabel)

        // Egg display with glass effect
        let eggContainer = createGlassContainer(size: CGSize(width: 90, height: 44))
        eggContainer.position = CGPoint(x: size.width - 60, y: size.height - 50)
        addChild(eggContainer)

        let eggIcon = SKLabelNode(text: "🥚")
        eggIcon.fontSize = 22
        eggIcon.verticalAlignmentMode = .center
        eggIcon.position = CGPoint(x: -20, y: 0)
        eggContainer.addChild(eggIcon)

        eggLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        eggLabel.fontSize = 18
        eggLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        eggLabel.horizontalAlignmentMode = .left
        eggLabel.verticalAlignmentMode = .center
        eggLabel.position = CGPoint(x: 0, y: 0)
        eggContainer.addChild(eggLabel)

        // Task banner
        setupTaskBanner()
    }

    /// Creates a glass-style container with frosted appearance
    private func createGlassContainer(size: CGSize, cornerRadius: CGFloat = 16) -> SKNode {
        let container = SKNode()

        // Glass background - frosted effect
        let glassBg = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        glassBg.fillColor = SKColor(white: 1.0, alpha: 0.6)
        glassBg.strokeColor = SKColor(white: 1.0, alpha: 0.8)
        glassBg.lineWidth = 1.5
        glassBg.glowWidth = 0.5
        container.addChild(glassBg)

        // Inner highlight for depth
        let highlight = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4), cornerRadius: cornerRadius - 2)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.15)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: 1)
        container.addChild(highlight)

        return container
    }

    private func setupTaskBanner() {
        taskBanner = SKNode()
        taskBanner.position = CGPoint(x: size.width / 2, y: size.height - 120)
        addChild(taskBanner)

        // Glass background for task banner
        let bannerBg = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 70), cornerRadius: 16)
        bannerBg.fillColor = SKColor(white: 1.0, alpha: 0.65)
        bannerBg.strokeColor = SKColor(white: 1.0, alpha: 0.9)
        bannerBg.lineWidth = 1.5
        bannerBg.glowWidth = 0.5
        taskBanner.addChild(bannerBg)

        // Inner highlight
        let highlight = SKShapeNode(rectOf: CGSize(width: size.width - 48, height: 62), cornerRadius: 14)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.15)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: 1)
        taskBanner.addChild(highlight)

        taskDescriptionLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        taskDescriptionLabel.fontSize = 16
        taskDescriptionLabel.fontColor = SKColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0)
        taskDescriptionLabel.position = CGPoint(x: 0, y: 10)
        taskBanner.addChild(taskDescriptionLabel)

        taskProgressLabel = SKLabelNode(fontNamed: "Helvetica")
        taskProgressLabel.fontSize = 14
        taskProgressLabel.fontColor = SKColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0)
        taskProgressLabel.position = CGPoint(x: -60, y: -15)
        taskBanner.addChild(taskProgressLabel)

        taskTimeLabel = SKLabelNode(fontNamed: "Helvetica")
        taskTimeLabel.fontSize = 14
        taskTimeLabel.fontColor = SKColor(red: 0.45, green: 0.4, blue: 0.35, alpha: 1.0)
        taskTimeLabel.position = CGPoint(x: 60, y: -15)
        taskBanner.addChild(taskTimeLabel)
    }

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
    }

    private func setupActionButtons() {
        // Heal button with glass effect (red tint)
        healButton = SKShapeNode(rectOf: CGSize(width: 110, height: 44), cornerRadius: 22)
        healButton.fillColor = SKColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.85)
        healButton.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.9)
        healButton.lineWidth = 1.5
        healButton.glowWidth = 1
        healButton.position = CGPoint(x: size.width - 75, y: 55)
        healButton.name = "healButton"
        addChild(healButton)

        // Inner highlight for heal button
        let healHighlight = SKShapeNode(rectOf: CGSize(width: 106, height: 40), cornerRadius: 20)
        healHighlight.fillColor = SKColor(white: 1.0, alpha: 0.15)
        healHighlight.strokeColor = .clear
        healHighlight.position = CGPoint(x: 0, y: 1)
        healButton.addChild(healHighlight)

        let healLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        healLabel.text = "HEAL 💎5"
        healLabel.fontSize = 14
        healLabel.fontColor = .white
        healLabel.verticalAlignmentMode = .center
        healButton.addChild(healLabel)

        // Store button with glass effect
        storeButton = SKShapeNode(rectOf: CGSize(width: 100, height: 44), cornerRadius: 22)
        storeButton.fillColor = SKColor(white: 1.0, alpha: 0.6)
        storeButton.strokeColor = SKColor(white: 1.0, alpha: 0.9)
        storeButton.lineWidth = 1.5
        storeButton.glowWidth = 0.5
        storeButton.position = CGPoint(x: 70, y: 55)
        storeButton.name = "storeButton"
        addChild(storeButton)

        // Inner highlight for store button
        let storeHighlight = SKShapeNode(rectOf: CGSize(width: 96, height: 40), cornerRadius: 20)
        storeHighlight.fillColor = SKColor(white: 1.0, alpha: 0.15)
        storeHighlight.strokeColor = .clear
        storeHighlight.position = CGPoint(x: 0, y: 1)
        storeButton.addChild(storeHighlight)

        let storeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        storeLabel.text = "🛒 STORE"
        storeLabel.fontSize = 14
        storeLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        storeLabel.verticalAlignmentMode = .center
        storeButton.addChild(storeLabel)
    }

    // MARK: - UI Updates

    private func updateUI() {
        diamondLabel.text = "\(gameManager.diamonds)"
        eggLabel.text = "\(gameManager.totalEggs)"

        if let task = gameManager.currentTask {
            taskDescriptionLabel.text = "Task: \(task.descriptionText)"
            taskProgressLabel.text = "Progress: \(task.progressText)"
            taskTimeLabel.text = gameManager.taskTimeRemaining
        } else {
            taskDescriptionLabel.text = "No active task"
            taskProgressLabel.text = ""
            taskTimeLabel.text = ""
        }

        eggBasket.updateEggCounts(from: gameManager)

        healButton.isHidden = !gameManager.isSick
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check buttons first
        let touchedNodes = nodes(at: location)
        for node in touchedNodes {
            if node.name == "healButton" || node.parent?.name == "healButton" {
                handleHealButton()
                return
            }
            if node.name == "storeButton" || node.parent?.name == "storeButton" {
                handleStoreButton()
                return
            }
        }

        // Check for popup dismissal
        if popupOverlay != nil {
            dismissPopup()
            return
        }

        // Check for egg dragging
        let basketLocation = touch.location(in: eggBasket)
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
                    self.updateUI()
                }
            }
        }
    }

    private func handleHealButton() {
        if gameManager.healEggMan() {
            eggMan.playHealAnimation {
                self.updateUI()
            }
        }
    }

    private func handleStoreButton() {
        let storeScene = StoreScene(size: size)
        storeScene.scaleMode = scaleMode

        let transition = SKTransition.push(with: .left, duration: 0.3)
        view?.presentScene(storeScene, transition: transition)
    }

    // MARK: - Popups

    private func showPopup(title: String, message: String) {
        dismissPopup()

        popupOverlay = SKNode()
        popupOverlay?.zPosition = 1000

        // Dimmed background
        let background = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        background.fillColor = SKColor(white: 0, alpha: 0.4)
        background.strokeColor = .clear
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        popupOverlay?.addChild(background)

        // Glass popup container
        let popupContainer = SKNode()
        popupContainer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        popupOverlay?.addChild(popupContainer)

        // Glass background
        let popup = SKShapeNode(rectOf: CGSize(width: 280, height: 160), cornerRadius: 24)
        popup.fillColor = SKColor(white: 1.0, alpha: 0.75)
        popup.strokeColor = SKColor(white: 1.0, alpha: 0.95)
        popup.lineWidth = 2
        popup.glowWidth = 1
        popupContainer.addChild(popup)

        // Inner highlight
        let highlight = SKShapeNode(rectOf: CGSize(width: 272, height: 152), cornerRadius: 22)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.2)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: 2)
        popupContainer.addChild(highlight)

        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 22
        titleLabel.fontColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 35)
        popupContainer.addChild(titleLabel)

        let messageLabel = SKLabelNode(fontNamed: "Helvetica")
        messageLabel.text = message
        messageLabel.fontSize = 16
        messageLabel.fontColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        messageLabel.position = CGPoint(x: 0, y: -5)
        popupContainer.addChild(messageLabel)

        let tapLabel = SKLabelNode(fontNamed: "Helvetica")
        tapLabel.text = "Tap to dismiss"
        tapLabel.fontSize = 12
        tapLabel.fontColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        tapLabel.position = CGPoint(x: 0, y: -45)
        popupContainer.addChild(tapLabel)

        addChild(popupOverlay!)

        // Animate in
        popupContainer.setScale(0.5)
        popupContainer.alpha = 0
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.25)
        scaleUp.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        popupContainer.run(SKAction.group([scaleUp, fadeIn]))
    }

    private func dismissPopup() {
        popupOverlay?.removeFromParent()
        popupOverlay = nil
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        // Update task time display periodically
        if let task = gameManager.currentTask {
            taskTimeLabel.text = gameManager.taskTimeRemaining
        }
    }
}

// MARK: - EggBasketDelegate

extension GameScene: EggBasketDelegate {
    func eggBasket(_ basket: EggBasket, didStartDragging egg: Egg) {
        // Visual feedback when starting to drag
    }

    func eggBasket(_ basket: EggBasket, didStopDragging egg: Egg, at position: CGPoint) {
        // Handled in touchesEnded
    }
}

// MARK: - GameManagerDelegate

extension GameScene: GameManagerDelegate {
    func gameStateDidUpdate() {
        updateUI()
    }

    func showDailyReward(diamonds: Int) {
        showPopup(title: "Daily Reward!", message: "You received \(diamonds) 💎")
    }

    func showTaskCompleted(reward: Int) {
        showPopup(title: "Task Complete!", message: "You earned \(reward) 💎")
    }

    func showTaskExpired() {
        showPopup(title: "Task Expired", message: "A new task has been assigned")
    }

    func eggManBecameSick() {
        eggMan.playSickAnimation()
        showPopup(title: "Oh No!", message: "Egg Man got sick! 🤢")
    }

    func eggManHealed() {
        updateUI()
    }

    func transactionFailed(reason: String) {
        showPopup(title: "Error", message: reason)
    }
}
