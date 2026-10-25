import XCTest
@testable import MindLock

@MainActor
final class VolumeInputLogicTests: XCTestCase {

    func testSequence2580ByDirectionSwitching() {
        let engine = VolumeInputLogicEngine(digitCommitTimeout: 10, codeCompletionTimeout: 10, hapticPerDigit: true)

        var committedDigits: [Int] = []
        engine.onDigitCommitted = {
            if let last = engine.pendingDigits.last {
                committedDigits.append(last)
            }
        }

        // Chiffre 2 (2 appuis sur +)
        engine.registerPress(direction: .up)
        engine.registerPress(direction: .up)

        // Changement de direction vers - : valide immédiatement le 2 et commence le chiffre suivant
        engine.registerPress(direction: .down) // 1er appui sur -
        engine.registerPress(direction: .down)
        engine.registerPress(direction: .down)
        engine.registerPress(direction: .down)
        engine.registerPress(direction: .down) // Total 5 appuis sur -

        // Changement vers + : valide immédiatement le 5
        engine.registerPress(direction: .up) // 1er appui sur +
        for _ in 0..<7 {
            engine.registerPress(direction: .up) // Total 8 appuis sur +
        }

        // Changement vers - : valide immédiatement le 8
        engine.registerPress(direction: .down) // 1er appui sur -
        for _ in 0..<9 {
            engine.registerPress(direction: .down) // Total 10 appuis sur -
        }

        // Validation finale de la série en cours (10 appuis = 0)
        engine.commitCurrentSeries()

        XCTAssertEqual(committedDigits, [2, 5, 8, 0])
        XCTAssertEqual(engine.pendingDigits, [2, 5, 8, 0])
    }

    func testConsecutiveIdenticalDigits3333() {
        let engine = VolumeInputLogicEngine(digitCommitTimeout: 10, codeCompletionTimeout: 10, hapticPerDigit: false)

        for _ in 0..<4 {
            for _ in 0..<3 {
                engine.registerPress(direction: .up)
            }
            // Validation par pause d'inactivité (appel de commitCurrentSeries)
            engine.commitCurrentSeries()
        }

        XCTAssertEqual(engine.pendingDigits, [3, 3, 3, 3])
    }

    func testDigitZeroTenPresses() {
        let engine = VolumeInputLogicEngine(digitCommitTimeout: 10, codeCompletionTimeout: 10, hapticPerDigit: false)

        for _ in 0..<4 {
            for _ in 0..<10 {
                engine.registerPress(direction: .down)
            }
            engine.commitCurrentSeries()
        }

        XCTAssertEqual(engine.pendingDigits, [0, 0, 0, 0])
    }

    func testAbortOnHeldButtonOverTwelvePresses() {
        let engine = VolumeInputLogicEngine(digitCommitTimeout: 10, codeCompletionTimeout: 10, hapticPerDigit: false)

        var didTriggerHeldClear = false
        engine.onHeldClear = {
            didTriggerHeldClear = true
        }

        // Saisir d'abord un premier chiffre valide
        engine.registerPress(direction: .up)
        engine.registerPress(direction: .up)
        engine.commitCurrentSeries()
        XCTAssertEqual(engine.pendingDigits.count, 1)

        // Simuler un bouton maintenu enfoncé (> 12 appuis consécutifs)
        for _ in 0..<13 {
            engine.registerPress(direction: .down)
        }

        XCTAssertTrue(didTriggerHeldClear, "Should trigger held clear on > 12 presses")
        XCTAssertEqual(engine.pendingDigits.count, 0, "Pending digits must be cleared on abort")
        XCTAssertEqual(engine.currentSeriesPresses, 0)
        XCTAssertNil(engine.currentDirection)
    }

    func testFlushOnSwipeUpToPasscode() {
        let engine = VolumeInputLogicEngine(digitCommitTimeout: 10, codeCompletionTimeout: 10, hapticPerDigit: false)

        var acceptedCode: String?
        engine.onCodeAccepted = { code in
            acceptedCode = code
        }

        // Saisir 2 sur +
        engine.registerPress(direction: .up)
        engine.registerPress(direction: .up)

        // Saisir 5 sur -
        engine.registerPress(direction: .down)
        for _ in 0..<4 { engine.registerPress(direction: .down) }

        // Saisir 8 sur +
        engine.registerPress(direction: .up)
        for _ in 0..<7 { engine.registerPress(direction: .up) }

        // Saisir 10 sur - (en cours, pas encore validé par timeout)
        engine.registerPress(direction: .down)
        for _ in 0..<9 { engine.registerPress(direction: .down) }

        // Swipe up immédiat -> appel de flush()
        engine.flush()

        XCTAssertEqual(engine.armedCode, "2580")
        XCTAssertEqual(acceptedCode, "2580")
        XCTAssertEqual(engine.pendingDigits.count, 0)
    }

    func testInvalidLengthRejectedSilentlyOnFlush() {
        let engine = VolumeInputLogicEngine(digitCommitTimeout: 10, codeCompletionTimeout: 10, hapticPerDigit: false)

        // Saisir seulement 3 chiffres
        for _ in 0..<3 {
            engine.registerPress(direction: .up)
            engine.commitCurrentSeries()
        }

        engine.flush()

        XCTAssertNil(engine.armedCode, "Code of length 3 must not be armed")
        XCTAssertEqual(engine.pendingDigits.count, 0)
    }
}
