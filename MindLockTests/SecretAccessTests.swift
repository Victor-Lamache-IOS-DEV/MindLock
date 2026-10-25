import XCTest
@testable import MindLock

final class SecretAccessTests: XCTestCase {

    struct SecretAccessChecker {
        let expectedCode: String?
        let secretSettingsCode: String // par ex. "1111"

        func isSecretKeyCandidate(digit: Int, enteredDigits: [Int]) -> Bool {
            // Règle 1111 : 3 chiffres '1' déjà saisis et touche '1'
            guard digit == 1, enteredDigits == [1, 1, 1] else { return false }

            // Exception : si le code attendu pour déverrouiller est lui-même 1111
            if let expected = expectedCode, expected == secretSettingsCode {
                return false // Désactivé, saisie normale
            }

            return true
        }
    }

    func testSecret1111TriggerEnabledWhenExpectedCodeIsDifferent() {
        let checker = SecretAccessChecker(expectedCode: "2580", secretSettingsCode: "1111")

        // 3 chiffres '1' saisis, appui sur '1' : candidat secret détecté
        XCTAssertTrue(checker.isSecretKeyCandidate(digit: 1, enteredDigits: [1, 1, 1]))

        // Pas assez de chiffres '1'
        XCTAssertFalse(checker.isSecretKeyCandidate(digit: 1, enteredDigits: [1, 1]))
        XCTAssertFalse(checker.isSecretKeyCandidate(digit: 1, enteredDigits: []))

        // Chiffres différents
        XCTAssertFalse(checker.isSecretKeyCandidate(digit: 1, enteredDigits: [2, 5, 8]))
        XCTAssertFalse(checker.isSecretKeyCandidate(digit: 2, enteredDigits: [1, 1, 1]))
    }

    func testSecret1111ExceptionWhenExpectedCodeIs1111() {
        // Le code attendu est 1111 (reçu au volume ou défini par défaut)
        let checker = SecretAccessChecker(expectedCode: "1111", secretSettingsCode: "1111")

        // La règle secrète doit être désactivée pour permettre le déverrouillage normal
        let isCandidate = checker.isSecretKeyCandidate(digit: 1, enteredDigits: [1, 1, 1])
        XCTAssertFalse(isCandidate, "Secret hold interception must be disabled when expected unlock code is 1111")
    }
}
