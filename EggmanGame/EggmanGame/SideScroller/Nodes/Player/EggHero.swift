import SpriteKit

enum EggHeroState {
    case idle
    case walking
    case jumping
    case falling
    case attacking
    case hurt
}

class EggHero: SKNode {

    // MARK: - Properties

    var maxHealth: Int = 100
    var currentHealth: Int = 100
    var moveSpeed: CGFloat = 200
    var jumpForce: CGFloat = 500
    var attackPower: Int = 25
    var attackCooldown: TimeInterval = 0.3

    private(set) var isGrounded: Bool = false
    private(set) var facingDirection: CGFloat = 1 // 1 = right, -1 = left
    private(set) var currentState: EggHeroState = .idle
    private(set) var isInvulnerable: Bool = false

    private var lastAttackTime: TimeInterval = 0
    private var invulnerabilityDuration: TimeInterval = 1.0

    // Visual components
    private var bodyNode: SKShapeNode!
    private var leftLegNode: SKShapeNode!
    private var rightLegNode: SKShapeNode!
    private var faceNode: SKNode!
    private var leftEyeNode: SKShapeNode!
    private var rightEyeNode: SKShapeNode!
    private var mouthNode: SKShapeNode!

    // Attack hitbox (created on attack)
    private var attackHitbox: SKNode?

    // MARK: - Initialization

