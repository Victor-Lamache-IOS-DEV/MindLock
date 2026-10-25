import SwiftUI

/// Vue de l'écran d'accueil factice (HOME) affichant la capture d'écran de l'utilisateur
public struct HomeView: View {
    let layout: Layout
    let image: UIImage?
    let endAction: EndAction
    var onLongPressReturnToLock: () -> Void

    @State private var scale: CGFloat = 1.12
    @State private var opacity: Double = 0.0

    public init(
        layout: Layout,
        image: UIImage?,
        endAction: EndAction,
        onLongPressReturnToLock: @escaping () -> Void
    ) {
        self.layout = layout
        self.image = image
        self.endAction = endAction
        self.onLongPressReturnToLock = onLongPressReturnToLock
    }

    public var body: some View {
        ZStack {
            Color.black

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: layout.screenWidth, height: layout.screenHeight)
                    .clipped()
            }
        }
        .frame(width: layout.screenWidth, height: layout.screenHeight)
        .scaleEffect(scale)
        .opacity(opacity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onAppear {
            // Animation d'apparition : zoom arrière de 1.12 à 1.0 et fondu en 0.35 s
            withAnimation(.easeOut(duration: 0.35)) {
                scale = 1.0
                opacity = 1.0
            }

            // Gestion de l'option de fin
            if endAction == .quitApp {
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 s
                    await MainActor.run {
                        AppExit.suspend()
                    }
                }
            }
        }
        .onLongPressGesture(minimumDuration: 1.5) {
            if endAction == .stayOnHome {
                onLongPressReturnToLock()
            }
        }
    }
}
