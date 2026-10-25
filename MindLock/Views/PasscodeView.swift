import SwiftUI

/// Effet géométrique de tremblement (secousse) pour les codes erronés
public struct ShakeGeometryEffect: GeometryEffect {
    public var amount: CGFloat = 10.0
    public var shakesPerUnit: CGFloat = 3.0
    public var animatableData: CGFloat

    public init(shakes: CGFloat) {
        self.animatableData = shakes
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * 2.0 * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

/// Écran de saisie du code de déverrouillage (PASSCODE)
public struct PasscodeView: View {
    let layout: Layout
    let settings: AppSettings
    let armedCode: String?
    var onCancel: () -> Void
    var onUnlocked: () -> Void
    var onOpenSettings: () -> Void
    var registerVolumeCallback: (@escaping (VolumeDirection) -> Void) -> Void

    @State private var enteredDigits: [Int] = []
    @State private var shakeCount: CGFloat = 0.0
    @State private var isFirstAttempt: Bool = true
    @State private var programmaticallyHighlightedDigit: Int? = nil

    // Inactivité
    @State private var inactivityTask: Task<Void, Never>?

    // Mode Mind
    @State private var isMindAutoTyping: Bool = false
    @State private var mindTask: Task<Void, Never>?
    @State private var didRunMindInThisSession: Bool = false

    // Bouton Urgence
    @State private var isEmergencyPressed: Bool = false

    // Arrivée de l'écran (fondu + glissement de 30 pt vers le haut)
    @State private var contentOffsetY: CGFloat = 30.0
    @State private var contentOpacity: Double = 0.0

    public init(
        layout: Layout,
        settings: AppSettings,
        armedCode: String?,
        onCancel: @escaping () -> Void,
        onUnlocked: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        registerVolumeCallback: @escaping (@escaping (VolumeDirection) -> Void) -> Void
    ) {
        self.layout = layout
        self.settings = settings
        self.armedCode = armedCode
        self.onCancel = onCancel
        self.onUnlocked = onUnlocked
        self.onOpenSettings = onOpenSettings
        self.registerVolumeCallback = registerVolumeCallback
    }

    /// Détermine le code attendu selon le mode actif
    private var expectedCode: String? {
        switch settings.mode {
        case .coincidence, .mind:
            return armedCode ?? settings.defaultCode
        case .anyCode:
            return nil // Tout code complet déverrouille
        case .normal:
            return settings.defaultCode
        }
    }

    /// Nombre de points affichés
    private var targetLength: Int {
        switch settings.mode {
        case .coincidence, .mind:
            return (armedCode ?? settings.defaultCode).count
        case .anyCode:
            return armedCode?.count ?? 4
        case .normal:
            return settings.defaultCode.count
        }
    }

    public var body: some View {
        ZStack {
            // Cadenas
            Image(systemName: "lock.fill")
                .font(.system(size: layout.passcodePadlockSize, weight: .semibold))
                .foregroundColor(.white)
                .position(x: layout.passcodePadlockX, y: layout.passcodePadlockY)

            // Contenu animé à l'arrivée (Titre, Points, Clavier, Boutons)
            ZStack {
                // Titre
                Text("Enter Passcode")
                    .font(.system(size: layout.titleFontSize, weight: .regular))
                    .foregroundColor(.white)
                    .position(x: layout.screenWidth / 2.0, y: layout.titleY)

                // Rangée de points avec effet de secousse en cas d'erreur
                dotsRow
                    .modifier(ShakeGeometryEffect(shakes: shakeCount))
                    .position(x: layout.screenWidth / 2.0, y: layout.dotsY)

                // Clavier numérique
                keypadGrid

                // Bouton Emergency (bas gauche)
                emergencyButton
                    .position(x: layout.emergencyX, y: layout.emergencyY)

                // Bouton Cancel / Delete (bas droit)
                cancelDeleteButton
                    .position(x: layout.cancelDeleteX, y: layout.cancelDeleteY)
            }
            .offset(y: contentOffsetY)
            .opacity(contentOpacity)
        }
        .frame(width: layout.screenWidth, height: layout.screenHeight)
        .contentShape(Rectangle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                contentOffsetY = 0
                contentOpacity = 1.0
            }

            resetInactivityTimer()
            setupMindMode()
        }
        .onDisappear {
            inactivityTask?.cancel()
            mindTask?.cancel()
        }
    }

    // MARK: - Rangée de Points
    private var dotsRow: some View {
        HStack(spacing: layout.dotSpacing - layout.dotDiameter) {
            ForEach(0..<targetLength, id: \.self) { index in
                let isFilled = index < enteredDigits.count
                Circle()
                    .stroke(Color.white, lineWidth: layout.dotStrokeWidth)
                    .background(
                        Circle().fill(isFilled ? Color.white : Color.clear)
                    )
                    .frame(width: layout.dotDiameter, height: layout.dotDiameter)
            }
        }
    }

    // MARK: - Clavier
    private var keypadGrid: some View {
        ZStack {
            // Ligne 1 : 1, 2, 3
            buttonFor(digit: 1, letters: "", x: layout.keypadCol1X, y: layout.keypadRow1Y)
            buttonFor(digit: 2, letters: "ABC", x: layout.keypadCol2X, y: layout.keypadRow1Y)
            buttonFor(digit: 3, letters: "DEF", x: layout.keypadCol3X, y: layout.keypadRow1Y)

            // Ligne 2 : 4, 5, 6
            buttonFor(digit: 4, letters: "GHI", x: layout.keypadCol1X, y: layout.keypadRow2Y)
            buttonFor(digit: 5, letters: "JKL", x: layout.keypadCol2X, y: layout.keypadRow2Y)
            buttonFor(digit: 6, letters: "MNO", x: layout.keypadCol3X, y: layout.keypadRow2Y)

            // Ligne 3 : 7, 8, 9
            buttonFor(digit: 7, letters: "PQRS", x: layout.keypadCol1X, y: layout.keypadRow3Y)
            buttonFor(digit: 8, letters: "TUV", x: layout.keypadCol2X, y: layout.keypadRow3Y)
            buttonFor(digit: 9, letters: "WXYZ", x: layout.keypadCol3X, y: layout.keypadRow3Y)

            // Ligne 4 : 0
            buttonFor(digit: 0, letters: "", x: layout.keypadZeroX, y: layout.keypadZeroY)
        }
    }

    private func buttonFor(digit: Int, letters: String, x: CGFloat, y: CGFloat) -> some View {
        let isSecretCandidate = shouldCheckSecretCandidate(digit: digit)

        return KeypadButton(
            digit: digit,
            letters: letters,
            layout: layout,
            defaultOpacity: settings.keypadButtonOpacity,
            isProgrammaticallyHighlighted: (programmaticallyHighlightedDigit == digit),
            isSecretKeyCandidate: isSecretCandidate,
            onTouchDown: {
                handleUserManualTap()
                appendDigit(digit)
            },
            onSecretHoldTriggered: {
                handleSecretHold()
            }
        )
        .position(x: x, y: y)
    }

    private func shouldCheckSecretCandidate(digit: Int) -> Bool {
        // Règle 1111 (§8.4) :
        // 3 chiffres '1' déjà saisis et touche '1' pressée
        guard digit == 1, enteredDigits == [1, 1, 1] else { return false }

        // Exception : si le code attendu est lui-même 1111, cette règle est désactivée !
        if let expected = expectedCode, expected == "1111" {
            return false
        }
        return true
    }

    // MARK: - Actions de saisie
    private func appendDigit(_ digit: Int) {
        resetInactivityTimer()

        guard enteredDigits.count < targetLength else { return }
        enteredDigits.append(digit)

        if enteredDigits.count == targetLength {
            validateCode()
        }
    }

    private func handleSecretHold() {
        Haptics.settingsOpened()
        enteredDigits.removeAll()
        onOpenSettings()
    }

    private func validateCode() {
        let enteredString = enteredDigits.map(String.init).joined()

        // Option "Le premier essai échoue"
        if settings.firstAttemptFails && isFirstAttempt {
            isFirstAttempt = false
            triggerWrongPasscodeShake()
            return
        }

        // Vérification de validité
        let isValid: Bool
        if settings.mode == .anyCode {
            isValid = true
        } else if let expected = expectedCode {
            isValid = (enteredString == expected)
        } else {
            isValid = false
        }

        if isValid {
            // Code juste : attendre 0.15 s que le dernier point s'affiche
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                await MainActor.run {
                    onUnlocked()
                }
            }
        } else {
            triggerWrongPasscodeShake()
        }
    }

