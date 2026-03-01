import SpriteKit

class MenuScene: SKScene {

    private var titleLabel: SKLabelNode!
    private var playButton: SKShapeNode!
    private var adventureButton: SKShapeNode!
    private var eggManPreview: EggMan!

    // Callbacks for SwiftUI navigation
    var onPlayPressed: (() -> Void)?
    var onAdventurePressed: (() -> Void)?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)

        setupTitle()
        setupEggManPreview()
        setupPlayButton()
        setupAdventureButton()
        setupSubtitle()
    }

    private func setupTitle() {
        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "Egg Man"
        titleLabel.fontSize = 56
        titleLabel.fontColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        addChild(titleLabel)

        let bounceUp = SKAction.moveBy(x: 0, y: 10, duration: 1.0)
        bounceUp.timingMode = .easeInEaseOut
        let bounceDown = SKAction.moveBy(x: 0, y: -10, duration: 1.0)
        bounceDown.timingMode = .easeInEaseOut
        let bounce = SKAction.sequence([bounceUp, bounceDown])
        titleLabel.run(SKAction.repeatForever(bounce))
    }

    private func setupEggManPreview() {
        eggManPreview = EggMan()
        eggManPreview.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        eggManPreview.setScale(0.8)
        addChild(eggManPreview)

        let rotate1 = SKAction.rotate(byAngle: 0.05, duration: 0.5)
        let rotate2 = SKAction.rotate(byAngle: -0.1, duration: 1.0)
        let rotate3 = SKAction.rotate(byAngle: 0.05, duration: 0.5)
        let rotateSequence = SKAction.sequence([rotate1, rotate2, rotate3])
        eggManPreview.run(SKAction.repeatForever(rotateSequence))
    }

    private func setupPlayButton() {
        playButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 15)
        playButton.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0)
        playButton.strokeColor = SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        playButton.lineWidth = 4
        playButton.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
        playButton.name = "playButton"
        addChild(playButton)

        let playLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        playLabel.text = "PLAY"
        playLabel.fontSize = 28
        playLabel.fontColor = .white
        playLabel.verticalAlignmentMode = .center
        playButton.addChild(playLabel)

        let scaleUp = SKAction.scale(to: 1.05, duration: 0.5)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        playButton.run(SKAction.repeatForever(pulse))
    }

    private func setupAdventureButton() {
        adventureButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 15)
        adventureButton.fillColor = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        adventureButton.strokeColor = SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        adventureButton.lineWidth = 4
        adventureButton.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        adventureButton.name = "adventureButton"
        addChild(adventureButton)

        let adventureLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        adventureLabel.text = "ADVENTURE"
        adventureLabel.fontSize = 24
        adventureLabel.fontColor = .white
        adventureLabel.verticalAlignmentMode = .center
        adventureButton.addChild(adventureLabel)

        // Add egg icon
        let eggIcon = SKLabelNode(fontNamed: "Helvetica")
        eggIcon.text = "🥚"
        eggIcon.fontSize = 20
        eggIcon.position = CGPoint(x: -70, y: -2)
        adventureButton.addChild(eggIcon)

        let scaleUp = SKAction.scale(to: 1.05, duration: 0.6)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.6)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        adventureButton.run(SKAction.repeatForever(pulse))
    }

    private func setupSubtitle() {
        let subtitleLabel = SKLabelNode(fontNamed: "Helvetica")
        subtitleLabel.text = "Feed the hungry egg man!"
        subtitleLabel.fontSize = 20
        subtitleLabel.fontColor = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        addChild(subtitleLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if node.name == "playButton" || node.parent?.name == "playButton" {
                animateButtonPress()
                return
            }
            if node.name == "adventureButton" || node.parent?.name == "adventureButton" {
                animateAdventureButtonPress()
                return
            }
        }
    }

    private func animateButtonPress() {
        let pressDown = SKAction.scale(to: 0.9, duration: 0.1)
        let pressUp = SKAction.scale(to: 1.0, duration: 0.1)
        let transition = SKAction.run { [weak self] in
            self?.transitionToGame()
        }

        playButton.run(SKAction.sequence([pressDown, pressUp, transition]))
    }

    private func transitionToGame() {
        // Use callback if available (SwiftUI navigation)
        if let onPlayPressed = onPlayPressed {
            onPlayPressed()
            return
        }

        // Fallback to direct scene transition
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode

        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }

    private func animateAdventureButtonPress() {
        let pressDown = SKAction.scale(to: 0.9, duration: 0.1)
        let pressUp = SKAction.scale(to: 1.0, duration: 0.1)
        let transition = SKAction.run { [weak self] in
            self?.transitionToAdventure()
        }

        adventureButton.run(SKAction.sequence([pressDown, pressUp, transition]))
    }

    private func transitionToAdventure() {
        // Use callback if available (SwiftUI navigation)
        if let onAdventurePressed = onAdventurePressed {
            onAdventurePressed()
            return
        }

        // Fallback to direct scene transition
        let adventureScene = SideScrollerScene(size: size)
        adventureScene.scaleMode = scaleMode

        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(adventureScene, transition: transition)
    }
}
