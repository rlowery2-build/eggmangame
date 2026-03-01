import SwiftUI

// MARK: - Liquid Glass (iOS 26+, material fallback for earlier)

extension View {
    /// Applies Liquid Glass on iOS 26+, falls back to material on earlier versions.
    @ViewBuilder
    func liquidGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: shape)
        } else {
            self
                .background(.regularMaterial, in: shape)
                .background {
                    shape
                        .fill(.white.opacity(0.1))
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

// MARK: - Main HUD View

struct GameHUDView: View {
    @Bindable var gameManager: GameManager

    var onStorePressed: () -> Void
    var onHealPressed: () -> Void

    @State private var alertInfo: AlertInfo?

    struct AlertInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top HUD: Resources
                ResourceDisplayBar(
                    diamonds: gameManager.diamonds,
                    eggs: gameManager.totalEggs
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Task Banner
                if let task = gameManager.currentTask {
                    TaskBannerView(
                        task: task,
                        timeRemaining: gameManager.taskTimeRemaining
                    )
                    .padding(.horizontal)
                    .padding(.top, 12)
                }

                Spacer()

                // Bottom HUD: Action Buttons
                GameActionsView(
                    isSick: gameManager.isSick,
                    onStore: onStorePressed,
                    onHeal: onHealPressed
                )
                .padding(.horizontal)
                .padding(.bottom, 100) // Above egg basket
            }

            // Alert Overlay
            if let alert = alertInfo {
                GlassAlertView(
                    title: alert.title,
                    message: alert.message,
                    onDismiss: { alertInfo = nil }
                )
            }
        }
    }

    func showAlert(title: String, message: String) {
        alertInfo = AlertInfo(title: title, message: message)
    }
}

// MARK: - Resource Display Bar

struct ResourceDisplayBar: View {
    let diamonds: Int
    let eggs: Int

    var body: some View {
        HStack(spacing: 16) {
            // Diamond display
            ResourceBadge(icon: "💎", value: diamonds)

            Spacer()

            // Egg display
            ResourceBadge(icon: "🥚", value: eggs)
        }
    }
}

struct ResourceBadge: View {
    let icon: String
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.title3)
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Task Banner

struct TaskBannerView: View {
    let task: GameTask
    let timeRemaining: String

    var body: some View {
        VStack(spacing: 6) {
            Text("Task: \(task.descriptionText)")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                // Progress indicator
                HStack(spacing: 4) {
                    Text("Progress:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(task.progressText)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                // Time remaining
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(timeRemaining)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Reward
                HStack(spacing: 2) {
                    Text("💎")
                        .font(.caption)
                    Text("\(task.diamondReward)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Game Actions

struct GameActionsView: View {
    let isSick: Bool
    let onStore: () -> Void
    let onHeal: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Store button with glass effect
            Button(action: onStore) {
                Label("STORE", systemImage: "bag.fill")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .liquidGlass(in: Capsule())

            Spacer()

            // Heal button (only when sick)
            if isSick {
                Button(action: onHeal) {
                    HStack(spacing: 4) {
                        Text("HEAL")
                            .fontWeight(.bold)
                        Text("💎5")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .tint(.red)
                .liquidGlass(in: Capsule())
            }
        }
    }
}

// MARK: - Glass Alert

struct GlassAlertView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(duration: 0.25)) {
                        onDismiss()
                    }
                }

            // Alert content
            VStack(spacing: 16) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Tap to dismiss")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(28)
            .frame(width: 280)
            .liquidGlass(in: RoundedRectangle(cornerRadius: 16))
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(duration: 0.3), value: title)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.95, green: 0.92, blue: 0.85)
            .ignoresSafeArea()

        GameHUDView(
            gameManager: .shared,
            onStorePressed: {},
            onHealPressed: {}
        )
    }
}
