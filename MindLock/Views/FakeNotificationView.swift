import SwiftUI

/// Fausse notification bancaire N26 dissimulant le code secret
public struct FakeNotificationView: View {
    let layout: Layout
    let notification: FakeNotification
    let iconImage: UIImage?

    public init(layout: Layout, notification: FakeNotification, iconImage: UIImage?) {
        self.layout = layout
        self.notification = notification
        self.iconImage = iconImage
    }

    public var body: some View {
        HStack(alignment: .top, spacing: layout.notifIconSpacing) {
            // Icône de l'app (N26 ou personnalisée)
            iconView
                .frame(width: layout.notifIconSize, height: layout.notifIconSize)

            // Contenu texte
            VStack(alignment: .leading, spacing: 3) {
                // Ligne 1 : Nom de l'app + heure ("now")
                HStack {
                    Text(notification.appName)
                        .font(.system(size: layout.notifAppNameFontSize, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text(notification.time)
                        .font(.system(size: layout.notifTimeFontSize))
                        .foregroundColor(Color.white.opacity(0.55))
                }

                // Ligne 2 : Titre
                Text(notification.title)
                    .font(.system(size: layout.notifTitleFontSize, weight: .semibold))
                    .foregroundColor(.white)

                // Corps du message (avec montant et numéro de commande dissimulé)
                Text(notification.body)
                    .font(.system(size: layout.notifBodyFontSize))
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .lineSpacing(2)
            }
        }
        .padding(layout.notifPadding)
        .frame(width: layout.notifWidth)
        .background(
            RoundedRectangle(cornerRadius: layout.notifCornerRadius, style: .continuous)
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)
        )
        .clipShape(RoundedRectangle(cornerRadius: layout.notifCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconImage = iconImage {
            Image(uiImage: iconImage)
                .resizable()
                .scaledToFill()
                .frame(width: layout.notifIconSize, height: layout.notifIconSize)
                .clipShape(RoundedRectangle(cornerRadius: layout.notifIconCornerRadius, style: .continuous))
        } else {
            // Icône N26 par défaut (carré noir arrondi avec N26 en blanc)
            ZStack {
                RoundedRectangle(cornerRadius: layout.notifIconCornerRadius, style: .continuous)
                    .fill(Color.black)

                Text("N26")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: layout.notifIconSize, height: layout.notifIconSize)
        }
    }
}
