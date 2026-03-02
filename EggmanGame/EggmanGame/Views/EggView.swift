import SwiftUI

struct EggView: View {
    let type: EggType
    var isDragging: Bool = false

    var body: some View {
        ZStack {
            // Egg shape — translucent glass body
            Ellipse()
                .fill(
                    type.swiftUIColor.opacity(0.45)
                )
                .overlay {
                    // Glass edge refraction stroke
                    Ellipse()
                        .stroke(type.swiftUIColor.opacity(0.4), lineWidth: 1.5)
                }
                .overlay {
                    // Inner shadow for depth
                    Ellipse()
                        .stroke(.black.opacity(0.08), lineWidth: 2)
                        .padding(3)
                }
                .overlay {
                    // Primary specular highlight
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.7), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .scaleEffect(x: 0.55, y: 0.4)
                        .offset(x: -8, y: -12)
                }
                .overlay {
                    // Secondary highlight spot for glass depth
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.35), .clear],
                                center: UnitPoint(x: 0.7, y: 0.75),
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .scaleEffect(x: 0.25, y: 0.2)
                        .offset(x: 6, y: 10)
                }

            // Golden glow + sparkle
            if type == .golden {
                Ellipse()
                    .fill(Color.yellow.opacity(0.15))
                    .blur(radius: 8)

                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .offset(x: 15, y: -20)
            }
        }
        .shadow(
            color: type.swiftUIColor.opacity(isDragging ? 0.4 : 0.2),
            radius: isDragging ? 12 : 6,
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
