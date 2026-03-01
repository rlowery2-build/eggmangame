import SpriteKit

class SideScrollerCamera: SKCameraNode {

    // MARK: - Properties

    private weak var target: SKNode?
    private var levelBounds: CGRect = .zero
    private var viewportSize: CGSize = .zero

    // Camera behavior settings
    var lerpSpeed: CGFloat = 0.1
    var deadZone: CGSize = CGSize(width: 50, height: 30)
    var lookAheadDistance: CGFloat = 50
    var verticalOffset: CGFloat = 50

    private var targetPosition: CGPoint = .zero

    // MARK: - Initialization

    override init() {
        super.init()
        name = "camera"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(target: SKNode, levelBounds: CGRect, viewportSize: CGSize) {
        self.target = target
        self.levelBounds = levelBounds
        self.viewportSize = viewportSize

        // Start at target position immediately
        position = calculateTargetPosition(for: target)
    }

    func updateViewportSize(_ size: CGSize) {
        self.viewportSize = size
    }

    func updateLevelBounds(_ bounds: CGRect) {
        self.levelBounds = bounds
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        guard let target = target else { return }

        let desiredPosition = calculateTargetPosition(for: target)

        // Apply dead zone
        let dx = desiredPosition.x - position.x
        let dy = desiredPosition.y - position.y

        var adjustedX = position.x
        var adjustedY = position.y

        if abs(dx) > deadZone.width / 2 {
            adjustedX = position.x + (dx - (dx > 0 ? deadZone.width / 2 : -deadZone.width / 2)) * lerpSpeed
        }

        if abs(dy) > deadZone.height / 2 {
            adjustedY = position.y + (dy - (dy > 0 ? deadZone.height / 2 : -deadZone.height / 2)) * lerpSpeed
        }

        // Clamp to level bounds
        let clampedPosition = clampToBounds(CGPoint(x: adjustedX, y: adjustedY))
        position = clampedPosition
    }

    // MARK: - Position Calculation

    private func calculateTargetPosition(for target: SKNode) -> CGPoint {
        var targetPos = target.position

        // Add vertical offset to see more above player
        targetPos.y += verticalOffset

        // Look ahead in movement direction
        if let player = target as? EggHero {
            targetPos.x += player.facingDirection * lookAheadDistance
        }

        return targetPos
    }

    private func clampToBounds(_ position: CGPoint) -> CGPoint {
        guard levelBounds != .zero && viewportSize != .zero else {
            return position
        }

        let halfWidth = viewportSize.width / 2
        let halfHeight = viewportSize.height / 2

        let minX = levelBounds.minX + halfWidth
        let maxX = levelBounds.maxX - halfWidth
        let minY = levelBounds.minY + halfHeight
        let maxY = levelBounds.maxY - halfHeight

        var clampedX = position.x
        var clampedY = position.y

        if maxX > minX {
            clampedX = max(minX, min(maxX, position.x))
        } else {
            // Level is smaller than viewport, center it
            clampedX = levelBounds.midX
        }

        if maxY > minY {
            clampedY = max(minY, min(maxY, position.y))
        } else {
            // Level is smaller than viewport, center it
            clampedY = levelBounds.midY
        }

        return CGPoint(x: clampedX, y: clampedY)
    }

    // MARK: - Effects

    func shake(intensity: CGFloat = 10, duration: TimeInterval = 0.3) {
        let numberOfShakes = Int(duration / 0.05)

        var actions: [SKAction] = []
        for _ in 0..<numberOfShakes {
            let moveX = CGFloat.random(in: -intensity...intensity)
            let moveY = CGFloat.random(in: -intensity...intensity)
            let move = SKAction.moveBy(x: moveX, y: moveY, duration: 0.025)
            let moveBack = SKAction.moveBy(x: -moveX, y: -moveY, duration: 0.025)
            actions.append(move)
            actions.append(moveBack)
        }

        run(SKAction.sequence(actions), withKey: "shake")
    }

    func flash(color: SKColor = .white, duration: TimeInterval = 0.1) {
        guard let scene = scene else { return }

        let flash = SKShapeNode(rectOf: scene.size)
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.alpha = 0
        flash.zPosition = 1000
        addChild(flash)

        let fadeIn = SKAction.fadeAlpha(to: 0.5, duration: duration / 2)
        let fadeOut = SKAction.fadeOut(withDuration: duration / 2)
        let remove = SKAction.removeFromParent()

        flash.run(SKAction.sequence([fadeIn, fadeOut, remove]))
    }
}
