import SpriteKit

enum EggManState {
    case idle
    case mouthOpen
    case eating
    case sick
}

class EggMan: SKNode {
    private(set) var currentState: EggManState = .idle

    private let bodyNode: SKShapeNode
    private let faceNode: SKNode
    private let leftEye: SKShapeNode
    private let rightEye: SKShapeNode
    private let mouth: SKShapeNode
    private var mouthHitbox: SKShapeNode

    private let bodySize = CGSize(width: 100, height: 170)
    private let mouthRadius: CGFloat = 25

    var mouthWorldPosition: CGPoint {
        let localMouthPos = CGPoint(x: 0, y: -20)
        return convert(localMouthPos, to: parent!)
    }

    var mouthHitboxRadius: CGFloat {
        mouthRadius + 20
    }

    override init() {
        bodyNode = SKShapeNode(ellipseOf: bodySize)
        bodyNode.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.8, alpha: 1.0)
        bodyNode.strokeColor = SKColor.darkGray
        bodyNode.lineWidth = 3

        faceNode = SKNode()
        faceNode.position = CGPoint(x: 0, y: 20)

        leftEye = SKShapeNode(circleOfRadius: 12)
        leftEye.fillColor = .white
        leftEye.strokeColor = .black
        leftEye.lineWidth = 2
        leftEye.position = CGPoint(x: -25, y: 30)

        let leftPupil = SKShapeNode(circleOfRadius: 5)
        leftPupil.fillColor = .black
        leftPupil.strokeColor = .clear
        leftEye.addChild(leftPupil)

        rightEye = SKShapeNode(circleOfRadius: 12)
        rightEye.fillColor = .white
        rightEye.strokeColor = .black
        rightEye.lineWidth = 2
        rightEye.position = CGPoint(x: 25, y: 30)

        let rightPupil = SKShapeNode(circleOfRadius: 5)
        rightPupil.fillColor = .black
        rightPupil.strokeColor = .clear
        rightEye.addChild(rightPupil)

        mouth = SKShapeNode()
        mouth.position = CGPoint(x: 0, y: -20)
        mouth.strokeColor = .black
        mouth.lineWidth = 3

        mouthHitbox = SKShapeNode(circleOfRadius: mouthRadius + 20)
        mouthHitbox.fillColor = .clear
        mouthHitbox.strokeColor = .clear
        mouthHitbox.position = CGPoint(x: 0, y: -20)

        super.init()

        addChild(bodyNode)
        addChild(faceNode)
        faceNode.addChild(leftEye)
        faceNode.addChild(rightEye)
        faceNode.addChild(mouth)
        addChild(mouthHitbox)

        setState(.mouthOpen)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setState(_ state: EggManState) {
        currentState = state
        updateAppearance()
    }

    private func updateAppearance() {
        mouth.path = nil

        switch currentState {
        case .idle:
            bodyNode.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.8, alpha: 1.0)
            drawIdleMouth()
            setEyesNormal()

        case .mouthOpen:
            bodyNode.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.8, alpha: 1.0)
            drawOpenMouth()
            setEyesExcited()

        case .eating:
            bodyNode.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 1.0)
            drawHappyMouth()
            setEyesHappy()

        case .sick:
            bodyNode.fillColor = SKColor(red: 0.7, green: 0.85, blue: 0.7, alpha: 1.0)
            drawSickMouth()
            setEyesSick()
        }
    }

    private func drawIdleMouth() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -15, y: 0))
        path.addLine(to: CGPoint(x: 15, y: 0))
        mouth.path = path
        mouth.fillColor = .clear
    }

    private func drawOpenMouth() {
        mouth.path = CGPath(ellipseIn: CGRect(x: -mouthRadius, y: -mouthRadius, width: mouthRadius * 2, height: mouthRadius * 2), transform: nil)
        mouth.fillColor = SKColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 1.0)
    }

    private func drawHappyMouth() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -20, y: 5))
        path.addQuadCurve(to: CGPoint(x: 20, y: 5), control: CGPoint(x: 0, y: -20))
        mouth.path = path
        mouth.fillColor = .clear
    }

    private func drawSickMouth() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -15, y: -5))
        path.addQuadCurve(to: CGPoint(x: 15, y: -5), control: CGPoint(x: 0, y: 10))
        mouth.path = path
        mouth.fillColor = .clear
    }

    private func setEyesNormal() {
        leftEye.children.first?.position = .zero
        rightEye.children.first?.position = .zero
    }

    private func setEyesExcited() {
        leftEye.children.first?.position = CGPoint(x: 0, y: -3)
        rightEye.children.first?.position = CGPoint(x: 0, y: -3)
    }

    private func setEyesHappy() {
        leftEye.children.first?.position = .zero
        rightEye.children.first?.position = .zero
    }

    private func setEyesSick() {
        leftEye.children.first?.position = CGPoint(x: 2, y: 2)
        rightEye.children.first?.position = CGPoint(x: -2, y: 2)
    }

    func isPointInMouth(_ point: CGPoint) -> Bool {
        let localPoint = convert(point, from: parent!)
        let mouthCenter = CGPoint(x: 0, y: -20)
        let distance = hypot(localPoint.x - mouthCenter.x, localPoint.y - mouthCenter.y)
        return distance <= mouthHitboxRadius
    }

    func playEatingAnimation(completion: @escaping () -> Void) {
        setState(.eating)

        let chew1 = SKAction.scaleY(to: 0.95, duration: 0.1)
        let chew2 = SKAction.scaleY(to: 1.0, duration: 0.1)
        let chewSequence = SKAction.sequence([chew1, chew2])
        let chewRepeat = SKAction.repeat(chewSequence, count: 3)

        let particleEmitter = createEatingParticles()
        particleEmitter.position = CGPoint(x: 0, y: 0)
        addChild(particleEmitter)

        run(chewRepeat) { [weak self] in
            particleEmitter.removeFromParent()
            self?.setState(.idle)
            completion()
        }
    }

    private func createEatingParticles() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 20
        emitter.numParticlesToEmit = 15
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 50
        emitter.particleSpeedRange = 20
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.1
        emitter.particleColor = .yellow
        emitter.particleColorBlendFactor = 1.0

        let texture = SKShapeNode(circleOfRadius: 5)
        texture.fillColor = .yellow
        texture.strokeColor = .clear
        let view = SKView()
        if let textureFromShape = view.texture(from: texture) {
            emitter.particleTexture = textureFromShape
        }

        return emitter
    }

    func playSickAnimation() {
        setState(.sick)

        let wobble1 = SKAction.rotate(byAngle: 0.1, duration: 0.1)
        let wobble2 = SKAction.rotate(byAngle: -0.2, duration: 0.2)
        let wobble3 = SKAction.rotate(byAngle: 0.1, duration: 0.1)
        let wobbleSequence = SKAction.sequence([wobble1, wobble2, wobble3])
        run(wobbleSequence)
    }

    func playHealAnimation(completion: @escaping () -> Void) {
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ])
        let flashRepeat = SKAction.repeat(flash, count: 3)

        bodyNode.run(flashRepeat) { [weak self] in
            self?.setState(.idle)
            completion()
        }
    }
}
