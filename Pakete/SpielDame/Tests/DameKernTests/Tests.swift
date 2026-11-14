// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import DameKern

final class DameTests: XCTestCase {
    func testStart() {
        let d = Dame(); XCTAssertEqual(d.steine(1), 12); XCTAssertEqual(d.steine(2), 12); XCTAssertEqual(d.zuege.count, 7)
    }
    func testSchlagzwangUndGleichgueltigeZuege() {
        var d = Dame()
        // Weiß 41 → 32, Schwarz 21 → 30? einfachster Test: nur gültige Züge sind erlaubt
        let z = d.zuege.first!
        XCTAssertTrue(d.spiele(z)); XCTAssertEqual(d.dran, 2)
        XCTAssertFalse(d.spiele(DamenZug(pfad: [0, 9], geschlagen: [])))
    }
    func testSchlagzwangUndMehrfachsprung() {
        var b = [Int](repeating: 0, count: 64)
        b[5 * 8 + 2] = 1           // Weiß-Mann
        b[4 * 8 + 3] = 2           // Schwarz, schlagbar
        b[2 * 8 + 5] = 2           // zweiter Schwarzer, danach schlagbar
        b[0 * 8 + 1] = 2
        let d = Dame(brett: b, dran: 1)
        XCTAssertTrue(d.zuege.allSatisfy { !$0.geschlagen.isEmpty })     // Zwang
        XCTAssertTrue(d.zuege.contains { $0.geschlagen.count == 2 && $0.ziel == 1 * 8 + 6 })
    }
    func testDameFliegtUndWirdKrone() {
        var b = [Int](repeating: 0, count: 64)
        b[1 * 8 + 2] = 1
        var d = Dame(brett: b, dran: 1)
        XCTAssertTrue(d.spiele(DamenZug(pfad: [1 * 8 + 2, 0 * 8 + 1], geschlagen: [])))
        XCTAssertEqual(d.brett[1], 3)
        var b2 = [Int](repeating: 0, count: 64); b2[7 * 8 + 0] = 3
        let k = Dame(brett: b2, dran: 1)
        XCTAssertTrue(k.zuege.contains { $0.ziel == 0 * 8 + 7 })           // fliegt die ganze Diagonale
    }
    func testComputerSpieltLegal() {
        var d = Dame(); var n = 0
        while d.sieger == nil && n < 200 { guard let z = DameComputer.wahl(d, tiefe: 2) else { break }; XCTAssertTrue(d.spiele(z)); n += 1 }
        XCTAssertTrue(n > 10)
    }
    func testRemisNachRuhigenZuegen() {
        // Zwei Damen gegen zwei Damen, die sich nie erreichen können
        var b = [Int](repeating: 0, count: 64)
        b[56] = 3; b[2] = 4          // Dame unten links, Dame oben rechts
        var d = Dame(brett: b, dran: 1)
        var n = 0
        while !d.vorbei && n < 500 { d.spiele(d.zuege.first!); n += 1 }
        XCTAssertTrue(d.remis || d.sieger != nil)
    }
}

final class DameRegelnTests: XCTestCase {
    func testEnglischDameZiehtNurEinFeld() {
        var b = [Int](repeating: 0, count: 64); b[3 * 8 + 3] = 3
        let d = Dame(brett: b, dran: 1, regeln: .englisch)
        XCTAssertEqual(d.zuege.count, 4)
        XCTAssertEqual(Dame(brett: b, dran: 1).zuege.count, 13)
    }
    func testEnglischMannSchlagtNichtRueckwaerts() {
        var b = [Int](repeating: 0, count: 64); b[3 * 8 + 3] = 1; b[4 * 8 + 4] = 2   // Gegner hinter dem weißen Mann
        XCTAssertFalse(Dame(brett: b, dran: 1, regeln: .englisch).zuege.contains { !$0.geschlagen.isEmpty })
        XCTAssertTrue(Dame(brett: b, dran: 1).zuege.contains { !$0.geschlagen.isEmpty })
    }
    func testKeinSchlagzwang() {
        var b = [Int](repeating: 0, count: 64); b[5 * 8 + 2] = 1; b[4 * 8 + 3] = 2; b[7 * 8 + 0] = 1
        let d = Dame(brett: b, dran: 1, regeln: .locker)
        XCTAssertTrue(d.zuege.contains { $0.geschlagen.isEmpty }); XCTAssertTrue(d.zuege.contains { !$0.geschlagen.isEmpty })
        XCTAssertTrue(Dame(brett: b, dran: 1).zuege.allSatisfy { !$0.geschlagen.isEmpty })
    }
    func testAlterSpielstandLaedt() throws {
        let json = #"{"brett":\#(Dame().brett),"dran":1,"ruhigeZuege":0}"#
        let d = try JSONDecoder().decode(Dame.self, from: Data(json.utf8))
        XCTAssertEqual(d.regeln, .deutsch)
    }
}

import SpieleKern
final class DameAbbruchTests: XCTestCase {
    /// „Beenden“ nach dem ersten Zug zählt als Niederlage des Menschen; ohne gemeldeten Zug zählt es nichts.
    @MainActor func testBeendenNachErstemZugIstEineNiederlage() {
        XCTAssertFalse(SpielZug.hatZug("dame"))
        SpielZug.gemacht("dame")
        XCTAssertTrue(SpielZug.hatZug("dame"))
        let e = PartieMeldung.abbruch(spiel: "dame", teilnehmer: [("Ich", false), ("Computer", true)])
        XCTAssertEqual(e?.teilnehmer.first { $0.name == "Ich" }?.platz, 2)
        XCTAssertEqual(e?.teilnehmer.first { $0.name == "Computer" }?.platz, 1)
        XCTAssertEqual(e?.istRemis, false)
    }
}
