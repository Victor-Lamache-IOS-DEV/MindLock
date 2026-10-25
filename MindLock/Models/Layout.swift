import SwiftUI

/// Structure contenant l'intégralité des mesures et positions de l'interface en points (repère 390 × 844).
/// Conforme à Codable pour la persistance et le calibrage interactif.
public struct Layout: Codable, Equatable {
    // MARK: - Écran de référence
    public var screenWidth: CGFloat = 390.0
    public var screenHeight: CGFloat = 844.0

    // MARK: - Fausse barre d'état
    public var carrierLeftX: CGFloat = 45.0
    public var carrierCenterY: CGFloat = 27.0
    public var carrierFontSize: CGFloat = 16.0

    public var rightIconsCenterY: CGFloat = 27.0
    public var batteryRightX: CGFloat = 363.0
    public var rightIconSpacing: CGFloat = 6.0

    public var signalBarWidth: CGFloat = 3.0
    public var signalBarSpacing: CGFloat = 1.5
    public var signalBarHeights: [CGFloat] = [4.0, 6.5, 9.0, 11.5]
    public var signalCornerRadius: CGFloat = 1.0

    public var wifiFontSize: CGFloat = 15.0

    public var batteryBodyWidth: CGFloat = 24.5
    public var batteryBodyHeight: CGFloat = 11.5
    public var batteryCornerRadius: CGFloat = 3.5
    public var batteryStrokeWidth: CGFloat = 1.0
    public var batteryInnerPadding: CGFloat = 1.5

    public var batteryCapWidth: CGFloat = 1.5
    public var batteryCapHeight: CGFloat = 4.0
    public var batteryCapOffset: CGFloat = 1.0
    public var batteryBoltSize: CGFloat = 8.0

    public var controlCenterStartX: CGFloat = 295.0
    public var controlCenterEndX: CGFloat = 350.0
    public var controlCenterY: CGFloat = 40.0
    public var controlCenterThickness: CGFloat = 3.0
    public var controlCenterOpacity: Double = 0.60

    // MARK: - Écran Verrouillé (LOCK)
    public var lockPadlockX: CGFloat = 195.0
    public var lockPadlockY: CGFloat = 65.0
    public var lockPadlockSize: CGFloat = 18.0

    public var dateY: CGFloat = 101.0
    public var dateFontSize: CGFloat = 22.0

    public var timeY: CGFloat = 164.5
    public var timeFontSize: CGFloat = 104.0

    public var flashlightX: CGFloat = 71.0
    public var flashlightY: CGFloat = 769.0
    public var flashlightDiameter: CGFloat = 50.0
    public var flashlightIconSize: CGFloat = 20.0

    public var cameraX: CGFloat = 319.0
    public var cameraY: CGFloat = 769.0
    public var cameraDiameter: CGFloat = 50.0
    public var cameraIconSize: CGFloat = 20.0

    public var dndX: CGFloat = 195.0
    public var dndY: CGFloat = 769.0
    public var dndIconSize: CGFloat = 13.0
    public var dndFontSize: CGFloat = 16.0
    public var dndSpacing: CGFloat = 5.0

    public var homeBarX: CGFloat = 195.0
    public var homeBarY: CGFloat = 833.0
    public var homeBarWidth: CGFloat = 136.0
    public var homeBarHeight: CGFloat = 5.0

    // MARK: - Fausse Notification
    public var notifWidth: CGFloat = 358.0
    public var notifBottomY: CGFloat = 715.0
    public var notifCornerRadius: CGFloat = 22.0
    public var notifPadding: CGFloat = 14.0
    public var notifIconSize: CGFloat = 38.0
    public var notifIconCornerRadius: CGFloat = 9.0
    public var notifIconSpacing: CGFloat = 10.0
    public var notifAppNameFontSize: CGFloat = 15.0
    public var notifTimeFontSize: CGFloat = 13.0
    public var notifTitleFontSize: CGFloat = 15.0
    public var notifBodyFontSize: CGFloat = 15.0

    // MARK: - Écran de Code (PASSCODE)
    public var passcodePadlockX: CGFloat = 195.0
    public var passcodePadlockY: CGFloat = 65.0
    public var passcodePadlockSize: CGFloat = 18.0

    public var titleY: CGFloat = 165.0
    public var titleFontSize: CGFloat = 21.0

    public var dotsY: CGFloat = 203.0
    public var dotDiameter: CGFloat = 12.5
    public var dotSpacing: CGFloat = 37.0
    public var dotStrokeWidth: CGFloat = 1.0

    public var keypadDiameter: CGFloat = 77.0
    public var keypadCol1X: CGFloat = 93.0
    public var keypadCol2X: CGFloat = 195.0
    public var keypadCol3X: CGFloat = 296.0
    public var keypadRow1Y: CGFloat = 332.0
    public var keypadRow2Y: CGFloat = 428.0
    public var keypadRow3Y: CGFloat = 523.0
    public var keypadZeroX: CGFloat = 195.0
    public var keypadZeroY: CGFloat = 619.0

    public var keypadDigitFontSize: CGFloat = 38.0
    public var keypadLettersFontSize: CGFloat = 10.0
    public var keypadLettersTracking: CGFloat = 2.0
    public var keypadDigitOffsetY: CGFloat = -2.0

    public var emergencyX: CGFloat = 93.0
    public var emergencyY: CGFloat = 784.0
    public var emergencyFontSize: CGFloat = 18.0

    public var cancelDeleteX: CGFloat = 296.0
    public var cancelDeleteY: CGFloat = 784.0
    public var cancelDeleteFontSize: CGFloat = 18.0

    // MARK: - Fond d'écran
    public var wallpaperZoom: Double = 1.00
    public var wallpaperOffsetX: CGFloat = 0.0
    public var wallpaperOffsetY: CGFloat = 0.0

    public init() {}

    /// Export sous forme de chaîne JSON formatée
    public func toJSONString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }

    /// Import depuis une chaîne JSON
    public static func from(jsonString: String) -> Layout? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Layout.self, from: data)
    }
}
