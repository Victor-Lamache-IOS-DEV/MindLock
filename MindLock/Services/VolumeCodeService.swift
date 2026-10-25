import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

/// Direction de l'appui sur le bouton de volume
public enum VolumeDirection: String, Codable {
    case up = "+"
    case down = "-"
}

/// Moteur logique de décodage des appuis de volume, testable unitairement
@MainActor
public final class VolumeInputLogicEngine: ObservableObject {
    @Published public private(set) var pendingDigits: [Int] = []
    @Published public private(set) var armedCode: String?
    @Published public private(set) var currentSeriesPresses: Int = 0
    @Published public private(set) var currentDirection: VolumeDirection?

    public var digitCommitTimeout: Double = 2.0
    public var codeCompletionTimeout: Double = 4.0
    public var hapticPerDigit: Bool = true

    // Callbacks pour les événements haptiques
    public var onDigitCommitted: (() -> Void)?
    public var onCodeAccepted: ((String) -> Void)?
    public var onInvalidLength: (() -> Void)?
    public var onHeldClear: (() -> Void)?

    private var digitCommitTask: Task<Void, Never>?
    private var codeCompletionTask: Task<Void, Never>?
    private var isCoolingDownAfterClear: Bool = false

    public init(
        digitCommitTimeout: Double = 2.0,
        codeCompletionTimeout: Double = 4.0,
        hapticPerDigit: Bool = true
    ) {
        self.digitCommitTimeout = digitCommitTimeout
        self.codeCompletionTimeout = codeCompletionTimeout
        self.hapticPerDigit = hapticPerDigit
    }

    /// Réinitialise l'intégralité de la saisie
    public func reset() {
        digitCommitTask?.cancel()
        codeCompletionTask?.cancel()
        pendingDigits.removeAll()
        currentSeriesPresses = 0
        currentDirection = nil
        armedCode = nil
        isCoolingDownAfterClear = false
    }

    /// Efface le code armé après un déverrouillage
    public func clearArmedCode() {
        armedCode = nil
    }

    /// Traite un appui sur un bouton de volume (+ ou -)
    public func registerPress(direction: VolumeDirection) {
        guard !isCoolingDownAfterClear else { return }

        // Si un code était déjà armé, tout nouvel appui commence une nouvelle saisie
        if armedCode != nil {
            armedCode = nil
            pendingDigits.removeAll()
            currentSeriesPresses = 0
            currentDirection = nil
        }

        // Annuler le timer de finalisation du code
        codeCompletionTask?.cancel()

        if let existingDirection = currentDirection {
            if existingDirection == direction {
                // Même bouton : incrémenter la série
                currentSeriesPresses += 1

                if currentSeriesPresses > 12 {
                    // Sécurité bouton maintenu enfoncé (> 12)
                    triggerHeldClear()
                    return
                }

                // Réinitialiser le timer d'inactivité pour valider le chiffre
                scheduleDigitCommitTimer()
            } else {
                // Bouton différent : valider le chiffre précédent immédiatement
                commitCurrentSeries()
                // Démarrer la nouvelle série avec 1 appui sur le nouveau bouton
                currentDirection = direction
                currentSeriesPresses = 1
                scheduleDigitCommitTimer()
            }
        } else {
            // Premier appui de la série
            currentDirection = direction
            currentSeriesPresses = 1
            scheduleDigitCommitTimer()
        }
    }

    /// Valide la série en cours et la convertit en chiffre (1..9, 10 -> 0)
    public func commitCurrentSeries() {
        digitCommitTask?.cancel()
        guard currentSeriesPresses > 0 else { return }

        let digit: Int
        if currentSeriesPresses == 10 {
            digit = 0
        } else if currentSeriesPresses < 10 {
            digit = currentSeriesPresses
        } else {
            // Entre 11 et 12 appuis : on ignore ou on prend modulo 10
            digit = currentSeriesPresses % 10
        }

        pendingDigits.append(digit)
        currentSeriesPresses = 0
        currentDirection = nil

        onDigitCommitted?()

        // Si 6 chiffres sont déjà saisis, finaliser le code automatiquement
        if pendingDigits.count == 6 {
            finalizeCode()
        } else {
            // Programmer le délai de fin de saisie
            scheduleCodeCompletionTimer()
        }
    }

    /// Force la validation immédiate (appelé lors du swipe up vers PASSCODE)
    public func flush() {
        digitCommitTask?.cancel()
        codeCompletionTask?.cancel()

        if currentSeriesPresses > 0 {
            let digit = (currentSeriesPresses == 10) ? 0 : (currentSeriesPresses % 10)
            pendingDigits.append(digit)
            currentSeriesPresses = 0
            currentDirection = nil
        }

        if pendingDigits.count == 4 || pendingDigits.count == 6 {
            let code = pendingDigits.map(String.init).joined()
            armedCode = code
            pendingDigits.removeAll()
            onCodeAccepted?(code)
        } else {
            // Effacement silencieux sans vibration
            pendingDigits.removeAll()
        }
    }

