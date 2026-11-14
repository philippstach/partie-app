// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer
import SpieleKern

@MainActor
final class StatsTests: XCTestCase {
    private let one = DealInfo(seed: 2, draw: 1, kind: .solvable)
    private let three = DealInfo(seed: 5, draw: 3, kind: .solvable)

    func testGetrenntNachZiehArt() {
        let s = StatsStore(url: nil)
        s.handle(.started(one)); s.handle(.won(one, moves: 100, score: 500, seconds: 200))
        s.handle(.started(three))
        XCTAssertEqual(s.stats(draw: 1).played, 1)
        XCTAssertEqual(s.stats(draw: 1).won, 1)
        XCTAssertEqual(s.stats(draw: 3).played, 1)
        XCTAssertEqual(s.stats(draw: 3).won, 0)
        XCTAssertEqual(s.stats(draw: 1).winRate, 100)
    }

    func testSerieEndetBeimVerlassenEinerAngefangenenPartie() {
        let s = StatsStore(url: nil)
        for _ in 0..<3 { s.handle(.started(one)); s.handle(.won(one, moves: 90, score: 400, seconds: 100)) }
        XCTAssertEqual(s.stats(draw: 1).streak, 3)
        s.handle(.started(one))
        s.handle(.abandoned(one))
        XCTAssertEqual(s.stats(draw: 1).streak, 0)
        XCTAssertEqual(s.stats(draw: 1).bestStreak, 3)
    }

    /// C-037: „Solitär“ meldet aufgegebene Partien als Niederlage unter der eigenen Kennung, Siege meldet der Rahmen.
    func testNeuMeldetNiederlageUnterEigenerKennung() async {
        let alt = PartieMeldung.senke
        defer { PartieMeldung.senke = alt }
        var erhalten: [PartieErgebnis] = []
        let ex = expectation(description: "Meldung")
        PartieMeldung.senke = { erhalten.append($0); ex.fulfill() }
        let s = StatsStore(url: nil)
        s.meldeKennung = "solitaer-neu"; s.meldeName = "Anna"
        s.handle(.won(one, moves: 100, score: 500, seconds: 200))      // Sieg: keine Meldung (macht der Rahmen)
        s.handle(.abandoned(one))
        await fulfillment(of: [ex], timeout: 2)
        XCTAssertEqual(erhalten.count, 1)
        XCTAssertEqual(erhalten.first?.spiel, "solitaer-neu")
        XCTAssertEqual(erhalten.first?.teilnehmer.first?.name, "Anna")
        XCTAssertEqual(erhalten.first?.teilnehmer.first?.platz, 2)
    }

    func testRekordeNurWennVorherEinWertDa() {
        let s = StatsStore(url: nil)
        s.handle(.won(one, moves: 100, score: 500, seconds: 200))
        XCTAssertFalse(s.lastRecords.any)                      // erster Sieg: nichts zu schlagen
        s.handle(.won(one, moves: 90, score: 450, seconds: 250))
        XCTAssertEqual(s.lastRecords, NewRecords(bestTime: false, fewestMoves: true, highScore: false))
        XCTAssertEqual(s.stats(draw: 1).bestTime, 200)
        XCTAssertEqual(s.stats(draw: 1).fewestMoves, 90)
        XCTAssertEqual(s.stats(draw: 1).highScore, 500)
    }

    func testTagesspielUndTagesSerie() {
        let s = StatsStore(url: nil)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2026, month: 10, day: 4))!
        for d in ["2026-10-02", "2026-10-03"] {
            let deal = DealInfo(seed: 1, draw: 1, kind: .daily, day: d)
            s.handle(.started(deal)); s.handle(.won(deal, moves: 100, score: 100, seconds: 100))
        }
        XCTAssertEqual(s.dailyStreak(today: today, calendar: cal), 2)    // heute noch offen: zählt bis gestern
        let heute = DealInfo(seed: 1, draw: 1, kind: .daily, day: "2026-10-04")
        s.handle(.won(heute, moves: 100, score: 100, seconds: 100))
        XCTAssertEqual(s.dailyStreak(today: today, calendar: cal), 3)
        XCTAssertEqual(s.data.dailyWon.count, 3)
    }

    func testSpeichernLadenUndFehlendeFelder() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "stat-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let s = StatsStore(url: url)
        s.handle(.started(one)); s.handle(.won(one, moves: 80, score: 600, seconds: 150))
        XCTAssertEqual(StatsStore(url: url).data, s.data)
        // alte/halbe Datei: fehlende Felder → Standardwert
        try Data("{\"one\":{\"played\":4}}".utf8).write(to: url)
        let alt = StatsStore(url: url)
        XCTAssertEqual(alt.stats(draw: 1).played, 4)
        XCTAssertEqual(alt.stats(draw: 3).played, 0)
        XCTAssertTrue(alt.data.dailyWon.isEmpty)
    }

    func testZuruecksetzenNurEineZiehArt() {
        let s = StatsStore(url: nil)
        s.handle(.started(one)); s.handle(.started(three))
        s.reset(draw: 3)
        XCTAssertEqual(s.stats(draw: 1).played, 1)
        XCTAssertEqual(s.stats(draw: 3).played, 0)
    }
}

@MainActor
final class StatsSerieTests: XCTestCase {
    func testBesteTagesSerie() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let s = StatsStore(url: nil)
        var d = StatsData()
        d.dailyWon = ["2026-09-30", "2026-10-01", "2026-10-02", "2026-10-05", "2026-10-06"]   // Folge über den Monatswechsel: 3
        s.load(d)
        XCTAssertEqual(s.bestDailyStreak(calendar: cal), 3)
        s.load(StatsData())
        XCTAssertEqual(s.bestDailyStreak(calendar: cal), 0)
    }
}
