import SwiftUI

struct EggView: View {
    let type: EggType
    var isDragging: Bool = false

    var body: some View {
        ZStack {
            // Egg shape
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            type.swiftUIColor,
                            type.swiftUIColor.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    // Shine highlight
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .scaleEffect(x: 0.6, y: 0.4)
                        .offset(x: -8, y: -12)
                }
                .overlay {
                    // Border
                    Ellipse()
                        .stroke(type.swiftUIColor.opacity(0.6), lineWidth: 2)
                }

            // Golden sparkle for golden eggs
            if type == .golden {
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .offset(x: 15, y: -20)
            }
        }
        .shadow(
            color: .black.opacity(isDragging ? 0.3 : 0.15),
            radius: isDragging ? 12 : 5,
            y: isDragging ? 8 : 3
        )
        .scaleEffect(isDragging ? 1.2 : 1.0)
        .animation(.spring(duration: 0.2), value: isDragging)
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(EggType.allCases) { type in
            VStack {
                EggView(type: type)
                    .frame(width: 50, height: 65)
                Text(type.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color(red: 0.95, green: 0.92, blue: 0.85))
}