    private func scheduleDigitCommitTimer() {
        digitCommitTask?.cancel()
        let timeout = digitCommitTimeout
        digitCommitTask = Task { [weak self] in
            let nano = UInt64(timeout * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nano)
            guard !Task.isCancelled, let self = self else { return }
            self.commitCurrentSeries()
        }
    }

    private func scheduleCodeCompletionTimer() {
        codeCompletionTask?.cancel()
        let timeout = codeCompletionTimeout
        codeCompletionTask = Task { [weak self] in
            let nano = UInt64(timeout * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nano)
            guard !Task.isCancelled, let self = self else { return }
            self.finalizeCode()
        }
    }

    private func finalizeCode() {
        codeCompletionTask?.cancel()
        digitCommitTask?.cancel()

        let count = pendingDigits.count
        if count == 4 || count == 6 {
            let code = pendingDigits.map(String.init).joined()
            armedCode = code
            pendingDigits.removeAll()
            onCodeAccepted?(code)
        } else if count > 0 {
            pendingDigits.removeAll()
            armedCode = nil
            onInvalidLength?()
        }
    }

    private func triggerHeldClear() {
        digitCommitTask?.cancel()
        codeCompletionTask?.cancel()
        pendingDigits.removeAll()
        currentSeriesPresses = 0
        currentDirection = nil
        armedCode = nil
        isCoolingDownAfterClear = true

        onHeldClear?()

        // Période d'inhibition de 0.8 s après effacement
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            self?.isCoolingDownAfterClear = false
        }
    }
}

/// Service global de détection matérielle des boutons de volume et gestion du code secret
@MainActor
public final class VolumeCodeService: ObservableObject {
    public static let shared = VolumeCodeService()

    public let engine = VolumeInputLogicEngine()

    @Published public private(set) var pendingDigits: [Int] = []
    @Published public private(set) var armedCode: String?
    @Published public private(set) var lastPressedDirection: VolumeDirection?

    public var isListening: Bool = true
    public var onSinglePress: ((VolumeDirection) -> Void)?

    private var volumeView: MPVolumeView?
    private var volumeSlider: UISlider?
    private var volumeObserver: NSKeyValueObservation?
    private var isRecentering: Bool = false
    private var lastRecordedVolume: Float = 0.5
    private var cancellables = Set<AnyCancellable>()

    public init() {
        // Liaison des états de l'engine
        engine.$pendingDigits
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingDigits)

        engine.$armedCode
            .receive(on: DispatchQueue.main)
            .assign(to: &$armedCode)

        // Haptiques
        engine.onDigitCommitted = { [weak self] in
            guard let self = self, self.engine.hapticPerDigit else { return }
            Haptics.digitCommitted()
        }
        engine.onCodeAccepted = { _ in
            Haptics.codeAccepted()
        }
        engine.onInvalidLength = {
            Haptics.invalidLength()
        }
        engine.onHeldClear = {
            Haptics.buttonHeldClear()
        }
    }

    public func updateTimeouts(digitTimeout: Double, codeTimeout: Double, hapticPerDigit: Bool) {
        engine.digitCommitTimeout = digitTimeout
        engine.codeCompletionTimeout = codeTimeout
        engine.hapticPerDigit = hapticPerDigit
    }

    public func start() {
        configureAudioSession()
        setupVolumeSlider()
        observeVolume()
    }

    public func reset() {
        engine.reset()
    }

    public func flush() {
        engine.flush()
    }

    public func clearArmedCode() {
        engine.clearArmedCode()
    }

    public func setVolumeView(_ view: MPVolumeView) {
        self.volumeView = view
        setupVolumeSlider()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            lastRecordedVolume = session.outputVolume
        } catch {
            // Audio session silent fallback
        }
    }

    private func setupVolumeSlider() {
        guard let view = volumeView else { return }
        if volumeSlider == nil {
            volumeSlider = view.subviews.compactMap { $0 as? UISlider }.first
        }
        recenterSlider()
    }

    private func recenterSlider() {
        guard let slider = volumeSlider else { return }
        isRecentering = true
        slider.value = 0.5
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 50_000_000)
            self?.isRecentering = false
        }
    }

    private func observeVolume() {
        let session = AVAudioSession.sharedInstance()
        lastRecordedVolume = session.outputVolume

        volumeObserver = session.observe(\.outputVolume, options: [.new, .old]) { [weak self] _, change in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard !self.isRecentering else { return }

                guard let newVolume = change.newValue else { return }
                let oldVolume = change.oldValue ?? self.lastRecordedVolume
                let delta = newVolume - oldVolume

                // Ignorer les micro-variations
                guard abs(delta) >= 0.001 else { return }

                let direction: VolumeDirection = (newVolume > oldVolume) ? .up : .down
                self.lastPressedDirection = direction
                self.lastRecordedVolume = newVolume

                // Recentrer le slider pour permettre les appuis répétés continus
                self.recenterSlider()

                if self.isListening {
                    self.engine.registerPress(direction: direction)
                } else {
                    self.onSinglePress?(direction)
                }
            }
        }
    }

    public func handleAppForeground() {
        configureAudioSession()
        recenterSlider()
    }
}
