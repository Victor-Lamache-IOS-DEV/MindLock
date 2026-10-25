import SwiftUI
import Combine

/// Écran verrouillé (LOCK) imitant fidèlement iOS 18
public struct LockScreenView: View {
    let layout: Layout
    let settings: AppSettings
    let armedCode: String?
    let notifIcon: UIImage?
    var onSwipeUpToPasscode: () -> Void
    var onOpenSettings: (() -> Void)?

    @State private var dragOffsetY: CGFloat = 0.0
    @State private var currentDate: Date = Date()
    @State private var timerSubscription: AnyCancellable?

    // Animations des boutons lampe et caméra
    @State private var isFlashlightScaled: Bool = false
    @State private var isCameraScaled: Bool = false

    // Auto-masquage de la notification
    @State private var isNotifVisible: Bool = false
    @State private var notifAutoHideTask: Task<Void, Never>?

    public init(
        layout: Layout,
        settings: AppSettings,
        armedCode: String?,
        notifIcon: UIImage?,
        onSwipeUpToPasscode: @escaping () -> Void,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.layout = layout
        self.settings = settings
        self.armedCode = armedCode
        self.notifIcon = notifIcon
        self.onSwipeUpToPasscode = onSwipeUpToPasscode
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        ZStack {
            // Contenu déplaçable avec le geste de glissement vers le haut (50% de la translation)
            ZStack {
                // Cadenas (avec secours triple-tap pour ouvrir les réglages)
                Image(systemName: "lock.fill")
                    .font(.system(size: layout.lockPadlockSize, weight: .semibold))
                    .foregroundColor(.white)
                    .position(x: layout.lockPadlockX, y: layout.lockPadlockY)
                    .onTapGesture(count: 3) {
                        Haptics.settingsOpened()
                        onOpenSettings?()
                    }

                // Date
                Text(formattedDate)
                    .font(.system(size: layout.dateFontSize, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.90))
                    .position(x: layout.screenWidth / 2.0, y: layout.dateY)

                // Horloge (format 24h)
                Text(formattedTime)
                    .font(.system(size: layout.timeFontSize, weight: settings.timeFontWeight.swiftUIWeight))
                    .foregroundColor(.white)
                    .position(x: layout.screenWidth / 2.0, y: layout.timeY)

                // Fausse notification N26
                if isNotifVisible, let code = armedCode {
                    let notif = NotificationFactory.createNotification(
                        code: code,
                        appName: settings.notifAppName,
                        title: settings.notifTitle,
                        bodyTemplate: settings.notifBodyTemplate
                    )

                    FakeNotificationView(layout: layout, notification: notif, iconImage: notifIcon)
                        .position(x: layout.screenWidth / 2.0, y: layout.notifBottomY - 50)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                }

                // Bouton "Do Not Disturb"
                if shouldShowDND {
                    HStack(spacing: layout.dndSpacing) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: layout.dndIconSize))
                        Text("Do Not Disturb")
                            .font(.system(size: layout.dndFontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .position(x: layout.dndX, y: layout.dndY)
                }

                // Bouton Lampe de poche (en bas à gauche)
                flashlightButton
                    .position(x: layout.flashlightX, y: layout.flashlightY)

                // Bouton Appareil photo (en bas à droite)
                cameraButton
                    .position(x: layout.cameraX, y: layout.cameraY)

                // Fausse barre d'accueil (Home Indicator)
                Capsule()
                    .fill(Color.white)
                    .frame(width: layout.homeBarWidth, height: layout.homeBarHeight)
                    .position(x: layout.homeBarX, y: layout.homeBarY)
            }
            .offset(y: dragOffsetY)
        }
        .frame(width: layout.screenWidth, height: layout.screenHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Déplacement vers le haut uniquement, à 50% de la vitesse du doigt
                    if value.translation.height < 0 {
                        dragOffsetY = value.translation.height * 0.5
                    }
                }
                .onEnded { value in
                    let distance = -value.translation.height
                    let velocity = -value.predictedEndTranslation.height

                    if distance > 80 || velocity > 300 {
                        // Bascule vers PASSCODE
                        onSwipeUpToPasscode()
                        dragOffsetY = 0
                    } else {
                        // Retour élastique
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dragOffsetY = 0
                        }
                    }
                }
        )
        .onAppear {
            updateCurrentTime()
            timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    updateCurrentTime()
                }
            handleArmedCodeChange(armedCode)
        }
        .onDisappear {
            timerSubscription?.cancel()
            notifAutoHideTask?.cancel()
        }
        .onChange(of: armedCode) { newCode in
            handleArmedCodeChange(newCode)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.dateFormat.localeIdentifier)
        formatter.dateFormat = settings.dateFormat.formatString
        return formatter.string(from: currentDate)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.leadingZeroInHour ? "HH:mm" : "H:mm"
        return formatter.string(from: currentDate)
    }

    private var shouldShowDND: Bool {
        switch settings.dndOption {
        case .always, .auto:
            return true
        case .never:
            return false
        }
    }

    private func updateCurrentTime() {
        currentDate = Date()
    }

    private func handleArmedCodeChange(_ code: String?) {
        notifAutoHideTask?.cancel()

        if code != nil {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                isNotifVisible = true
            }

            if let duration = settings.notifAutoHide.duration {
                notifAutoHideTask = Task {
                    let nano = UInt64(duration * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nano)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isNotifVisible = false
                        }
                    }
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                isNotifVisible = false
            }
        }
    }

    // MARK: - Bouton Lampe
    private var flashlightButton: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(Color.black.opacity(0.25)))
                .frame(width: layout.flashlightDiameter, height: layout.flashlightDiameter)

            Image(systemName: "flashlight.off.fill")
                .font(.system(size: layout.flashlightIconSize))
                .foregroundColor(.white)
        }
        .scaleEffect(isFlashlightScaled ? 1.15 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFlashlightScaled)
        .onLongPressGesture(minimumDuration: 0.5, perform: {
            Haptics.toolButtonLongPress()
            isFlashlightScaled = true
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    isFlashlightScaled = false
                }
            }
        })
    }

    // MARK: - Bouton Caméra
    private var cameraButton: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(Color.black.opacity(0.25)))
                .frame(width: layout.cameraDiameter, height: layout.cameraDiameter)

            Image(systemName: "camera.fill")
                .font(.system(size: layout.cameraIconSize))
                .foregroundColor(.white)
        }
        .scaleEffect(isCameraScaled ? 1.15 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isCameraScaled)
        .onLongPressGesture(minimumDuration: 0.5, perform: {
            Haptics.toolButtonLongPress()
            isCameraScaled = true
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    isCameraScaled = false
                }
            }
        })
    }
}