    private func triggerWrongPasscodeShake() {
        Haptics.wrongPasscode()

        // Animation de tremblement sinusoïdal sur 0.4 s
        withAnimation(.easeInOut(duration: 0.4)) {
            shakeCount = 1.0
        }

        // Vider les points à 0.45 s après le début
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            await MainActor.run {
                shakeCount = 0.0
                enteredDigits.removeAll()
            }
        }
    }

    // MARK: - Mode Mind (Saisie automatique)
    private func setupMindMode() {
        guard settings.mode == .mind, !didRunMindInThisSession else { return }

        // Enregistrement du déclencheur Volume +
        registerVolumeCallback { direction in
            if direction == .up && settings.mindTrigger == .volume {
                startMindAutoTyping()
            }
        }

        // Déclencheur par délai automatique
        if settings.mindTrigger == .delay {
            mindTask = Task {
                let nano = UInt64(settings.mindDelaySeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nano)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    startMindAutoTyping()
                }
            }
        }
    }

    private func startMindAutoTyping() {
        guard !didRunMindInThisSession, !isMindAutoTyping else { return }
        didRunMindInThisSession = true
        isMindAutoTyping = true
        inactivityTask?.cancel() // Désactiver l'inactivité pendant Mind

        guard let target = expectedCode else { return }
        let digitsToType = target.compactMap { Int(String($0)) }

        mindTask = Task {
            for digit in digitsToType {
                guard !Task.isCancelled else { break }

                // Pause aléatoire entre les chiffres
                let delay = Double.random(in: settings.mindMinDigitDelay...settings.mindMaxDigitDelay)
                let nanoDelay = UInt64(delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoDelay)
                guard !Task.isCancelled else { break }

                // Allumage de la touche pendant 0.12 s
                await MainActor.run {
                    programmaticallyHighlightedDigit = digit
                    appendDigit(digit)
                }

                try? await Task.sleep(nanoseconds: 120_000_000)
                await MainActor.run {
                    programmaticallyHighlightedDigit = nil
                }
            }
            await MainActor.run {
                isMindAutoTyping = false
                resetInactivityTimer()
            }
        }
    }

    private func handleUserManualTap() {
        if isMindAutoTyping {
            // Annulation de la saisie automatique si l'utilisateur touche l'écran
            mindTask?.cancel()
            isMindAutoTyping = false
            programmaticallyHighlightedDigit = nil
        }
    }

    // MARK: - Bouton Emergency
    private var emergencyButton: some View {
        Button(action: {}) {
            Text("Emergency")
                .font(.system(size: layout.emergencyFontSize))
                .foregroundColor(.white)
                .opacity(isEmergencyPressed ? 0.40 : 1.0)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isEmergencyPressed = true }
                .onEnded { _ in isEmergencyPressed = false }
        )
    }

    // MARK: - Bouton Cancel / Delete
    private var cancelDeleteButton: some View {
        Button(action: {
            handleUserManualTap()
            if enteredDigits.isEmpty {
                onCancel()
            } else {
                enteredDigits.removeLast()
                resetInactivityTimer()
            }
        }) {
            Text(enteredDigits.isEmpty ? "Cancel" : "Delete")
                .font(.system(size: layout.cancelDeleteFontSize))
                .foregroundColor(.white)
        }
    }

    // MARK: - Timer d'inactivité
    private func resetInactivityTimer() {
        inactivityTask?.cancel()
        guard !isMindAutoTyping, settings.passcodeInactivityTimeout > 0 else { return }

        let timeout = settings.passcodeInactivityTimeout
        inactivityTask = Task {
            let nano = UInt64(timeout * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nano)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                onCancel()
            }
        }
    }
}
