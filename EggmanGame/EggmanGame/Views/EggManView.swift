import SwiftUI

struct EggManView: View {
    var isMouthOpen: Bool
    var isEating: Bool
    var onFrameChange: (CGRect) -> Void

    @State private var isWobbling = false
    @State private var danceRotation: Double = 0
    @State private var danceScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Body - egg shaped
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.85),
                                Color(red: 0.95, green: 0.88, blue: 0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Ellipse()
                            .stroke(Color(red: 0.85, green: 0.78, blue: 0.65), lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

                // Face - centered
                VStack(spacing: 12) {
                    // Eyes
                    HStack(spacing: 30) {
                        EyeView(isHappy: isEating)
                        EyeView(isHappy: isEating)
                    }

                    // Mouth - bigger and more oval
                    MouthView(isOpen: isMouthOpen, isSmiling: isEating)
                        .frame(width: 70, height: (isMouthOpen && !isEating) ? 55 : (isEating ? 30 : 20))
                }
            }
            .scaleEffect(isEating ? danceScale : (isMouthOpen ? 1.05 : 1.0))
            .rotationEffect(.degrees(isEating ? danceRotation : (isWobbling ? 2 : -2)))
            .animation(.spring(duration: 0.3), value: isMouthOpen)
            .onChange(of: isEating) { _, eating in
                if eating {
                    // Start dance animation
                    withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true)) {
                        danceRotation = 15
                        danceScale = 1.1
                    }
                } else {
                    // Reset dance
                    withAnimation(.spring(duration: 0.2)) {
                        danceRotation = 0
                        danceScale = 1.0
                    }
                }
            }
            .onAppear {
                // Gentle idle wobble
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isWobbling = true
                }

                // Report frame
                let frame = geometry.frame(in: .global)
                onFrameChange(frame)
            }
            .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                onFrameChange(newFrame)
            }
        }
    }
}

struct EyeView: View {
    var isHappy: Bool

    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(.white)
                .frame(width: 28, height: isHappy ? 20 : 32)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

            // Pupil - bigger size
            Circle()
                .fill(.black)
                .frame(width: 18, height: 18)
                .offset(y: isHappy ? -2 : 2)

            // Highlight
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .offset(x: -4, y: isHappy ? -5 : -2)
        }
    }
}

struct MouthView: View {
    var isOpen: Bool
    var isSmiling: Bool

    var body: some View {
        ZStack {
            if isSmiling {
                // Big happy smile when eating
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 10))
                    path.addQuadCurve(
                        to: CGPoint(x: 70, y: 10),
                        control: CGPoint(x: 35, y: 40)
                    )
                }
                .stroke(Color(red: 0.3, green: 0.15, blue: 0.1), lineWidth: 5)
                .frame(width: 70, height: 30)
            } else if isOpen {
                // Open mouth - big oval (hungry)
                Ellipse()
                    .fill(Color(red: 0.15, green: 0.02, blue: 0.02))
                    .overlay {
                        // Inner mouth depth
                        Ellipse()
                            .fill(Color(red: 0.3, green: 0.08, blue: 0.08))
                            .scaleEffect(0.7)
                            .offset(y: 8)
                    }
                    .overlay {
                        // Tongue hint
                        Ellipse()
                            .fill(Color(red: 0.6, green: 0.2, blue: 0.2))
                            .scaleEffect(x: 0.5, y: 0.3)
                            .offset(y: 15)
                    }
            } else {
                // Closed mouth - neutral line
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 10))
                    path.addLine(to: CGPoint(x: 60, y: 10))
                }
                .stroke(Color(red: 0.4, green: 0.25, blue: 0.15), lineWidth: 4)
                .frame(width: 70, height: 20)
            }
        }
        .animation(.spring(duration: 0.2), value: isOpen)
        .animation(.spring(duration: 0.2), value: isSmiling)
    }
}

#Preview {
    VStack(spacing: 40) {
        EggManView(isMouthOpen: false, isEating: false, onFrameChange: { _ in })
            .frame(width: 150, height: 180)

        EggManView(isMouthOpen: true, isEating: false, onFrameChange: { _ in })
            .frame(width: 150, height: 180)

        EggManView(isMouthOpen: false, isEating: true, onFrameChange: { _ in })
            .frame(width: 150, height: 180)
    }
    .padding()
    .background(Color(red: 0.95, green: 0.92, blue: 0.85))
}
