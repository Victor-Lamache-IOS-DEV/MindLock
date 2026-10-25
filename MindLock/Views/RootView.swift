import SwiftUI
import MediaPlayer
import AVFoundation

public enum AppScreen {
    case lock
    case passcode
    case unlocking
    case home
}

/// Vue UIKit intégrant MPVolumeView de façon invisible pour masquer le HUD système et intercepter le slider
public struct HiddenVolumeViewRepresentable: UIViewRepresentable {
    let volumeService: VolumeCodeService

    public init(volumeService: VolumeCodeService) {
        self.volumeService = volumeService
    }

    public func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 10, height: 10))
        volumeView.alpha = 0.01
        volumeView.clipsToBounds = true
        DispatchQueue.main.async {
            self.volumeService.setVolumeView(volumeView)
        }
        return volumeView
    }

    public func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

/// Vue racine de l'application orchestrant la machine à états et le dimensionnement iPhone 13
public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var settingsStore = SettingsStore.shared
    @StateObject private var volumeService = VolumeCodeService.shared
    @StateObject private var imageStore = ImageStore.shared

    @State private var currentScreen: AppScreen = .lock
    @State private var showSettings: Bool = false
    @State private var showCalibration: Bool = false

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            let layout = settingsStore.settings.layout
            let scale = geometry.size.width / layout.screenWidth

            ZStack {
                // Fond noir absolu
                Color.black.ignoresSafeArea()

                // Contenu calibré sur 390 × 844
                mainContent
                    .frame(width: layout.screenWidth, height: layout.screenHeight)
                    .scaleEffect(scale, anchor: .top)
                    .position(x: geometry.size.width / 2.0, y: (layout.screenHeight * scale) / 2.0)

                // MPVolumeView masquée dans la hiérarchie pour bloquer le HUD de volume d'iOS
                HiddenVolumeViewRepresentable(volumeService: volumeService)
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)

                // Calque de calibrage interactif
                if showCalibration {
                    CalibrationOverlay(
                        layout: $settingsStore.settings.layout,
                        calibOpacity: $settingsStore.settings.calibOpacity,
                        lockImage: imageStore.image(for: .calibLock),
                        passcodeImage: imageStore.image(for: .calibPasscode),
                        onDismiss: {
                            showCalibration = false
                        }
                    )
                }
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .all)
        .fullScreenCover(isPresented: $showSettings, onDismiss: {
            transitionToLock()
        }) {
            SettingsView(
                settingsStore: settingsStore,
                volumeService: volumeService,
                imageStore: imageStore,
                onDismiss: {
                    showSettings = false
                },
                onLaunchCalibration: {
                    showSettings = false
                    showCalibration = true
                }
            )
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Haptics.prepareAll()
            volumeService.start()
            transitionToLock()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                UIApplication.shared.isIdleTimerDisabled = true
                volumeService.handleAppForeground()
                transitionToLock()
            }
        }
    }

    // MARK: - Contenu Principal par Écran
    @ViewBuilder
    private var mainContent: some View {
        let layout = settingsStore.settings.layout
        let settings = settingsStore.settings

        ZStack {
            // Fond d'écran
            WallpaperView(
                layout: layout,
                image: imageStore.image(for: .wallpaper),
                blurRadius: (currentScreen == .passcode) ? CGFloat(settings.passcodeBlurRadius) : 0,
                darkeningOpacity: (currentScreen == .passcode) ? settings.passcodeDarkeningOpacity : 0
            )
            .animation(.easeInOut(duration: 0.3), value: currentScreen)

            // Vues d'écran
            switch currentScreen {
            case .lock:
                LockScreenView(
                    layout: layout,
                    settings: settings,
                    armedCode: volumeService.armedCode,
                    notifIcon: imageStore.image(for: .notifIcon),
                    onSwipeUpToPasscode: {
                        transitionToPasscode()
                    }
                )

                // Fausse barre d'état avec indicateur Centre de contrôle
                FakeStatusBar(
                    layout: layout,
                    carrierName: settings.carrierName,
                    cellularBars: settings.cellularBars,
                    showWifi: settings.showWifi,
                    showControlCenterIndicator: true
                )

            case .passcode:
                PasscodeView(
                    layout: layout,
                    settings: settings,
                    armedCode: volumeService.armedCode,
                    onCancel: {
                        transitionToLock()
                    },
                    onUnlocked: {
                        transitionToUnlocking()
                    },
                    onOpenSettings: {
                        showSettings = true
                    },
                    registerVolumeCallback: { callback in
                        volumeService.onSinglePress = callback
                    }
                )

                // Fausse barre d'état SANS indicateur Centre de contrôle
                FakeStatusBar(
                    layout: layout,
                    carrierName: settings.carrierName,
                    cellularBars: settings.cellularBars,
                    showWifi: settings.showWifi,
                    showControlCenterIndicator: false
                )

            case .unlocking:
                // Animation de déverrouillage intermédiaire
                EmptyView()

            case .home:
                HomeView(
                    layout: layout,
                    image: imageStore.image(for: .home),
                    endAction: settings.endAction,
                    onLongPressReturnToLock: {
                        transitionToLock()
                    }
                )
            }
        }
    }

    // MARK: - Transitions d'états
    private func transitionToLock() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentScreen = .lock
        }
        volumeService.isListening = true
    }

    private func transitionToPasscode() {
        volumeService.flush()
        volumeService.isListening = false

        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = .passcode
        }
    }

    private func transitionToUnlocking() {
        volumeService.isListening = false
        volumeService.clearArmedCode()

        withAnimation(.easeOut(duration: 0.2)) {
            currentScreen = .unlocking
        }

        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.35)) {
                    currentScreen = .home
                }
            }
        }
    }
}
