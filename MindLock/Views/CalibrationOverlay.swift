import SwiftUI

public enum CalibScreenTarget {
    case lock
    case passcode
}

public enum CalibElement: String, CaseIterable, Identifiable {
    case statusBar = "Barre d'état"
    case padlock = "Cadenas"
    case date = "Date"
    case time = "Heure"
    case bottomButtons = "Boutons du bas"
    case dnd = "Do Not Disturb"
    case homeBar = "Barre d'accueil"
    case notification = "Notification"
    case passcodeTitle = "Titre du code"
    case dots = "Points"
    case keypad = "Clavier"
    case emergencyCancel = "Emergency / Cancel"
    case wallpaper = "Fond d'écran"

    public var id: String { rawValue }
}

/// Calque de calibrage avec capture d'écran semi-transparente et panneau flottant d'ajustement
public struct CalibrationOverlay: View {
    @Binding var layout: Layout
    @Binding var calibOpacity: Double
    let lockImage: UIImage?
    let passcodeImage: UIImage?
    var onDismiss: () -> Void

    @State private var currentScreen: CalibScreenTarget = .lock
    @State private var selectedElement: CalibElement = .time
    @State private var isCollapsed: Bool = false
    @State private var panelOffset: CGSize = CGSize(width: 0, height: 180)

    public init(
        layout: Binding<Layout>,
        calibOpacity: Binding<Double>,
        lockImage: UIImage?,
        passcodeImage: UIImage?,
        onDismiss: @escaping () -> Void
    ) {
        self._layout = layout
        self._calibOpacity = calibOpacity
        self.lockImage = lockImage
        self.passcodeImage = passcodeImage
        self.onDismiss = onDismiss
    }

    private var activeOverlayImage: UIImage? {
        (currentScreen == .lock) ? lockImage : passcodeImage
    }

    public var body: some View {
        ZStack {
            // Calque d'image de référence semi-transparent
            if let image = activeOverlayImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: layout.screenWidth, height: layout.screenHeight)
                    .opacity(calibOpacity)
                    .allowsHitTesting(false)
            }

