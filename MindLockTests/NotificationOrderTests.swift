import XCTest
@testable import MindLock

final class NotificationOrderTests: XCTestCase {

    func testExtractCodeFourDigits() {
        let testCodes = ["2580", "0123", "0000", "9876", "0505"]

        for code in testCodes {
            let orderNumber = NotificationFactory.generateOrderNumber(forCode: code)
            let extracted = NotificationFactory.extractCode(fromOrderNumber: orderNumber, length: 4)
            XCTAssertEqual(extracted, code, "Extraction failed for 4-digit code: \(code) from order: \(orderNumber)")
        }
    }

    func testExtractCodeSixDigits() {
        let testCodes = ["123456", "001234", "000000", "654321", "909090"]

        for code in testCodes {
            let orderNumber = NotificationFactory.generateOrderNumber(forCode: code)
            let extracted = NotificationFactory.extractCode(fromOrderNumber: orderNumber, length: 6)
            XCTAssertEqual(extracted, code, "Extraction failed for 6-digit code: \(code) from order: \(orderNumber)")
        }
    }

    func testOrderNumberFormat() {
        let orderNumber = NotificationFactory.generateOrderNumber(forCode: "2580")
        let components = orderNumber.split(separator: "-")
        XCTAssertEqual(components.count, 3, "Order number should have 3 segments separated by hyphens")
        XCTAssertEqual(components[0].count, 3, "First segment should be 3 digits")
        XCTAssertEqual(components[1].count, 7, "Second segment should be 7 digits")
        XCTAssertEqual(components[2].count, 7, "Third segment should be 7 digits")

        let allowedPrefixes = ["402", "403", "405", "171"]
        XCTAssertTrue(allowedPrefixes.contains(String(components[0])), "Prefix should be from allowed set")
    }

    func testRandomAmountFormat() {
        for _ in 0..<50 {
            let amount = NotificationFactory.generateRandomAmount()
            XCTAssertTrue(amount.hasSuffix("\u{00A0}€"), "Amount should end with non-breaking space and euro symbol: \(amount)")

            let trimmed = amount.replacingOccurrences(of: "\u{00A0}€", with: "")
            let parts = trimmed.split(separator: ",")
            XCTAssertEqual(parts.count, 2, "Amount should have integer and decimal parts")

            if let euros = Int(parts[0]) {
                XCTAssertGreaterThanOrEqual(euros, 9)
                XCTAssertLessThanOrEqual(euros, 89)
            } else {
                XCTFail("Euros not integer: \(parts[0])")
            }

            let validCents = ["99", "90", "49", "00"]
            XCTAssertTrue(validCents.contains(String(parts[1])), "Centimes should be valid: \(parts[1])")
        }
    }

    func testFullNotificationCreation() {
        let notif = NotificationFactory.createNotification(
            code: "2580",
            appName: "N26",
            title: "Remboursement reçu",
            bodyTemplate: "Vous avez reçu {montant} de AMAZON EU SARL – commande n° {commande}"
        )

        XCTAssertEqual(notif.appName, "N26")
        XCTAssertEqual(notif.title, "Remboursement reçu")
        XCTAssertFalse(notif.body.contains("{montant}"))
        XCTAssertFalse(notif.body.contains("{commande}"))

        let extracted = NotificationFactory.extractCode(fromOrderNumber: notif.orderNumber, length: 4)
        XCTAssertEqual(extracted, "2580")
    }
}
