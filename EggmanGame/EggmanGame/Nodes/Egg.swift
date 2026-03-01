import SpriteKit

class Egg: SKNode {
    let eggType: EggType
    private let eggShape: SKShapeNode
    private var originalPosition: CGPoint = .zero
    private(set) var isDragging: Bool = false

    static let size = CGSize(width: 40, height: 50)

    init(type: EggType) {
        self.eggType = type

        let path = Egg.createEggPath(size: Egg.size)
        eggShape = SKShapeNode(path: path)
        eggShape.fillColor = type.color
        eggShape.strokeColor = SKColor.darkGray
        eggShape.lineWidth = 2

        super.init()

        addChild(eggShape)

        if type == .spotted, let spotColor = type.spotColor {
            addSpots(color: spotColor)
        }

        isUserInteractionEnabled = false
        name = "egg_\(type.rawValue)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func createEggPath(size: CGSize) -> CGPath {
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
            CGPoint(x: -8, y: 10),
            CGPoint(x: 8, y: 5),
            CGPoint(x: -5, y: -8),
            CGPoint(x: 10, y: -5),
            CGPoint(x: 0, y: 15)
        ]

        for position in spotPositions {
            let spot = SKShapeNode(circleOfRadius: 4)
            spot.fillColor = color
            spot.strokeColor = .clear
            spot.position = position
            addChild(spot)
        }
    }

    func setOriginalPosition(_ position: CGPoint) {
        self.originalPosition = position
        self.position = position
    }

    func startDragging() {
        isDragging = true
        zPosition = 100
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        run(scaleUp)
    }

    func stopDragging(snapBack: Bool) {
        isDragging = false
        zPosition = 0

        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)

        if snapBack {
            let moveBack = SKAction.move(to: originalPosition, duration: 0.2)
            moveBack.timingMode = .easeOut
            run(SKAction.group([scaleDown, moveBack]))
        } else {
            run(scaleDown)
        }
    }

    func consumeAnimation(completion: @escaping () -> Void) {
        let shrink = SKAction.scale(to: 0, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let group = SKAction.group([shrink, fadeOut])

        run(group) {
            self.removeFromParent()
            completion()
        }
    }
}
