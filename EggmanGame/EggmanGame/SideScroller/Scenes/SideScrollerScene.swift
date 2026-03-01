import SpriteKit

protocol SideScrollerSceneDelegate: AnyObject {
    func sideScrollerDidComplete(collectedEggs: [EggType: Int])
    func sideScrollerDidExit()
}

class SideScrollerScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Properties

    weak var gameDelegate: SideScrollerSceneDelegate?

    private var player: EggHero!
    private var gameCamera: SideScrollerCamera!
    private var hud: SideScrollerHUD!

    private var enemies: [SlimeEnemy] = []
    private var collectibleEggs: [CollectibleEgg] = []
    private var collectedEggs: [EggType: Int] = [:]

    private var lastUpdateTime: TimeInterval = 0
    private var isGamePaused: Bool = false
    private var isLevelComplete: Bool = false

    // Input state
    private var movementDirection: CGFloat = 0
    private var activeButtonTouches: [UITouch: String] = [:]

    // Level configuration
    private var levelWidth: CGFloat = 2000
    private var levelHeight: CGFloat = 600
    private var levelBounds: CGRect {
        CGRect(x: 0, y: 0, width: levelWidth, height: levelHeight)
    }

    // Layers
    private var backgroundLayer: SKNode!
    private var worldLayer: SKNode!
    private var foregroundLayer: SKNode!

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)

        setupPhysicsWorld()
        setupLayers()
        setupCamera()
        setupPlayer()
        setupLevel()
        setupHUD()

        // Initialize collected eggs counter
        for type in EggType.allCases {
            collectedEggs[type] = 0
        }
    }

    override func willMove(from view: SKView) {
        removeAllActions()
        removeAllChildren()
    }

    // MARK: - Setup

    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        physicsWorld.contactDelegate = self
    }

    private func setupLayers() {
        backgroundLayer = SKNode()
        backgroundLayer.zPosition = -100
        addChild(backgroundLayer)

        worldLayer = SKNode()
        worldLayer.zPosition = 0
        addChild(worldLayer)

        foregroundLayer = SKNode()
        foregroundLayer.zPosition = 50
        addChild(foregroundLayer)
    }

    private func setupCamera() {
        gameCamera = SideScrollerCamera()
        camera = gameCamera
        addChild(gameCamera)
    }

    private func setupPlayer() {
        player = EggHero()
        player.position = CGPoint(x: 100, y: 150)
        player.zPosition = 10
        worldLayer.addChild(player)

        gameCamera.configure(target: player, levelBounds: levelBounds, viewportSize: size)
    }

    private func setupLevel() {
        createBackground()
        createGround()
        createPlatforms()
        createEnemies()
        createCollectibles()
        createLevelExit()
    }

    private func setupHUD() {
        hud = SideScrollerHUD()
        hud.configure(viewportSize: size)
        gameCamera.addChild(hud)

        updateHUD()
    }

    // MARK: - Level Building

    private func createBackground() {
        // Gradient sky
        let skyGradient = SKSpriteNode(color: SKColor(red: 0.5, green: 0.7, blue: 0.95, alpha: 1.0), size: CGSize(width: levelWidth, height: levelHeight))
        skyGradient.position = CGPoint(x: levelWidth / 2, y: levelHeight / 2)
        skyGradient.zPosition = -10
        backgroundLayer.addChild(skyGradient)

        // Clouds
        for i in 0..<5 {
            let cloud = createCloud()
            cloud.position = CGPoint(
                x: CGFloat(i) * 400 + CGFloat.random(in: 0...100),
                y: levelHeight - CGFloat.random(in: 50...150)
            )
            backgroundLayer.addChild(cloud)
        }

        // Castle towers in background (castle theme)
        for i in 0..<3 {
            let tower = createCastleTower()
            tower.position = CGPoint(x: 300 + CGFloat(i) * 600, y: 200)
            tower.setScale(0.6)
            tower.alpha = 0.5
            tower.zPosition = -5
            backgroundLayer.addChild(tower)
        }
    }

    private func createCloud() -> SKNode {
        let cloudNode = SKNode()

        let sizes: [(CGFloat, CGPoint)] = [
            (30, CGPoint(x: -20, y: 0)),
            (40, CGPoint(x: 0, y: 5)),
            (35, CGPoint(x: 25, y: 0)),
            (25, CGPoint(x: 40, y: -5))
        ]

        for (radius, offset) in sizes {
            let puff = SKShapeNode(circleOfRadius: radius)
            puff.fillColor = .white
            puff.strokeColor = .clear
            puff.alpha = 0.8
            puff.position = offset
            cloudNode.addChild(puff)
        }

        return cloudNode
    }

    private func createCastleTower() -> SKNode {
        let tower = SKNode()

        // Tower body
        let body = SKShapeNode(rectOf: CGSize(width: 60, height: 150))
        body.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: 75)
        tower.addChild(body)

        // Tower top (cone)
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: -35, y: 150))
        topPath.addLine(to: CGPoint(x: 0, y: 200))
        topPath.addLine(to: CGPoint(x: 35, y: 150))
        topPath.closeSubpath()

        let top = SKShapeNode(path: topPath)
        top.fillColor = SKColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 1.0)
        top.strokeColor = SKColor(red: 0.4, green: 0.2, blue: 0.2, alpha: 1.0)
        tower.addChild(top)

        return tower
    }

    private func createGround() {
        // Main ground
        let groundHeight: CGFloat = 100
        let ground = SKShapeNode(rectOf: CGSize(width: levelWidth, height: groundHeight))
        ground.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        ground.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.15, alpha: 1.0)
        ground.lineWidth = 3
        ground.position = CGPoint(x: levelWidth / 2, y: groundHeight / 2)

        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: levelWidth, height: groundHeight))
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        ground.physicsBody?.contactTestBitMask = PhysicsCategory.player
        ground.physicsBody?.isDynamic = false
        ground.name = "ground"

        worldLayer.addChild(ground)

        // Grass on top
        for x in stride(from: CGFloat(20), to: levelWidth, by: 40) {
            let grass = createGrassTuft()
            grass.position = CGPoint(x: x, y: groundHeight)
            worldLayer.addChild(grass)
        }

        // Left wall
        createWall(at: CGPoint(x: -10, y: levelHeight / 2), height: levelHeight)

        // Right wall
        createWall(at: CGPoint(x: levelWidth + 10, y: levelHeight / 2), height: levelHeight)
    }

    private func createGrassTuft() -> SKNode {
        let grass = SKNode()
        for i in -2...2 {
            let blade = SKShapeNode(rectOf: CGSize(width: 4, height: 15 + CGFloat.random(in: 0...10)))
            blade.fillColor = SKColor(red: 0.3, green: 0.6, blue: 0.2, alpha: 1.0)
            blade.strokeColor = .clear
            blade.position = CGPoint(x: CGFloat(i) * 5, y: 5)
            blade.zRotation = CGFloat.random(in: -0.2...0.2)
            grass.addChild(blade)
        }
        return grass
    }

    private func createWall(at position: CGPoint, height: CGFloat) {
        let wall = SKNode()
        wall.position = position

        wall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: height))
        wall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        wall.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        wall.physicsBody?.isDynamic = false
        wall.name = "wall"

        worldLayer.addChild(wall)
    }

    private func createPlatforms() {
        let platformConfigs: [(x: CGFloat, y: CGFloat, width: CGFloat)] = [
            (300, 200, 150),
            (550, 280, 120),
            (800, 200, 180),
            (1100, 320, 140),
            (1400, 240, 160),
            (1700, 350, 120)
        ]

        for config in platformConfigs {
            let platform = createPlatform(width: config.width)
            platform.position = CGPoint(x: config.x, y: config.y)
            worldLayer.addChild(platform)
        }
    }

    private func createPlatform(width: CGFloat) -> SKNode {
        let platform = SKShapeNode(rectOf: CGSize(width: width, height: 20), cornerRadius: 5)
        platform.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        platform.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)
        platform.lineWidth = 2

        platform.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: 20))
        platform.physicsBody?.categoryBitMask = PhysicsCategory.platform
        platform.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        platform.physicsBody?.contactTestBitMask = PhysicsCategory.player
        platform.physicsBody?.isDynamic = false
        platform.name = "platform"

        return platform
    }

    private func createEnemies() {
        let enemyPositions: [CGPoint] = [
            CGPoint(x: 400, y: 130),
            CGPoint(x: 700, y: 130),
            CGPoint(x: 1000, y: 130),
            CGPoint(x: 1300, y: 130),
            CGPoint(x: 600, y: 310)
        ]

        for position in enemyPositions {
            let enemy = SlimeEnemy()
            enemy.position = position
            enemy.startPatrolling()
            worldLayer.addChild(enemy)
            enemies.append(enemy)
        }
    }

    private func createCollectibles() {
        let eggConfigs: [(x: CGFloat, y: CGFloat, type: EggType)] = [
            (200, 150, .white),
            (350, 250, .white),
            (500, 150, .brown),
            (650, 330, .white),
            (850, 250, .brown),
            (1000, 150, .white),
            (1150, 370, .golden),
            (1350, 150, .brown),
            (1500, 290, .white),
            (1800, 400, .golden)
        ]

        for config in eggConfigs {
            let egg = CollectibleEgg(type: config.type)
            egg.position = CGPoint(x: config.x, y: config.y)
            worldLayer.addChild(egg)
            collectibleEggs.append(egg)
        }
    }

    private func createLevelExit() {
        // Exit door at end of level
        let door = SKShapeNode(rectOf: CGSize(width: 60, height: 100), cornerRadius: 5)
        door.fillColor = SKColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0)
        door.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        door.lineWidth = 3
        door.position = CGPoint(x: levelWidth - 80, y: 150)
        door.name = "exit"

        // Door frame
        let frame = SKShapeNode(rectOf: CGSize(width: 70, height: 110), cornerRadius: 8)
        frame.fillColor = .clear
        frame.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        frame.lineWidth = 5
        door.addChild(frame)

        // Door knob
        let knob = SKShapeNode(circleOfRadius: 5)
        knob.fillColor = SKColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1.0)
        knob.position = CGPoint(x: 20, y: 0)
        door.addChild(knob)

        // Exit text
        let exitLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        exitLabel.text = "EXIT"
        exitLabel.fontSize = 16
        exitLabel.fontColor = .white
        exitLabel.position = CGPoint(x: 0, y: 60)
        door.addChild(exitLabel)

        // Exit trigger
        let exitTrigger = SKNode()
        exitTrigger.position = door.position
        exitTrigger.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 100))
        exitTrigger.physicsBody?.categoryBitMask = PhysicsCategory.collectible
        exitTrigger.physicsBody?.contactTestBitMask = PhysicsCategory.player
        exitTrigger.physicsBody?.collisionBitMask = PhysicsCategory.none
        exitTrigger.physicsBody?.isDynamic = false
        exitTrigger.name = "exitTrigger"

        worldLayer.addChild(door)
        worldLayer.addChild(exitTrigger)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isGamePaused && !isLevelComplete else { return }

        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Update player movement
        player.move(direction: movementDirection)

        // Update camera
        gameCamera.update(deltaTime: deltaTime)

        // Update enemies
        for enemy in enemies {
            enemy.update(deltaTime: deltaTime)
        }

        // Check for player death
        if player.isDead {
            handlePlayerDeath()
        }

        // Update grounded state
        updatePlayerGroundedState()
    }

    private func updatePlayerGroundedState() {
        guard let playerBody = player.physicsBody else { return }

        // Check if player is on ground/platform
        let isGrounded = abs(playerBody.velocity.dy) < 1.0
        player.setGrounded(isGrounded)
    }

    private func updateHUD() {
        hud.updateHealth(current: player.currentHealth, max: player.maxHealth)
        hud.updateAllEggCounts(collectedEggs)
    }

    // MARK: - Touch Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let locationInCamera = touch.location(in: gameCamera)

            if let buttonName = hud.getButtonAt(location: locationInCamera) {
                activeButtonTouches[touch] = buttonName
                handleButtonPress(buttonName)
                hud.highlightButton(buttonName, highlighted: true)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let locationInCamera = touch.location(in: gameCamera)
            let currentButton = hud.getButtonAt(location: locationInCamera)

            if let previousButton = activeButtonTouches[touch] {
                if currentButton != previousButton {
                    // Finger moved off button
                    hud.highlightButton(previousButton, highlighted: false)
                    handleButtonRelease(previousButton)

                    if let newButton = currentButton {
                        activeButtonTouches[touch] = newButton
                        handleButtonPress(newButton)
                        hud.highlightButton(newButton, highlighted: true)
                    } else {
                        activeButtonTouches.removeValue(forKey: touch)
                    }
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let buttonName = activeButtonTouches[touch] {
                hud.highlightButton(buttonName, highlighted: false)
                handleButtonRelease(buttonName)
                activeButtonTouches.removeValue(forKey: touch)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func handleButtonPress(_ buttonName: String) {
        switch buttonName {
        case "leftButton":
            movementDirection = -1
        case "rightButton":
            movementDirection = 1
        case "jumpButton":
            player.jump()
        case "attackButton":
            player.attack(currentTime: lastUpdateTime)
        case "pauseButton":
            togglePause()
        default:
            break
        }
    }

    private func handleButtonRelease(_ buttonName: String) {
        switch buttonName {
        case "leftButton":
            if movementDirection < 0 {
                movementDirection = 0
            }
        case "rightButton":
            if movementDirection > 0 {
                movementDirection = 0
            }
        default:
            break
        }
    }

    // MARK: - Physics Contact

    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        // Extract data before crossing isolation boundary
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let bodyACategory = contact.bodyA.categoryBitMask
        let bodyANode = contact.bodyA.node
        let bodyBNode = contact.bodyB.node

        MainActor.assumeIsolated {
            handleContact(collision: collision, bodyACategory: bodyACategory, bodyANode: bodyANode, bodyBNode: bodyBNode)
        }
    }

    private func handleContact(collision: UInt32, bodyACategory: UInt32, bodyANode: SKNode?, bodyBNode: SKNode?) {
        // Player touches ground/platform
        if collision == PhysicsCategory.player | PhysicsCategory.ground ||
           collision == PhysicsCategory.player | PhysicsCategory.platform {
            player.setGrounded(true)
        }

        // Player attacks enemy
        if collision == PhysicsCategory.playerAttack | PhysicsCategory.enemy {
            let enemyNode = (bodyACategory == PhysicsCategory.enemy) ? bodyANode : bodyBNode
            if let enemy = enemyNode as? SlimeEnemy {
                enemy.takeDamage(player.attackPower)
                gameCamera.shake(intensity: 5, duration: 0.1)
            }
        }

        // Player touches enemy
        if collision == PhysicsCategory.player | PhysicsCategory.enemy {
            let enemyNode = (bodyACategory == PhysicsCategory.enemy) ? bodyANode : bodyBNode
            if let enemy = enemyNode as? SlimeEnemy, enemy.isAlive && !player.isInvulnerable {
                player.takeDamage(enemy.contactDamage)
                gameCamera.shake(intensity: 8, duration: 0.2)
                updateHUD()
            }
        }

        // Player collects egg
        if collision == PhysicsCategory.player | PhysicsCategory.collectible {
            let collectibleNode = (bodyACategory == PhysicsCategory.collectible) ? bodyANode : bodyBNode

            if let egg = collectibleNode as? CollectibleEgg, !egg.isCollected {
                egg.collect {
                    self.collectibleEggs.removeAll { $0 === egg }
                }
                collectedEggs[egg.eggType, default: 0] += 1
                updateHUD()
            } else if collectibleNode?.name == "exitTrigger" {
                handleLevelComplete()
            }
        }

        // Enemy hits wall
        if collision == PhysicsCategory.enemy | PhysicsCategory.wall {
            let enemyNode = (bodyACategory == PhysicsCategory.enemy) ? bodyANode : bodyBNode
            if let enemy = enemyNode as? SlimeEnemy {
                enemy.reverseDirection()
            }
        }
    }

    nonisolated func didEnd(_ contact: SKPhysicsContact) {
        // Handle contact end if needed
    }

    // MARK: - Game State

    private func togglePause() {
        isGamePaused = !isGamePaused
        self.isPaused = isGamePaused

        if isGamePaused {
            showPauseMenu()
        } else {
            hidePauseMenu()
        }
    }

    private func showPauseMenu() {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.zPosition = 200
        overlay.name = "pauseOverlay"
        gameCamera.addChild(overlay)

        let pauseLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        pauseLabel.text = "PAUSED"
        pauseLabel.fontSize = 48
        pauseLabel.fontColor = .white
        pauseLabel.position = CGPoint(x: 0, y: 50)
        pauseLabel.zPosition = 201
        pauseLabel.name = "pauseLabel"
        gameCamera.addChild(pauseLabel)

        // Resume button
        let resumeButton = SKShapeNode(rectOf: CGSize(width: 150, height: 50), cornerRadius: 10)
        resumeButton.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0)
        resumeButton.strokeColor = .white
        resumeButton.lineWidth = 2
        resumeButton.position = CGPoint(x: 0, y: -20)
        resumeButton.zPosition = 201
        resumeButton.name = "resumeButton"
        gameCamera.addChild(resumeButton)

        let resumeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        resumeLabel.text = "RESUME"
        resumeLabel.fontSize = 20
        resumeLabel.fontColor = .white
        resumeLabel.verticalAlignmentMode = .center
        resumeButton.addChild(resumeLabel)

        // Exit button
        let exitButton = SKShapeNode(rectOf: CGSize(width: 150, height: 50), cornerRadius: 10)
        exitButton.fillColor = SKColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        exitButton.strokeColor = .white
        exitButton.lineWidth = 2
        exitButton.position = CGPoint(x: 0, y: -80)
        exitButton.zPosition = 201
        exitButton.name = "exitButton"
        gameCamera.addChild(exitButton)

        let exitLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        exitLabel.text = "EXIT"
        exitLabel.fontSize = 20
        exitLabel.fontColor = .white
        exitLabel.verticalAlignmentMode = .center
        exitButton.addChild(exitLabel)
    }

    private func hidePauseMenu() {
        gameCamera.childNode(withName: "pauseOverlay")?.removeFromParent()
        gameCamera.childNode(withName: "pauseLabel")?.removeFromParent()
        gameCamera.childNode(withName: "resumeButton")?.removeFromParent()
        gameCamera.childNode(withName: "exitButton")?.removeFromParent()
    }

    private func handleLevelComplete() {
        guard !isLevelComplete else { return }
        isLevelComplete = true

        // Flash effect
        gameCamera.flash(color: .white, duration: 0.3)

        // Show completion UI
        let completeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        completeLabel.text = "LEVEL COMPLETE!"
        completeLabel.fontSize = 40
        completeLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        completeLabel.position = CGPoint(x: 0, y: 50)
        completeLabel.zPosition = 200
        gameCamera.addChild(completeLabel)

        // Show eggs collected
        var yOffset: CGFloat = 0
        for (type, count) in collectedEggs where count > 0 {
            let eggLabel = SKLabelNode(fontNamed: "Helvetica")
            eggLabel.text = "\(type.emoji) x\(count)"
            eggLabel.fontSize = 24
            eggLabel.fontColor = .white
            eggLabel.position = CGPoint(x: 0, y: yOffset)
            eggLabel.zPosition = 200
            gameCamera.addChild(eggLabel)
            yOffset -= 35
        }

        // Return to menu after delay
        let waitAction = SKAction.wait(forDuration: 3.0)
        let completeAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.gameDelegate?.sideScrollerDidComplete(collectedEggs: self.collectedEggs)
        }
        run(SKAction.sequence([waitAction, completeAction]))
    }

    private func handlePlayerDeath() {
        guard !isLevelComplete else { return }
        isLevelComplete = true

        gameCamera.shake(intensity: 15, duration: 0.5)

        let deathLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        deathLabel.text = "GAME OVER"
        deathLabel.fontSize = 40
        deathLabel.fontColor = .red
        deathLabel.position = CGPoint(x: 0, y: 0)
        deathLabel.zPosition = 200
        gameCamera.addChild(deathLabel)

        // Return to menu after delay (eggs are lost)
        let waitAction = SKAction.wait(forDuration: 2.0)
        let exitAction = SKAction.run { [weak self] in
            self?.gameDelegate?.sideScrollerDidExit()
        }
        run(SKAction.sequence([waitAction, exitAction]))
    }
}
