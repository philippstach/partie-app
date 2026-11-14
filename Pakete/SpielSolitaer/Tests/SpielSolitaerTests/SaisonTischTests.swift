// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

final class SaisonTischTests: XCTestCase {
    private func defaults() -> UserDefaults {
        let n = "saison-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: n)!
        d.removePersistentDomain(forName: n)
        return d
    }

    func testMonatZuJahreszeitAlle12() {
        let erwartet: [Int: TableStyle] = [1: .winter, 2: .winter, 3: .spring, 4: .spring, 5: .spring, 6: .summer, 7: .summer, 8: .summer,
                                           9: .autumn, 10: .autumn, 11: .autumn, 12: .winter]
        for (monat, stil) in erwartet { XCTAssertEqual(TableStyle.season(month: monat), stil, "Monat \(monat)") }
        XCTAssertEqual(erwartet.count, 12)
    }

    func testDatumInOrtszeit() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        // 29. Februar 23:30 Ortszeit ist noch Winter, 1. März 00:30 schon Frühling
        let feb = cal.date(from: DateComponents(year: 2028, month: 2, day: 29, hour: 23, minute: 30))!
        let mar = cal.date(from: DateComponents(year: 2028, month: 3, day: 1, hour: 0, minute: 30))!
        XCTAssertEqual(TableStyle.season(for: feb, calendar: cal), .winter)
        XCTAssertEqual(TableStyle.season(for: mar, calendar: cal), .spring)
    }

    func testStandardwerte() {
        let p = AppPreferences(defaults: defaults(), photoFolder: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        XCTAssertFalse(p.autoSeason)
        XCTAssertEqual(p.tableStyle, .linen)
        XCTAssertEqual(p.activeTable, .linen)
    }

    func testSchalterUeberschreibtDieTischwahl() {
        let p = AppPreferences(defaults: defaults(), photoFolder: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        p.tableStyle = .felt
        XCTAssertEqual(p.activeTable(on: Date(timeIntervalSince1970: 1_780_000_000)), .felt)           // Schalter aus: die Wahl
        p.autoSeason = true
        var cal = Calendar.current; cal.timeZone = .current
        let juli = cal.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 12))!
        XCTAssertEqual(p.activeTable(on: juli), .summer)
        XCTAssertEqual(p.tableStyle, .felt)                                                         // die Wahl bleibt erhalten
        p.autoSeason = false
        XCTAssertEqual(p.activeTable(on: juli), .felt)
    }

    func testSpeichernUndLaden() {
        let d = defaults()
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let a = AppPreferences(defaults: d, photoFolder: folder)
        a.tableStyle = .autumn
        a.autoSeason = true
        let b = AppPreferences(defaults: d, photoFolder: folder)
        XCTAssertEqual(b.tableStyle, .autumn)
        XCTAssertTrue(b.autoSeason)
        // unbekannter Wert → Leinen
        d.set("regenbogen", forKey: "tableStyle")
        XCTAssertEqual(AppPreferences(defaults: d, photoFolder: folder).tableStyle, .linen)
    }

    func testReihenUndNamen() {
        XCTAssertEqual(TableStyle.basic.count, 4)
        XCTAssertEqual(TableStyle.seasons, [.spring, .summer, .autumn, .winter])
        XCTAssertTrue(TableStyle.seasons.allSatisfy(\.isSeason))
        XCTAssertFalse(TableStyle.basic.contains(where: \.isSeason))
    }
}