    override init() {
        super.init()
        setupVisuals()
        setupPhysics()
        name = "eggHero"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupVisuals() {
        // Egg body (oval shape)
        let bodyPath = createEggPath(width: 40, height: 50)
        bodyNode = SKShapeNode(path: bodyPath)
        bodyNode.fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.5)
        bodyNode.strokeColor = SKColor(white: 1.0, alpha: 0.5)
        bodyNode.lineWidth = 1.5
        bodyNode.glowWidth = 1.0
        bodyNode.position = CGPoint(x: 0, y: 25)
        addChild(bodyNode)

        // Glass specular highlight
        let heroHighlight = SKShapeNode(ellipseOf: CGSize(width: 18, height: 14))
        heroHighlight.fillColor = SKColor(white: 1.0, alpha: 0.3)
        heroHighlight.strokeColor = .clear
        heroHighlight.position = CGPoint(x: -6, y: 38)
        addChild(heroHighlight)

        // Face container
        faceNode = SKNode()
        faceNode.position = CGPoint(x: 0, y: 35)
        addChild(faceNode)

        // Eyes
        leftEyeNode = SKShapeNode(circleOfRadius: 5)
        leftEyeNode.fillColor = .black
        leftEyeNode.strokeColor = .clear
        leftEyeNode.position = CGPoint(x: -8, y: 5)
        faceNode.addChild(leftEyeNode)

        rightEyeNode = SKShapeNode(circleOfRadius: 5)
        rightEyeNode.fillColor = .black
        rightEyeNode.strokeColor = .clear
        rightEyeNode.position = CGPoint(x: 8, y: 5)
        faceNode.addChild(rightEyeNode)

        // Mouth (simple smile)
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -6, y: -5))
        mouthPath.addQuadCurve(to: CGPoint(x: 6, y: -5), control: CGPoint(x: 0, y: -12))
        mouthNode = SKShapeNode(path: mouthPath)
        mouthNode.strokeColor = .black
        mouthNode.lineWidth = 2
        mouthNode.fillColor = .clear
        faceNode.addChild(mouthNode)

        // Legs
        leftLegNode = createLeg()
        leftLegNode.position = CGPoint(x: -10, y: 0)
        addChild(leftLegNode)

        rightLegNode = createLeg()
        rightLegNode.position = CGPoint(x: 10, y: 0)
        addChild(rightLegNode)
    }

    private func createEggPath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()

        // Start at bottom center
        path.move(to: CGPoint(x: 0, y: -height / 2))

        // Right side curve
        path.addCurve(
            to: CGPoint(x: width / 2, y: 0),
            control1: CGPoint(x: width / 3, y: -height / 2),
            control2: CGPoint(x: width / 2, y: -height / 4)
        )

        // Top curve (narrower)
        path.addCurve(
            to: CGPoint(x: 0, y: height / 2),
            control1: CGPoint(x: width / 2, y: height / 3),
            control2: CGPoint(x: width / 4, y: height / 2)
        )

        // Left side top
        path.addCurve(
            to: CGPoint(x: -width / 2, y: 0),
            control1: CGPoint(x: -width / 4, y: height / 2),
            control2: CGPoint(x: -width / 2, y: height / 3)
        )

        // Left side bottom
        path.addCurve(
            to: CGPoint(x: 0, y: -height / 2),
            control1: CGPoint(x: -width / 2, y: -height / 4),
            control2: CGPoint(x: -width / 3, y: -height / 2)
        )

        path.closeSubpath()
        return path
    }

    private func createLeg() -> SKShapeNode {
        let leg = SKShapeNode(rectOf: CGSize(width: 8, height: 15), cornerRadius: 2)
        leg.fillColor = SKColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1.0)
        leg.strokeColor = SKColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 1.0)
        leg.lineWidth = 1
        return leg
    }

    private func setupPhysics() {
        let bodySize = CGSize(width: 36, height: 50)
        physicsBody = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: 0, y: 25))
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.enemy | PhysicsCategory.collectible | PhysicsCategory.platform
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.wall | PhysicsCategory.platform
        physicsBody?.allowsRotation = false
        physicsBody?.restitution = 0
        physicsBody?.friction = 0.2
        physicsBody?.linearDamping = 0.1
    }

    // MARK: - Movement

    func move(direction: CGFloat) {
        guard currentState != .hurt && currentState != .attacking else { return }

        if direction != 0 {
            facingDirection = direction > 0 ? 1 : -1
            updateFacingDirection()

            if isGrounded {
                setState(.walking)
                animateWalk()
            }
        } else if isGrounded && currentState == .walking {
            setState(.idle)
            stopWalkAnimation()
        }

        physicsBody?.velocity.dx = direction * moveSpeed
    }

    func jump() {
        guard isGrounded && currentState != .hurt && currentState != .attacking else { return }

        isGrounded = false
        setState(.jumping)
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpForce))
        stopWalkAnimation()

        // Jump squash and stretch
        let squash = SKAction.scaleY(to: 1.2, duration: 0.1)
        let stretch = SKAction.scaleY(to: 1.0, duration: 0.2)
        bodyNode.run(SKAction.sequence([squash, stretch]))
    }

    func attack(currentTime: TimeInterval) {
        guard currentTime - lastAttackTime >= attackCooldown else { return }
        guard currentState != .hurt else { return }

        lastAttackTime = currentTime
        setState(.attacking)

        // Create attack hitbox
        let hitboxSize = CGSize(width: 40, height: 40)
        let hitbox = SKNode()
        hitbox.name = "playerAttack"
        hitbox.position = CGPoint(x: facingDirection * 35, y: 25)

        let hitboxBody = SKPhysicsBody(rectangleOf: hitboxSize)
        hitboxBody.categoryBitMask = PhysicsCategory.playerAttack
        hitboxBody.contactTestBitMask = PhysicsCategory.enemy
        hitboxBody.collisionBitMask = PhysicsCategory.none
        hitboxBody.isDynamic = false
        hitbox.physicsBody = hitboxBody

        addChild(hitbox)
        attackHitbox = hitbox

        // Visual attack animation
        let attackAnim = SKAction.sequence([
            SKAction.moveBy(x: facingDirection * 10, y: 0, duration: 0.1),
            SKAction.moveBy(x: -facingDirection * 10, y: 0, duration: 0.1)
        ])
        bodyNode.run(attackAnim)

        // Attack expression
        showAttackFace()

        // Remove hitbox after short duration
        let removeHitbox = SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                self?.attackHitbox?.removeFromParent()
                self?.attackHitbox = nil
                if self?.isGrounded == true {
                    self?.setState(.idle)
                } else {
                    self?.setState(.falling)
                }
                self?.showNormalFace()
            }
        ])
        run(removeHitbox)
    }

    // MARK: - Damage & Health

    func takeDamage(_ amount: Int) {
        guard !isInvulnerable else { return }

        currentHealth = max(0, currentHealth - amount)
        setState(.hurt)
        isInvulnerable = true

        // Knockback
        let knockbackDirection: CGFloat = facingDirection * -1
        physicsBody?.velocity = CGVector(dx: knockbackDirection * 200, dy: 200)

        // Hurt animation - flash red
        let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1)
        let flashBack = SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        let flashSequence = SKAction.sequence([flashRed, flashBack])
        let flashRepeat = SKAction.repeat(flashSequence, count: 5)
        bodyNode.run(flashRepeat)

        // Show hurt face
        showHurtFace()

        // End invulnerability
        let endInvulnerability = SKAction.sequence([
            SKAction.wait(forDuration: invulnerabilityDuration),
            SKAction.run { [weak self] in
                self?.isInvulnerable = false
                if self?.isGrounded == true {
                    self?.setState(.idle)
                }
                self?.showNormalFace()
            }
        ])
        run(endInvulnerability, withKey: "invulnerability")
    }

    func heal(_ amount: Int) {
        currentHealth = min(maxHealth, currentHealth + amount)
    }

    var isDead: Bool {
        currentHealth <= 0
    }

    // MARK: - Ground Detection

    func setGrounded(_ grounded: Bool) {
        let wasInAir = !isGrounded
        isGrounded = grounded

        if grounded && wasInAir {
            // Landing
            if currentState == .falling || currentState == .jumping {
                setState(.idle)

                // Landing squash animation
                let squash = SKAction.scaleY(to: 0.8, duration: 0.05)
                let stretch = SKAction.scaleY(to: 1.0, duration: 0.1)
                bodyNode.run(SKAction.sequence([squash, stretch]))
            }
        } else if !grounded && wasInAir == false {
            // Just left ground
            if currentState != .jumping && currentState != .attacking && currentState != .hurt {
                setState(.falling)
            }
        }
    }

    // MARK: - State Management

    private func setState(_ state: EggHeroState) {
        currentState = state
    }

    private func updateFacingDirection() {
        xScale = facingDirection
    }

    // MARK: - Animations

    private func animateWalk() {
        guard leftLegNode.action(forKey: "walk") == nil else { return }

        let legSwingUp = SKAction.rotate(toAngle: 0.3, duration: 0.15)
        let legSwingDown = SKAction.rotate(toAngle: -0.3, duration: 0.15)
        let walkCycle = SKAction.sequence([legSwingUp, legSwingDown])
        let repeatWalk = SKAction.repeatForever(walkCycle)

        leftLegNode.run(repeatWalk, withKey: "walk")

        // Right leg is offset
        let rightWalkCycle = SKAction.sequence([legSwingDown, legSwingUp])
        let rightRepeatWalk = SKAction.repeatForever(rightWalkCycle)
        rightLegNode.run(rightRepeatWalk, withKey: "walk")

        // Subtle body bob
        let bobUp = SKAction.moveBy(x: 0, y: 2, duration: 0.15)
        let bobDown = SKAction.moveBy(x: 0, y: -2, duration: 0.15)
        let bobCycle = SKAction.sequence([bobUp, bobDown])
        let repeatBob = SKAction.repeatForever(bobCycle)
        bodyNode.run(repeatBob, withKey: "bob")
    }

    private func stopWalkAnimation() {
        leftLegNode.removeAction(forKey: "walk")
        rightLegNode.removeAction(forKey: "walk")
        bodyNode.removeAction(forKey: "bob")

        leftLegNode.zRotation = 0
        rightLegNode.zRotation = 0
        bodyNode.position.y = 25
    }

    // MARK: - Face Expressions

    private func showNormalFace() {
        // Normal eyes
        leftEyeNode.setScale(1.0)
        rightEyeNode.setScale(1.0)

        // Normal smile
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -6, y: -5))
        mouthPath.addQuadCurve(to: CGPoint(x: 6, y: -5), control: CGPoint(x: 0, y: -12))
        mouthNode.path = mouthPath
    }

    private func showAttackFace() {
        // Angry/determined eyes
        leftEyeNode.setScale(0.8)
        rightEyeNode.setScale(0.8)

        // Open mouth (battle cry)
        let mouthPath = CGMutablePath()
        mouthPath.addEllipse(in: CGRect(x: -5, y: -10, width: 10, height: 8))
        mouthNode.path = mouthPath
        mouthNode.fillColor = SKColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 1.0)
    }

    private func showHurtFace() {
        // X eyes (hurt)
        leftEyeNode.setScale(1.2)
        rightEyeNode.setScale(1.2)

        // Frown
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -6, y: -8))
        mouthPath.addQuadCurve(to: CGPoint(x: 6, y: -8), control: CGPoint(x: 0, y: -2))
        mouthNode.path = mouthPath
        mouthNode.fillColor = .clear
    }
}