            // Panneau flottant déplaçable et réductible
            floatingControlPanel
                .offset(panelOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            panelOffset = CGSize(
                                width: panelOffset.width + value.translation.width,
                                height: panelOffset.height + value.translation.height
                            )
                        }
                )
        }
        .frame(width: layout.screenWidth, height: layout.screenHeight)
        .ignoresSafeArea()
    }

    // MARK: - Panneau Flottant
    private var floatingControlPanel: some View {
        VStack(spacing: 8) {
            // Barre d'en-tête du panneau
            HStack {
                Text("Calibrage (\(currentScreen == .lock ? "LOCK" : "PASSCODE"))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    currentScreen = (currentScreen == .lock) ? .passcode : .lock
                }) {
                    Text("Inverser")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue))
                        .foregroundColor(.white)
                }

                Button(action: { isCollapsed.toggle() }) {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                Button(action: onDismiss) {
                    Text("Terminer")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            }

            if !isCollapsed {
                Divider().background(Color.white.opacity(0.2))

                // Sélecteur d'élément
                Picker("Élément", selection: $selectedElement) {
                    ForEach(CalibElement.allCases) { element in
                        Text(element.rawValue).tag(element)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)

                // Curseur d'opacité du calque
                HStack {
                    Text("Calque : \(Int(calibOpacity * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Slider(value: $calibOpacity, in: 0.1...1.0)
                }

                Divider().background(Color.white.opacity(0.2))

                // Contrôles spécifiques à l'élément sélectionné
                ScrollView {
                    VStack(spacing: 10) {
                        elementControlsView
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(12)
        .frame(width: 350)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Contrôles détaillés
    @ViewBuilder
    private var elementControlsView: some View {
        switch selectedElement {
        case .statusBar:
            stepperControl(label: "Opérateur Y", value: $layout.carrierCenterY)
            stepperControl(label: "Opérateur X", value: $layout.carrierLeftX)
            stepperControl(label: "Taille police opérateur", value: $layout.carrierFontSize)
            stepperControl(label: "Icônes Y", value: $layout.rightIconsCenterY)
            stepperControl(label: "Batterie bord droit X", value: $layout.batteryRightX)
            stepperControl(label: "Indicateur CC Y", value: $layout.controlCenterY)

        case .padlock:
            stepperControl(label: "Cadenas Lock Y", value: $layout.lockPadlockY)
            stepperControl(label: "Cadenas Passcode Y", value: $layout.passcodePadlockY)
            stepperControl(label: "Taille cadenas", value: $layout.lockPadlockSize)

        case .date:
            stepperControl(label: "Date Y", value: $layout.dateY)
            stepperControl(label: "Taille police date", value: $layout.dateFontSize)

        case .time:
            stepperControl(label: "Heure Y (centre)", value: $layout.timeY)
            stepperControl(label: "Taille police heure", value: $layout.timeFontSize, range: 70...130)

        case .bottomButtons:
            stepperControl(label: "Lampe X", value: $layout.flashlightX)
            stepperControl(label: "Lampe Y", value: $layout.flashlightY)
            stepperControl(label: "Caméra X", value: $layout.cameraX)
            stepperControl(label: "Caméra Y", value: $layout.cameraY)
            stepperControl(label: "Diamètre boutons", value: $layout.flashlightDiameter)

        case .dnd:
            stepperControl(label: "DND Y", value: $layout.dndY)
            stepperControl(label: "Taille icône DND", value: $layout.dndIconSize)
            stepperControl(label: "Taille police DND", value: $layout.dndFontSize)

        case .homeBar:
            stepperControl(label: "Home Bar Y", value: $layout.homeBarY)
            stepperControl(label: "Largeur Home Bar", value: $layout.homeBarWidth)
            stepperControl(label: "Hauteur Home Bar", value: $layout.homeBarHeight)

        case .notification:
            stepperControl(label: "Notif bas Y", value: $layout.notifBottomY)
            stepperControl(label: "Largeur notif", value: $layout.notifWidth)
            stepperControl(label: "Rayon coins", value: $layout.notifCornerRadius)

        case .passcodeTitle:
            stepperControl(label: "Titre Y", value: $layout.titleY)
            stepperControl(label: "Taille police", value: $layout.titleFontSize)

        case .dots:
            stepperControl(label: "Points Y", value: $layout.dotsY)
            stepperControl(label: "Diamètre point", value: $layout.dotDiameter)
            stepperControl(label: "Espacement points", value: $layout.dotSpacing)

        case .keypad:
            stepperControl(label: "Diamètre touche", value: $layout.keypadDiameter)
            stepperControl(label: "Ligne 1 Y (1,2,3)", value: $layout.keypadRow1Y)
            stepperControl(label: "Ligne 2 Y (4,5,6)", value: $layout.keypadRow2Y)
            stepperControl(label: "Ligne 3 Y (7,8,9)", value: $layout.keypadRow3Y)
            stepperControl(label: "Ligne 4 Y (0)", value: $layout.keypadZeroY)
            stepperControl(label: "Colonne 1 X", value: $layout.keypadCol1X)
            stepperControl(label: "Colonne 2 X", value: $layout.keypadCol2X)
            stepperControl(label: "Colonne 3 X", value: $layout.keypadCol3X)
            stepperControl(label: "Taille chiffres", value: $layout.keypadDigitFontSize)
            stepperControl(label: "Taille lettres", value: $layout.keypadLettersFontSize)
            stepperControl(label: "Décalage chiffre Y", value: $layout.keypadDigitOffsetY)

        case .emergencyCancel:
            stepperControl(label: "Emergency Y", value: $layout.emergencyY)
            stepperControl(label: "Cancel/Delete Y", value: $layout.cancelDeleteY)
            stepperControl(label: "Taille police", value: $layout.emergencyFontSize)

        case .wallpaper:
            stepperControl(label: "Zoom fond", value: Binding(
                get: { CGFloat(layout.wallpaperZoom) },
                set: { layout.wallpaperZoom = Double($0) }
            ), step: 0.01)
            stepperControl(label: "Décalage X", value: $layout.wallpaperOffsetX)
            stepperControl(label: "Décalage Y", value: $layout.wallpaperOffsetY)
        }
    }

    private func stepperControl(
        label: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat> = -200...900,
        step: CGFloat = 0.5
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white)
            Spacer()

            Text(String(format: "%.1f", value.wrappedValue))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.yellow)
                .frame(width: 45)

            Button("-") {
                value.wrappedValue -= step
            }
            .font(.system(size: 14, weight: .bold))
            .frame(width: 28, height: 24)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.4)))
            .foregroundColor(.white)

            Button("+") {
                value.wrappedValue += step
            }
            .font(.system(size: 14, weight: .bold))
            .frame(width: 28, height: 24)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.4)))
            .foregroundColor(.white)
        }
    }
}
