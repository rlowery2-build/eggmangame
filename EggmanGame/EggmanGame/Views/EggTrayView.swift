import SwiftUI

struct EggTrayView: View {
    var gameState: GameState
    var onDragStarted: (EggType) -> Void
    var onDragChanged: (CGPoint) -> Void
    var onDragEnded: (EggType, CGPoint) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ForEach(EggType.allCases) { type in
                EggSlotView(
                    type: type,
                    count: gameState.count(for: type),
                    onDragStarted: onDragStarted,
                    onDragChanged: onDragChanged,
                    onDragEnded: onDragEnded
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }
}

struct EggSlotView: View {
    let type: EggType
    let count: Int
    var onDragStarted: (EggType) -> Void
    var onDragChanged: (CGPoint) -> Void
    var onDragEnded: (EggType, CGPoint) -> Void

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero

    var isAvailable: Bool { count > 0 }

    var body: some View {
        VStack(spacing: 8) {
            // Egg with drag gesture
            ZStack {
                // Slot background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 70, height: 85)

                // Egg (hidden when dragging)
                if isAvailable && !isDragging {
                    EggView(type: type)
                        .frame(width: 50, height: 65)
                }

                // Empty state
                if !isAvailable {
                    Image(systemName: "oval")
                        .font(.largeTitle)
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        guard isAvailable else { return }

                        if !isDragging {
                            isDragging = true
                            onDragStarted(type)
                        }
                        onDragChanged(value.location)
                    }
                    .onEnded { value in
                        guard isAvailable else { return }
                        isDragging = false
                        onDragEnded(type, value.location)
                    }
            )

            // Count badge
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(isAvailable ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(isAvailable ? type.swiftUIColor.opacity(0.3) : Color.gray.opacity(0.2))
                }
        }
        .opacity(isAvailable ? 1.0 : 0.5)
    }
}

#Preview {
    ZStack {
        Color(red: 0.95, green: 0.92, blue: 0.85)
            .ignoresSafeArea()

        VStack {
            Spacer()
            EggTrayView(
                gameState: GameState(),
                onDragStarted: { _ in },
                onDragChanged: { _ in },
                onDragEnded: { _, _ in }
            )
            .padding(.bottom, 40)
        }
    }
}
