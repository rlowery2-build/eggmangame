import SpriteKit

class SideScrollerHUD: SKNode {

    // MARK: - Properties

    private var viewportSize: CGSize = .zero

    // Health bar components
    private var healthBarBackground: SKShapeNode!
    private var healthBarFill: SKShapeNode!
    private var healthLabel: SKLabelNode!

    // Egg count display
    private var eggCountContainer: SKNode!
    private var eggCountLabels: [EggType: SKLabelNode] = [:]
    private var totalEggLabel: SKLabelNode!

    // Control buttons
    private var leftButton: SKShapeNode!
    private var rightButton: SKShapeNode!
    private var jumpButton: SKShapeNode!
    private var attackButton: SKShapeNode!

    // Pause button
    private var pauseButton: SKShapeNode!

    // Layout constants
    private let healthBarSize = CGSize(width: 150, height: 20)
    private let buttonSize: CGFloat = 60
    private let buttonPadding: CGFloat = 20

    // MARK: - Initialization

    override init() {
        super.init()
        name = "hud"
        zPosition = 100
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    func configure(viewportSize: CGSize) {
        self.viewportSize = viewportSize
        removeAllChildren()

        setupHealthBar()
        setupEggCounter()
        setupControlButtons()
        setupPauseButton()
    }

    private func setupHealthBar() {
        let margin: CGFloat = 20
        let posX = -viewportSize.width / 2 + healthBarSize.width / 2 + margin
        let posY = viewportSize.height / 2 - healthBarSize.height / 2 - margin

        // Background
        healthBarBackground = SKShapeNode(rectOf: healthBarSize, cornerRadius: 5)
        healthBarBackground.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.8)
        healthBarBackground.strokeColor = .white
        healthBarBackground.lineWidth = 2
        healthBarBackground.position = CGPoint(x: posX, y: posY)
        addChild(healthBarBackground)

        // Fill (starts full)
        healthBarFill = SKShapeNode(rectOf: CGSize(width: healthBarSize.width - 4, height: healthBarSize.height - 4), cornerRadius: 3)
        healthBarFill.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
        healthBarFill.strokeColor = .clear
        healthBarFill.position = CGPoint(x: posX, y: posY)
        addChild(healthBarFill)

        // Heart icon
        let heartLabel = SKLabelNode(fontNamed: "Helvetica")
        heartLabel.text = "❤️"
        heartLabel.fontSize = 18
        heartLabel.position = CGPoint(x: posX - healthBarSize.width / 2 - 15, y: posY - 6)
        addChild(heartLabel)

        // HP text
        healthLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        healthLabel.text = "100/100"
        healthLabel.fontSize = 12
        healthLabel.fontColor = .white
        healthLabel.position = CGPoint(x: posX, y: posY - 5)
        healthLabel.zPosition = 1
        addChild(healthLabel)
    }

