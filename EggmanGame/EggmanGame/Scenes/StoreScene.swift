import SpriteKit

class StoreScene: SKScene {

    private var gameManager: GameManager!
    private var iapManager: IAPManager!
    private var diamondLabel: SKLabelNode!
    private var loadingOverlay: SKNode?

    // Callback for SwiftUI navigation
    var onBackPressed: (() -> Void)?

    override func didMove(to view: SKView) {
        gameManager = GameManager.shared
        iapManager = IAPManager.shared
        iapManager.delegate = self

        backgroundColor = SKColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)

        setupHeader()
        setupDiamondPacks()
        setupEggPurchase()
        setupBackButton()

        _Concurrency.Task { @MainActor [weak self] in
            await self?.iapManager.loadProducts()
        }
    }

    private func setupHeader() {
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "Diamond Store"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 60)
        addChild(titleLabel)

        // Current diamonds
        let diamondIcon = SKLabelNode(text: "💎")
        diamondIcon.fontSize = 24
        diamondIcon.position = CGPoint(x: size.width / 2 - 40, y: size.height - 100)
        addChild(diamondIcon)

        diamondLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        diamondLabel.fontSize = 24
        diamondLabel.fontColor = .white
        diamondLabel.horizontalAlignmentMode = .left
        diamondLabel.position = CGPoint(x: size.width / 2 - 15, y: size.height - 105)
        diamondLabel.text = "\(gameManager.diamonds)"
        addChild(diamondLabel)
    }

    private func setupDiamondPacks() {
        let sectionLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        sectionLabel.text = "Buy Diamonds"
        sectionLabel.fontSize = 20
        sectionLabel.fontColor = SKColor(white: 0.9, alpha: 1.0)
        sectionLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        addChild(sectionLabel)

        let packs: [(diamonds: Int, price: String, productId: String)] = [
            (100, "$0.99", IAPManager.ProductID.diamonds100),
            (500, "$3.99", IAPManager.ProductID.diamonds500),
            (1500, "$9.99", IAPManager.ProductID.diamonds1500)
        ]

        let startY = size.height - 220
        let packHeight: CGFloat = 70
        let packSpacing: CGFloat = 10

        for (index, pack) in packs.enumerated() {
            let y = startY - CGFloat(index) * (packHeight + packSpacing)
            createDiamondPackButton(
                diamonds: pack.diamonds,
                price: pack.price,
                productId: pack.productId,
                position: CGPoint(x: size.width / 2, y: y)
            )
        }
    }

    private func createDiamondPackButton(diamonds: Int, price: String, productId: String, position: CGPoint) {
        let button = SKShapeNode(rectOf: CGSize(width: size.width - 60, height: 60), cornerRadius: 10)
        button.fillColor = SKColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1.0)
        button.lineWidth = 2
        button.position = position
        button.name = "pack_\(productId)"
        addChild(button)

        let diamondText = SKLabelNode(fontNamed: "Helvetica-Bold")
        diamondText.text = "💎 \(diamonds)"
        diamondText.fontSize = 20
        diamondText.fontColor = .white
        diamondText.horizontalAlignmentMode = .left
        diamondText.verticalAlignmentMode = .center
        diamondText.position = CGPoint(x: -button.frame.width / 2 + 20, y: 0)
        button.addChild(diamondText)

        let priceText = SKLabelNode(fontNamed: "Helvetica-Bold")
        priceText.text = price
        priceText.fontSize = 18
        priceText.fontColor = SKColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0)
        priceText.horizontalAlignmentMode = .right
        priceText.verticalAlignmentMode = .center
        priceText.position = CGPoint(x: button.frame.width / 2 - 20, y: 0)
        button.addChild(priceText)
    }

    private func setupEggPurchase() {
        let sectionLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        sectionLabel.text = "Buy Eggs (10 💎 = 10 eggs)"
        sectionLabel.fontSize = 18
        sectionLabel.fontColor = SKColor(white: 0.9, alpha: 1.0)
        sectionLabel.position = CGPoint(x: size.width / 2, y: size.height - 440)
        addChild(sectionLabel)

        let eggTypes = EggType.allCases
        let buttonWidth: CGFloat = 70
        let spacing: CGFloat = 10
        let totalWidth = CGFloat(eggTypes.count) * buttonWidth + CGFloat(eggTypes.count - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + buttonWidth / 2

        for (index, eggType) in eggTypes.enumerated() {
            let x = startX + CGFloat(index) * (buttonWidth + spacing)
            createEggButton(type: eggType, position: CGPoint(x: x, y: size.height - 500))
        }
    }

    private func createEggButton(type: EggType, position: CGPoint) {
        let button = SKShapeNode(rectOf: CGSize(width: 65, height: 80), cornerRadius: 8)
        button.fillColor = SKColor(white: 0.25, alpha: 1.0)
        button.strokeColor = type.color
        button.lineWidth = 3
        button.position = position
        button.name = "egg_\(type.rawValue)"
        addChild(button)

        let egg = Egg(type: type)
        egg.setScale(0.7)
        egg.position = CGPoint(x: 0, y: 10)
        egg.isUserInteractionEnabled = false
        button.addChild(egg)

        let countLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        countLabel.text = "\(gameManager.eggCount(for: type))"
        countLabel.fontSize = 14
        countLabel.fontColor = .white
        countLabel.position = CGPoint(x: 0, y: -30)
        button.addChild(countLabel)
    }

    private func setupBackButton() {
        let backButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 8)
        backButton.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        backButton.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        backButton.lineWidth = 2
        backButton.position = CGPoint(x: size.width / 2, y: 60)
        backButton.name = "backButton"
        addChild(backButton)

        let backLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        backLabel.text = "BACK"
        backLabel.fontSize = 16
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backButton.addChild(backLabel)
    }

    private func updateUI() {
        diamondLabel.text = "\(gameManager.diamonds)"

        // Update egg counts
        for eggType in EggType.allCases {
            if let button = childNode(withName: "egg_\(eggType.rawValue)") as? SKShapeNode {
                if let countLabel = button.children.compactMap({ $0 as? SKLabelNode }).last {
                    countLabel.text = "\(gameManager.eggCount(for: eggType))"
                }
            }
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            guard let name = node.name ?? node.parent?.name else { continue }

            if name == "backButton" {
                goBack()
                return
            }

            if name.hasPrefix("pack_") {
                let productId = String(name.dropFirst(5))
                purchaseDiamonds(productId: productId)
                return
            }

            if name.hasPrefix("egg_") {
                let typeString = String(name.dropFirst(4))
                if let eggType = EggType(rawValue: typeString) {
                    purchaseEggs(type: eggType)
                }
                return
            }
        }
    }

    private func goBack() {
        // Use callback if available (SwiftUI navigation)
        if let onBackPressed = onBackPressed {
            onBackPressed()
            return
        }

        // Fallback to direct scene transition
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode

        let transition = SKTransition.push(with: .right, duration: 0.3)
        view?.presentScene(gameScene, transition: transition)
    }

    private func purchaseDiamonds(productId: String) {
        showLoading()
        _Concurrency.Task { @MainActor [weak self] in
            await self?.iapManager.purchase(productId: productId)
        }
    }

    private func purchaseEggs(type: EggType) {
        if gameManager.buyEggs(type: type) {
            updateUI()
            showFeedback(message: "Purchased 10 \(type.displayName) eggs!")
        } else {
            showFeedback(message: "Not enough diamonds!")
        }
    }

    private func showLoading() {
        loadingOverlay = SKNode()
        loadingOverlay?.zPosition = 1000

        let background = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        background.fillColor = SKColor(white: 0, alpha: 0.5)
        background.strokeColor = .clear
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        loadingOverlay?.addChild(background)

        let loadingLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        loadingLabel.text = "Processing..."
        loadingLabel.fontSize = 24
        loadingLabel.fontColor = .white
        loadingLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        loadingOverlay?.addChild(loadingLabel)

        addChild(loadingOverlay!)
    }

    private func hideLoading() {
        loadingOverlay?.removeFromParent()
        loadingOverlay = nil
    }

    private func showFeedback(message: String) {
        let feedbackLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        feedbackLabel.text = message
        feedbackLabel.fontSize = 16
        feedbackLabel.fontColor = .white
        feedbackLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        feedbackLabel.zPosition = 500
        addChild(feedbackLabel)

        let fadeOut = SKAction.fadeOut(withDuration: 1.5)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 1.5)
        let group = SKAction.group([fadeOut, moveUp])
        let remove = SKAction.removeFromParent()

        feedbackLabel.run(SKAction.sequence([group, remove]))
    }
}

// MARK: - IAPManagerDelegate

extension StoreScene: IAPManagerDelegate {
    func purchaseSucceeded(productId: String, diamonds: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoading()
            self?.gameManager.purchaseDiamonds(count: diamonds)
            self?.updateUI()
            self?.showFeedback(message: "Purchased \(diamonds) 💎!")
        }
    }

    func purchaseFailed(error: String) {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoading()
            self?.showFeedback(message: error)
        }
    }

    func purchaseCancelled() {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoading()
        }
    }
}
