import SpriteKit

@MainActor
protocol EggBasketDelegate: AnyObject {
    func eggBasket(_ basket: EggBasket, didStartDragging egg: Egg)
    func eggBasket(_ basket: EggBasket, didStopDragging egg: Egg, at position: CGPoint)
}

class EggBasket: SKNode {
    weak var delegate: EggBasketDelegate?

    private var eggSlots: [EggType: EggSlot] = [:]
    private var activeEgg: Egg?
    private let slotSpacing: CGFloat = 80

    private struct EggSlot {
        let position: CGPoint
        var count: Int
        var countLabel: SKLabelNode
        var eggs: [Egg]
    }

    override init() {
        super.init()
        setupSlots()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSlots() {
        let types = EggType.allCases
        let totalWidth = CGFloat(types.count - 1) * slotSpacing
        let startX = -totalWidth / 2

        for (index, eggType) in types.enumerated() {
            let slotX = startX + CGFloat(index) * slotSpacing
            let slotPosition = CGPoint(x: slotX, y: 0)

            let background = SKShapeNode(rectOf: CGSize(width: 60, height: 70), cornerRadius: 8)
            background.fillColor = SKColor(white: 0.9, alpha: 0.5)
            background.strokeColor = SKColor.gray
            background.lineWidth = 2
            background.position = slotPosition
            addChild(background)

            let countLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            countLabel.fontSize = 14
            countLabel.fontColor = .black
            countLabel.position = CGPoint(x: slotX, y: -40)
            countLabel.verticalAlignmentMode = .center
            countLabel.text = "0"
            addChild(countLabel)

            eggSlots[eggType] = EggSlot(
                position: slotPosition,
                count: 0,
                countLabel: countLabel,
                eggs: []
            )
        }
    }

    func updateEggCounts(from gameManager: GameManager) {
        for eggType in EggType.allCases {
            let count = gameManager.eggCount(for: eggType)
            updateSlot(for: eggType, count: count)
        }
    }

    private func updateSlot(for type: EggType, count: Int) {
        guard var slot = eggSlots[type] else { return }

        slot.count = count
        slot.countLabel.text = "\(count)"

        for egg in slot.eggs {
            egg.removeFromParent()
        }
        slot.eggs.removeAll()

        if count > 0 {
            let egg = Egg(type: type)
            egg.setOriginalPosition(slot.position)
            addChild(egg)
            slot.eggs.append(egg)
        }

        eggSlots[type] = slot
    }

    func eggAt(point: CGPoint) -> Egg? {
        let localPoint = convert(point, from: parent!)
        for (_, slot) in eggSlots {
            for egg in slot.eggs {
                // Use distance-based hit detection for reliability
                let distance = hypot(localPoint.x - egg.position.x, localPoint.y - egg.position.y)
                if distance <= 40 { // Hit radius slightly larger than egg size
                    return egg
                }
            }
        }
        return nil
    }

    func startDraggingEgg(_ egg: Egg) {
        guard eggSlots[egg.eggType]?.count ?? 0 > 0 else { return }

        activeEgg = egg
        egg.startDragging()
        delegate?.eggBasket(self, didStartDragging: egg)
    }

    func updateDragPosition(_ position: CGPoint) {
        activeEgg?.position = convert(position, from: parent!)
    }

    func stopDragging(at position: CGPoint) {
        guard let egg = activeEgg else { return }

        delegate?.eggBasket(self, didStopDragging: egg, at: position)
        activeEgg = nil
    }

    func snapEggBack(_ egg: Egg) {
        egg.stopDragging(snapBack: true)
    }

    func consumeEgg(_ egg: Egg, completion: @escaping () -> Void) {
        egg.stopDragging(snapBack: false)
        egg.consumeAnimation { [weak self] in
            self?.eggSlots[egg.eggType]?.eggs.removeAll { $0 === egg }
            completion()
        }
    }

    var activeEggType: EggType? {
        activeEgg?.eggType
    }
}