    private func setupEggCounter() {
        let margin: CGFloat = 20
        let posX = viewportSize.width / 2 - 80
        let posY = viewportSize.height / 2 - margin - 10

        eggCountContainer = SKNode()
        eggCountContainer.position = CGPoint(x: posX, y: posY)
        addChild(eggCountContainer)

        // Background panel
        let panelBg = SKShapeNode(rectOf: CGSize(width: 140, height: 80), cornerRadius: 10)
        panelBg.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.7)
        panelBg.strokeColor = SKColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0)
        panelBg.lineWidth = 2
        eggCountContainer.addChild(panelBg)

        // Title
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "EGGS"
        titleLabel.fontSize = 14
        titleLabel.fontColor = SKColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 25)
        eggCountContainer.addChild(titleLabel)

        // Egg type counts
        let types: [EggType] = [.white, .brown, .golden]
        var yOffset: CGFloat = 5

        for eggType in types {
            let rowNode = SKNode()
            rowNode.position = CGPoint(x: -40, y: yOffset)

            // Egg icon
            let iconLabel = SKLabelNode(fontNamed: "Helvetica")
            iconLabel.text = eggType.emoji
            iconLabel.fontSize = 16
            iconLabel.position = CGPoint(x: 0, y: -5)
            rowNode.addChild(iconLabel)

            // Count label
            let countLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            countLabel.text = "0"
            countLabel.fontSize = 14
            countLabel.fontColor = .white
            countLabel.horizontalAlignmentMode = .left
            countLabel.position = CGPoint(x: 20, y: -5)
            rowNode.addChild(countLabel)

            eggCountLabels[eggType] = countLabel
            eggCountContainer.addChild(rowNode)

            yOffset -= 20
        }
    }

    private func setupControlButtons() {
        let bottomMargin: CGFloat = 30

        // Left button
        leftButton = createControlButton(symbol: "◀")
        leftButton.name = "leftButton"
        leftButton.position = CGPoint(
            x: -viewportSize.width / 2 + buttonPadding + buttonSize / 2,
            y: -viewportSize.height / 2 + bottomMargin + buttonSize / 2
        )
        addChild(leftButton)

        // Right button
        rightButton = createControlButton(symbol: "▶")
        rightButton.name = "rightButton"
        rightButton.position = CGPoint(
            x: -viewportSize.width / 2 + buttonPadding * 2 + buttonSize * 1.5,
            y: -viewportSize.height / 2 + bottomMargin + buttonSize / 2
        )
        addChild(rightButton)

        // Jump button
        jumpButton = createControlButton(symbol: "⬆")
        jumpButton.name = "jumpButton"
        jumpButton.position = CGPoint(
            x: viewportSize.width / 2 - buttonPadding * 2 - buttonSize * 1.5,
            y: -viewportSize.height / 2 + bottomMargin + buttonSize / 2
        )
        addChild(jumpButton)

        // Attack button
        attackButton = createControlButton(symbol: "⚔")
        attackButton.name = "attackButton"
        attackButton.position = CGPoint(
            x: viewportSize.width / 2 - buttonPadding - buttonSize / 2,
            y: -viewportSize.height / 2 + bottomMargin + buttonSize / 2
        )
        addChild(attackButton)
    }

    private func createControlButton(symbol: String) -> SKShapeNode {
        let button = SKShapeNode(circleOfRadius: buttonSize / 2)
        button.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.7)
        button.strokeColor = .white
        button.lineWidth = 3

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = symbol
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)

        return button
    }

    private func setupPauseButton() {
        pauseButton = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 8)
        pauseButton.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.7)
        pauseButton.strokeColor = .white
        pauseButton.lineWidth = 2
        pauseButton.name = "pauseButton"
        pauseButton.position = CGPoint(
            x: 0,
            y: viewportSize.height / 2 - 30
        )
        addChild(pauseButton)

        let pauseLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        pauseLabel.text = "⏸"
        pauseLabel.fontSize = 20
        pauseLabel.verticalAlignmentMode = .center
        pauseButton.addChild(pauseLabel)
    }

    // MARK: - Updates

    func updateHealth(current: Int, max: Int) {
        let percentage = CGFloat(current) / CGFloat(max)
        let fillWidth = (healthBarSize.width - 4) * percentage

        // Update fill bar width (recreate shape)
        let newFillPath = CGPath(
            roundedRect: CGRect(
                x: -fillWidth / 2,
                y: -(healthBarSize.height - 4) / 2,
                width: fillWidth,
                height: healthBarSize.height - 4
            ),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        healthBarFill.path = newFillPath

        // Update fill position to align left
        let offsetX = (healthBarSize.width - 4 - fillWidth) / 2
        healthBarFill.position.x = healthBarBackground.position.x - offsetX

        // Update color based on health
        if percentage > 0.5 {
            healthBarFill.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
        } else if percentage > 0.25 {
            healthBarFill.fillColor = SKColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
        } else {
            healthBarFill.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        }

        healthLabel.text = "\(current)/\(max)"
    }

    func updateEggCount(type: EggType, count: Int) {
        eggCountLabels[type]?.text = "\(count)"
    }

    func updateAllEggCounts(_ counts: [EggType: Int]) {
        for (type, count) in counts {
            updateEggCount(type: type, count: count)
        }
    }

    // MARK: - Input Handling

    func getButtonAt(location: CGPoint) -> String? {
        let nodes = [leftButton, rightButton, jumpButton, attackButton, pauseButton]
        for node in nodes {
            if let node = node, node.contains(location) {
                return node.name
            }
        }
        return nil
    }

    func highlightButton(_ name: String, highlighted: Bool) {
        var button: SKShapeNode?

        switch name {
        case "leftButton": button = leftButton
        case "rightButton": button = rightButton
        case "jumpButton": button = jumpButton
        case "attackButton": button = attackButton
        case "pauseButton": button = pauseButton
        default: break
        }

        if let button = button {
            button.fillColor = highlighted
                ? SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.9)
                : SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.7)
        }
    }
}
