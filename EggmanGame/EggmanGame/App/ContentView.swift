import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createMenuScene(size: geometry.size))
                .ignoresSafeArea()
        }
    }

    private func createMenuScene(size: CGSize) -> SKScene {
        let scene = MenuScene(size: size)
        scene.scaleMode = .resizeFill
        return scene
    }
}

#Preview {
    ContentView()
}
