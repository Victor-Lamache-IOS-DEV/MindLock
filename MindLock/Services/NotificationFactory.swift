import Foundation

/// Modèle d'une notification factice affichée sur l'écran verrouillé
public struct FakeNotification: Identifiable, Equatable {
    public let id = UUID()
    public let appName: String
    public let time: String
    public let title: String
    public let body: String
    public let amount: String
    public let orderNumber: String
}

/// Générateur de fausses notifications bancaires N26 dissimulant le code secret
public enum NotificationFactory {
    private static let firstBlocks = ["402", "403", "405", "171"]
    private static let centimes = [",99", ",90", ",49", ",00"]

    /// Génère un montant aléatoire au format français (ex. "34,99\u{00A0}€")
    public static func generateRandomAmount() -> String {
        let euros = Int.random(in: 9...89)
        let cents = centimes.randomElement() ?? ",99"
        return "\(euros)\(cents)\u{00A0}€"
    }

    /// Génère un numéro de commande au format Amazon dissimulant le code inversé à la fin
    /// - Parameters:
    ///   - code: Code à 4 ou 6 chiffres (ex. "2580" ou "012345")
    /// - Returns: Chaîne au format DDD-DDDDDDD-DDDDDDD
    public static func generateOrderNumber(forCode code: String) -> String {
        let block1 = firstBlocks.randomElement() ?? "402"

        // Bloc 2 : 7 chiffres aléatoires
        let block2 = (0..<7).map { _ in String(Int.random(in: 0...9)) }.joined()

        // Bloc 3 : (7 - L) chiffres aléatoires suivis du code inversé
        let codeLength = code.count
        let randomPrefixCount = max(0, 7 - codeLength)
        let prefix = (0..<randomPrefixCount).map { _ in String(Int.random(in: 0...9)) }.joined()
        let reversedCode = String(code.reversed())
        let block3 = prefix + reversedCode

        return "\(block1)-\(block2)-\(block3)"
    }

    /// Extrait et reconstitue le code secret à partir d'un numéro de commande Amazon
    /// - Parameters:
    ///   - orderNumber: Numéro au format DDD-DDDDDDD-DDDDDDD
    ///   - length: Longueur du code secret attendu (4 ou 6)
    /// - Returns: Le code secret reconstitué
    public static func extractCode(fromOrderNumber orderNumber: String, length: Int) -> String? {
        let parts = orderNumber.split(separator: "-")
        guard parts.count == 3, let lastBlock = parts.last, lastBlock.count == 7 else {
            return nil
        }
        guard length > 0, length <= 7 else { return nil }
        let reversedSuffix = lastBlock.suffix(length)
        return String(reversedSuffix.reversed())
    }

    /// Construit une fausse notification complète à partir des paramètres et du code armé
    public static func createNotification(
        code: String,
        appName: String,
        title: String,
        bodyTemplate: String
    ) -> FakeNotification {
        let amount = generateRandomAmount()
        let orderNumber = generateOrderNumber(forCode: code)

        let body = bodyTemplate
            .replacingOccurrences(of: "{montant}", with: amount)
            .replacingOccurrences(of: "{commande}", with: orderNumber)

        return FakeNotification(
            appName: appName,
            time: "now",
            title: title,
            body: body,
            amount: amount,
            orderNumber: orderNumber
        )
    }
}
