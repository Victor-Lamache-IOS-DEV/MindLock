import Foundation

/// Modes de fonctionnement du tour de magie
public enum TrickMode: String, Codable, CaseIterable, Identifiable {
    case coincidence = "Coïncidence"
    case mind = "Mind"
    case anyCode = "N'importe quel code"
    case normal = "Normal"

    public var id: String { rawValue }

    public var summaryDescription: String {
        switch self {
        case .coincidence:
            return "Le code saisi au volume (ou le code par défaut) déverrouille le téléphone."
        case .mind:
            return "Les touches du clavier s'enfoncent toutes seules pour déverrouiller l'appareil."
        case .anyCode:
            return "N'importe quel code complet (4 ou 6 chiffres) déverrouille le téléphone."
        case .normal:
            return "Seul le code par défaut défini dans les réglages déverrouille le téléphone."
        }
    }
}
