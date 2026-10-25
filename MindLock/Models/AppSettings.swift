import SwiftUI

public enum MindTrigger: String, Codable, CaseIterable, Identifiable {
    case volume = "Volume +"
    case delay = "Délai automatique"

    public var id: String { rawValue }
}

public enum NotifAutoHide: String, Codable, CaseIterable, Identifiable {
    case never = "Jamais"
    case fiveSeconds = "5 secondes"
    case tenSeconds = "10 secondes"

    public var id: String { rawValue }

    public var duration: Double? {
        switch self {
        case .never: return nil
        case .fiveSeconds: return 5.0
        case .tenSeconds: return 10.0
        }
    }
}

public enum DNDOption: String, Codable, CaseIterable, Identifiable {
    case always = "Toujours"
    case never = "Jamais"
    case auto = "Auto"

    public var id: String { rawValue }
}

public enum DateFormatOption: String, Codable, CaseIterable, Identifiable {
    case enGB = "en_GB (Sunday 25 October)"
    case enUS = "en_US (Sunday, October 25)"

    public var id: String { rawValue }

    public var formatString: String {
        switch self {
        case .enGB: return "EEEE d MMMM"
        case .enUS: return "EEEE, MMMM d"
        }
    }

    public var localeIdentifier: String {
        switch self {
        case .enGB: return "en_GB"
        case .enUS: return "en_US"
        }
    }
}

public enum TimeFontWeight: String, Codable, CaseIterable, Identifiable {
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"

    public var id: String { rawValue }

    public var swiftUIWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

public enum EndAction: String, Codable, CaseIterable, Identifiable {
    case stayOnHome = "Rester sur la fausse page d'accueil"
    case quitApp = "Quitter l'app (Mettre en veille/arrière-plan)"

    public var id: String { rawValue }
}

/// Modèle global des paramètres de l'application
public struct AppSettings: Codable, Equatable {
    // Mode
    public var mode: TrickMode = .coincidence

    // Codes
    public var defaultCode: String = "2580"
    public var secretSettingsCode: String = "1111"
    public var firstAttemptFails: Bool = false

    // Mind
    public var mindTrigger: MindTrigger = .volume
    public var mindDelaySeconds: Double = 4.0
    public var mindMinDigitDelay: Double = 0.7
    public var mindMaxDigitDelay: Double = 1.4

    // Volume
    public var digitCommitTimeout: Double = 2.0
    public var codeCompletionTimeout: Double = 4.0
    public var hapticPerDigit: Bool = true

    // Notification
    public var notifAppName: String = "N26"
    public var notifTitle: String = "Remboursement reçu"
    public var notifBodyTemplate: String = "Vous avez reçu {montant} de AMAZON EU SARL – commande n° {commande}"
    public var notifAutoHide: NotifAutoHide = .never

    // Apparence
    public var carrierName: String = "Tele2"
    public var cellularBars: Int = 4
    public var showWifi: Bool = true
    public var dndOption: DNDOption = .always
    public var dateFormat: DateFormatOption = .enGB
    public var leadingZeroInHour: Bool = true
    public var timeFontWeight: TimeFontWeight = .semibold
    public var passcodeBlurRadius: Double = 30.0
    public var passcodeDarkeningOpacity: Double = 0.30
    public var keypadButtonOpacity: Double = 0.18

    // Fin
    public var endAction: EndAction = .stayOnHome
    public var passcodeInactivityTimeout: Double = 10.0

    // Calibrage
    public var calibOpacity: Double = 0.50

    // Layout
    public var layout: Layout = Layout()

    public init() {}
}
