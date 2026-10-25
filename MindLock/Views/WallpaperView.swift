import SwiftUI

/// Vue affichant le fond d'écran avec zoom, décalage, flou et assombrissement configurables
public struct WallpaperView: View {
    let layout: Layout
    let image: UIImage?
    var blurRadius: CGFloat = 0.0
    var darkeningOpacity: Double = 0.0

    public init(
        layout: Layout,
        image: UIImage?,
        blurRadius: CGFloat = 0.0,
        darkeningOpacity: Double = 0.0
    ) {
        self.layout = layout
        self.image = image
        self.blurRadius = blurRadius
        self.darkeningOpacity = darkeningOpacity
    }

    public var body: some View {
        ZStack {
            Color.black

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: layout.screenWidth, height: layout.screenHeight)
                    .scaleEffect(layout.wallpaperZoom)
                    .offset(x: layout.wallpaperOffsetX, y: layout.wallpaperOffsetY)
                    .clipped()
            }

            if blurRadius > 0 {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: blurRadius)
            }

            if darkeningOpacity > 0 {
                Color.black.opacity(darkeningOpacity)
            }
        }
        .frame(width: layout.screenWidth, height: layout.screenHeight)
        .ignoresSafeArea()
    }
}
