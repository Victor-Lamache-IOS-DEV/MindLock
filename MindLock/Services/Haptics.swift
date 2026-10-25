import UIKit

/// Gestionnaire centralisé des retours haptiques
@MainActor
public enum Haptics {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let notificationFeedback = UINotificationFeedbackGenerator()

    public static func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        rigidImpact.prepare()
        notificationFeedback.prepare()
    }

    /// Chiffre validé au volume (.light)
    public static func digitCommitted() {
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    /// Code accepté et notification affichée (.medium)
    public static func codeAccepted() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    /// Bouton de volume maintenu / effacement (2 x .rigid à 150 ms d'intervalle)
    public static func buttonHeldClear() {
        Task {
            rigidImpact.prepare()
            rigidImpact.impactOccurred()
            try? await Task.sleep(nanoseconds: 150_000_000)
            rigidImpact.prepare()
            rigidImpact.impactOccurred()
        }
    }

    /// Longueur de code invalide (3 x .rigid à 120 ms d'intervalle)
    public static func invalidLength() {
        Task {
            for _ in 0..<3 {
                rigidImpact.prepare()
                rigidImpact.impactOccurred()
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
    }

    /// Mauvais code saisi (.error)
    public static func wrongPasscode() {
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
    }

    /// Ouverture secrète des réglages (.success)
    public static func settingsOpened() {
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }

    /// Appui long sur lampe ou appareil photo (.medium)
    public static func toolButtonLongPress() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }
}
