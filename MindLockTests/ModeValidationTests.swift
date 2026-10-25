import XCTest
@testable import MindLock

final class ModeValidationTests: XCTestCase {

    struct PasscodeValidator {
        let mode: TrickMode
        let defaultCode: String
        let armedCode: String?
        let firstAttemptFails: Bool
        var isFirstAttempt: Bool = true

        var expectedCode: String? {
            switch mode {
            case .coincidence, .mind:
                return armedCode ?? defaultCode
            case .anyCode:
                return nil
            case .normal:
                return defaultCode
            }
        }

        var targetLength: Int {
            switch mode {
            case .coincidence, .mind:
                return (armedCode ?? defaultCode).count
            case .anyCode:
                return armedCode?.count ?? 4
            case .normal:
                return defaultCode.count
            }
        }

        mutating func validate(enteredCode: String) -> Bool {
            guard enteredCode.count == targetLength else { return false }

            if firstAttemptFails && isFirstAttempt {
                isFirstAttempt = false
                return false
            }

            if mode == .anyCode {
                return true
            } else if let expected = expectedCode {
                return (enteredCode == expected)
            } else {
                return false
            }
        }
    }

    func testCoincidenceModeWithArmedCode() {
        var validator = PasscodeValidator(
            mode: .coincidence,
            defaultCode: "2580",
            armedCode: "1234",
            firstAttemptFails: false
        )

        XCTAssertEqual(validator.expectedCode, "1234")
        XCTAssertEqual(validator.targetLength, 4)

        XCTAssertFalse(validator.validate(enteredCode: "2580"))
        XCTAssertFalse(validator.validate(enteredCode: "9999"))
        XCTAssertTrue(validator.validate(enteredCode: "1234"))
    }

    func testCoincidenceModeFallbackToDefault() {
        var validator = PasscodeValidator(
            mode: .coincidence,
            defaultCode: "2580",
            armedCode: nil,
            firstAttemptFails: false
        )

        XCTAssertEqual(validator.expectedCode, "2580")
        XCTAssertEqual(validator.targetLength, 4)

        XCTAssertFalse(validator.validate(enteredCode: "1234"))
        XCTAssertTrue(validator.validate(enteredCode: "2580"))
    }

    func testAnyCodeMode() {
        var validator = PasscodeValidator(
            mode: .anyCode,
            defaultCode: "2580",
            armedCode: "123456", // Longueur 6
            firstAttemptFails: false
        )

        XCTAssertEqual(validator.targetLength, 6)
        XCTAssertNil(validator.expectedCode)

        // Tout code de longueur 6 est accepté
        XCTAssertTrue(validator.validate(enteredCode: "000000"))
        XCTAssertTrue(validator.validate(enteredCode: "987654"))
        XCTAssertTrue(validator.validate(enteredCode: "111111"))
    }

    func testNormalModeIgnoresArmedCode() {
        var validator = PasscodeValidator(
            mode: .normal,
            defaultCode: "2580",
            armedCode: "9999", // Doit être ignoré
            firstAttemptFails: false
        )

        XCTAssertEqual(validator.expectedCode, "2580")
        XCTAssertFalse(validator.validate(enteredCode: "9999"))
        XCTAssertTrue(validator.validate(enteredCode: "2580"))
    }

    func testFirstAttemptFailsOption() {
        var validator = PasscodeValidator(
            mode: .coincidence,
            defaultCode: "2580",
            armedCode: "2580",
            firstAttemptFails: true,
            isFirstAttempt: true
        )

        // 1er essai avec le bon code : doit échouer
        let attempt1 = validator.validate(enteredCode: "2580")
        XCTAssertFalse(attempt1, "First attempt must fail when option is enabled")

        // 2e essai avec le bon code : doit réussir
        let attempt2 = validator.validate(enteredCode: "2580")
        XCTAssertTrue(attempt2, "Second attempt must succeed")
    }
}
