import SpriteKit

class SlimeEnemy: SKNode {

    // MARK: - Properties

    var maxHealth: Int = 50
    var currentHealth: Int = 50
    var moveSpeed: CGFloat = 50
    var contactDamage: Int = 20

    private(set) var isAlive: Bool = true
    private var movingRight: Bool = true
    private var patrolRange: CGFloat = 150
    private var startX: CGFloat = 0

    // Visual components
    private var bodyNode: SKShapeNode!
    private var leftEyeNode: SKShapeNode!
    private var rightEyeNode: SKShapeNode!

    // MARK: - Initialization

    override init() {
        super.init()
        setupVisuals()
        setupPhysics()
        name = "slimeEnemy"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupVisuals() {
        // Slime body (blob shape)
        let bodyPath = createSlimePath(width: 40, height: 30)
        bodyNode = SKShapeNode(path: bodyPath)
        bodyNode.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.35)
        bodyNode.strokeColor = SKColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 0.5)
        bodyNode.lineWidth = 1.5
        bodyNode.glowWidth = 2.0
        bodyNode.position = CGPoint(x: 0, y: 15)
        addChild(bodyNode)

        // Glass inner highlight (refraction)
        let slimeHighlight = SKShapeNode(circleOfRadius: 8)
        slimeHighlight.fillColor = SKColor(white: 1.0, alpha: 0.3)
        slimeHighlight.strokeColor = .clear
        slimeHighlight.position = CGPoint(x: -5, y: 24)
        addChild(slimeHighlight)

        // Darker bottom shadow for gel pooling effect
        let bottomShadow = SKShapeNode(ellipseOf: CGSize(width: 30, height: 8))
        bottomShadow.fillColor = SKColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 0.25)
        bottomShadow.strokeColor = .clear
        bottomShadow.position = CGPoint(x: 0, y: 2)
        addChild(bottomShadow)

        // Eyes
        leftEyeNode = SKShapeNode(circleOfRadius: 4)
        leftEyeNode.fillColor = .white
        leftEyeNode.strokeColor = .clear
        leftEyeNode.position = CGPoint(x: -8, y: 20)
        addChild(leftEyeNode)

        let leftPupil = SKShapeNode(circleOfRadius: 2)
        leftPupil.fillColor = .black
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 1, y: -1)
        leftEyeNode.addChild(leftPupil)

        rightEyeNode = SKShapeNode(circleOfRadius: 4)
        rightEyeNode.fillColor = .white
        rightEyeNode.strokeColor = .clear
        rightEyeNode.position = CGPoint(x: 8, y: 20)
        addChild(rightEyeNode)

        let rightPupil = SKShapeNode(circleOfRadius: 2)
        rightPupil.fillColor = .black
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 1, y: -1)
        rightEyeNode.addChild(rightPupil)

        // Start idle animation
        startIdleAnimation()
    }

    private func createSlimePath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()

        // Bottom flat
        path.move(to: CGPoint(x: -width / 2, y: -height / 2))
        path.addLine(to: CGPoint(x: width / 2, y: -height / 2))

        // Right side curve
        path.addCurve(
            to: CGPoint(x: width / 4, y: height / 2),
            control1: CGPoint(x: width / 2 + 5, y: 0),
            control2: CGPoint(x: width / 2, y: height / 2)
        )

        // Top curve (wobbly)
        path.addCurve(
            to: CGPoint(x: -width / 4, y: height / 2),
            control1: CGPoint(x: 0, y: height / 2 + 5),
            control2: CGPoint(x: -width / 4, y: height / 2)
        )

        // Left side curve
        path.addCurve(
            to: CGPoint(x: -width / 2, y: -height / 2),
            control1: CGPoint(x: -width / 2, y: height / 2),
            control2: CGPoint(x: -width / 2 - 5, y: 0)
        )

        path.closeSubpath()
        return path
    }

    private func setupPhysics() {
        let bodySize = CGSize(width: 36, height: 25)
        physicsBody = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: 0, y: 15))
        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerAttack | PhysicsCategory.wall
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.wall | PhysicsCategory.platform
        physicsBody?.allowsRotation = false
        physicsBody?.restitution = 0
        physicsBody?.friction = 0.5
    }

    // MARK: - Behavior

    func startPatrolling() {
        startX = position.x
    }

    func update(deltaTime: TimeInterval) {
        guard isAlive else { return }

        // Patrol behavior
        if movingRight {
            physicsBody?.velocity.dx = moveSpeed
            xScale = 1
        } else {
            physicsBody?.velocity.dx = -moveSpeed
            xScale = -1
        }

        // Check patrol bounds
        if position.x > startX + patrolRange {
            movingRight = false
        } else if position.x < startX - patrolRange {
            movingRight = true
        }
    }

    func reverseDirection() {
        movingRight = !movingRight
    }

    // MARK: - Damage

    func takeDamage(_ amount: Int) {
        guard isAlive else { return }

        currentHealth -= amount

        // Flash white on hit
        let flashWhite = SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05)
        let flashBack = SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        bodyNode.run(SKAction.sequence([flashWhite, flashBack]))

        // Knockback
        let knockbackDir: CGFloat = movingRight ? -1 : 1
        physicsBody?.applyImpulse(CGVector(dx: knockbackDir * 50, dy: 100))

        if currentHealth <= 0 {
            die()
        }
    }

    private func die() {
        isAlive = false
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none

        // Death animation
        let flatten = SKAction.scaleY(to: 0.2, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        run(SKAction.sequence([flatten, fadeOut, remove]))
    }

    // MARK: - Animations

    private func startIdleAnimation() {
        // Squish and stretch animation
        let squish = SKAction.scaleX(to: 1.1, duration: 0.5)
        let stretch = SKAction.scaleX(to: 0.9, duration: 0.5)
        let squishY = SKAction.scaleY(to: 0.9, duration: 0.5)
        let stretchY = SKAction.scaleY(to: 1.1, duration: 0.5)

        let squishGroup = SKAction.group([squish, squishY])
        let stretchGroup = SKAction.group([stretch, stretchY])
        let cycle = SKAction.sequence([squishGroup, stretchGroup])

        bodyNode.run(SKAction.repeatForever(cycle), withKey: "idle")
    }
}
