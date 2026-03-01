import SpriteKit

class CollectibleEgg: SKNode {

    // MARK: - Properties

    let eggType: EggType
    private(set) var isCollected: Bool = false

    private var eggShape: SKShapeNode!
    private var sparkleEmitter: SKEmitterNode?
    private var glowNode: SKShapeNode!

    static let size = CGSize(width: 30, height: 38)

    // MARK: - Initialization

    init(type: EggType) {
        self.eggType = type
        super.init()
        setupVisuals()
        setupPhysics()
        startAnimations()
        name = "collectibleEgg_\(type.rawValue)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupVisuals() {
        // Glow effect behind egg
        glowNode = SKShapeNode(circleOfRadius: 25)
        glowNode.fillColor = eggType.color.withAlphaComponent(0.3)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: CollectibleEgg.size.height / 2)
        glowNode.zPosition = -1
        addChild(glowNode)

        // Egg shape
        let path = createEggPath(size: CollectibleEgg.size)
        eggShape = SKShapeNode(path: path)
        eggShape.fillColor = eggType.color
        eggShape.strokeColor = SKColor.darkGray
        eggShape.lineWidth = 1.5
        eggShape.position = CGPoint(x: 0, y: CollectibleEgg.size.height / 2)
        addChild(eggShape)

        // Add spots for spotted eggs
        if eggType == .spotted, let spotColor = eggType.spotColor {
            addSpots(color: spotColor)
        }

        // Add shine highlight
        let shinePath = CGMutablePath()
        shinePath.addEllipse(in: CGRect(x: -8, y: 5, width: 6, height: 10))
        let shine = SKShapeNode(path: shinePath)
        shine.fillColor = SKColor.white.withAlphaComponent(0.4)
        shine.strokeColor = .clear
        eggShape.addChild(shine)
    }

    private func createEggPath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        let width = size.width
        let height = size.height

        path.move(to: CGPoint(x: 0, y: -height / 2))

        path.addCurve(
            to: CGPoint(x: width / 2, y: 0),
            control1: CGPoint(x: width / 3, y: -height / 2),
            control2: CGPoint(x: width / 2, y: -height / 4)
        )

        path.addCurve(
            to: CGPoint(x: 0, y: height / 2),
            control1: CGPoint(x: width / 2, y: height / 3),
            control2: CGPoint(x: width / 4, y: height / 2)
        )

        path.addCurve(
            to: CGPoint(x: -width / 2, y: 0),
            control1: CGPoint(x: -width / 4, y: height / 2),
            control2: CGPoint(x: -width / 2, y: height / 3)
        )

        path.addCurve(
            to: CGPoint(x: 0, y: -height / 2),
            control1: CGPoint(x: -width / 2, y: -height / 4),
            control2: CGPoint(x: -width / 3, y: -height / 2)
        )

        path.closeSubpath()
        return path
    }

    private func addSpots(color: SKColor) {
        let spotPositions: [CGPoint] = [
            CGPoint(x: -5, y: 8),
            CGPoint(x: 5, y: 3),
            CGPoint(x: -3, y: -5),
            CGPoint(x: 7, y: -3)
        ]

        for position in spotPositions {
            let spot = SKShapeNode(circleOfRadius: 3)
            spot.fillColor = color
            spot.strokeColor = .clear
            spot.position = position
            eggShape.addChild(spot)
        }
    }

    private func setupPhysics() {
        let bodySize = CGSize(width: CollectibleEgg.size.width, height: CollectibleEgg.size.height)
        physicsBody = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: 0, y: CollectibleEgg.size.height / 2))
        physicsBody?.categoryBitMask = PhysicsCategory.collectible
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.isDynamic = false
    }

    // MARK: - Animations

    private func startAnimations() {
        // Floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 8, duration: 1.0)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -8, duration: 1.0)
        floatDown.timingMode = .easeInEaseOut
        let floatCycle = SKAction.sequence([floatUp, floatDown])
        run(SKAction.repeatForever(floatCycle), withKey: "float")

        // Glow pulse
        let glowBright = SKAction.fadeAlpha(to: 0.6, duration: 0.8)
        let glowDim = SKAction.fadeAlpha(to: 0.2, duration: 0.8)
        let glowCycle = SKAction.sequence([glowBright, glowDim])
        glowNode.run(SKAction.repeatForever(glowCycle), withKey: "glow")

        // Subtle rotation
        let rotateLeft = SKAction.rotate(byAngle: 0.1, duration: 1.5)
        let rotateRight = SKAction.rotate(byAngle: -0.1, duration: 1.5)
        let rotateCycle = SKAction.sequence([rotateLeft, rotateRight])
        eggShape.run(SKAction.repeatForever(rotateCycle), withKey: "rotate")
    }

    // MARK: - Collection

    func collect(completion: @escaping () -> Void) {
        guard !isCollected else { return }
        isCollected = true

        // Stop ongoing animations
        removeAllActions()
        eggShape.removeAllActions()
        glowNode.removeAllActions()

        // Disable physics
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none

        // Collection animation
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.15)
        let scaleDown = SKAction.scale(to: 0, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)

        // Sparkle burst
        createSparkles()

        let collectGroup = SKAction.group([scaleDown, fadeOut])
        let sequence = SKAction.sequence([scaleUp, collectGroup, SKAction.removeFromParent()])

        run(sequence) {
            completion()
        }
    }

    private func createSparkles() {
        let sparkleCount = 8
        for i in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: 3)
            sparkle.fillColor = eggType.color
            sparkle.strokeColor = .white
            sparkle.lineWidth = 1
            sparkle.position = CGPoint(x: 0, y: CollectibleEgg.size.height / 2)
            sparkle.zPosition = 10
            addChild(sparkle)

            let angle = CGFloat(i) * (CGFloat.pi * 2) / CGFloat(sparkleCount)
            let distance: CGFloat = 40
            let targetX = cos(angle) * distance
            let targetY = sin(angle) * distance + CollectibleEgg.size.height / 2

            let moveOut = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.3)
            moveOut.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let scale = SKAction.scale(to: 0.3, duration: 0.3)
            let group = SKAction.group([moveOut, fadeOut, scale])

            sparkle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }
}
