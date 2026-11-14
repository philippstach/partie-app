// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// S3: Einstellung „Partie abbrechen“ – nie (Standard), gegen den Computer, immer.
final class AbbruchWertungTests: XCTestCase {
    private let allein = [(name: "Anna", computer: false)]
    private let gegenComputer = [(name: "Anna", computer: false), (name: "Computer", computer: true)]
    private let zweiMenschen = [(name: "Anna", computer: false), (name: "Ben", computer: false)]

    private func buchung(_ w: AbbruchWertung, _ t: [(name: String, computer: Bool)], begonnen: Bool = true, kinder: Bool = false, arcade: Bool = false) -> PartieErgebnis? {
        PartieMeldung.abbruchBuchung(begonnen: begonnen, spiel: "t", teilnehmer: t, wertung: w, kinder: kinder, arcade: arcade)
    }

    func testStandardIstNie() {
        let d = UserDefaults(suiteName: "abbruch.tests")!; d.removePersistentDomain(forName: "abbruch.tests")
        XCTAssertEqual(AbbruchWertung.gespeichert(d), .nie)
        d.set("immer", forKey: AbbruchWertung.schluessel); XCTAssertEqual(AbbruchWertung.gespeichert(d), .immer)
        d.set("quatsch", forKey: AbbruchWertung.schluessel); XCTAssertEqual(AbbruchWertung.gespeichert(d), .nie)
    }

    func testNieBuchtNichts() {
        XCTAssertNil(buchung(.nie, allein)); XCTAssertNil(buchung(.nie, gegenComputer)); XCTAssertNil(buchung(.nie, zweiMenschen))
    }

    func testComputerBuchtNurMitComputerAmTisch() {
        XCTAssertEqual(buchung(.computer, gegenComputer)?.teilnehmer.map(\.platz), [2, 1], "Mensch verliert, Computer vorn")
        XCTAssertNil(buchung(.computer, allein)); XCTAssertNil(buchung(.computer, zweiMenschen))
    }

    func testImmerBuchtAuchAlleinUndUnterMenschen() {
        let e = buchung(.immer, allein)
        XCTAssertEqual(e?.teilnehmer.map(\.platz), [2], "allein: verloren wie die S1-Buchung")
        XCTAssertEqual(e?.teilnehmer.map(\.platz), EndeBuchung.teilnehmer(reihenfolge: ["Anna"], einzel: .verloren).map(\.platz))
        XCTAssertEqual(buchung(.immer, zweiMenschen)?.teilnehmer.map(\.platz), [2, 2], "niemand gewinnt, kein Remis")
        XCTAssertEqual(buchung(.immer, zweiMenschen)?.istAbbruch, true)
        XCTAssertNotNil(buchung(.immer, gegenComputer))
    }

    func testNichtBegonneneParteiZaehltNie() {
        for w in AbbruchWertung.allCases { XCTAssertNil(buchung(w, gegenComputer, begonnen: false), "\(w)") }
    }

    func testKinderModusUndArcadeBuchenNie() {
        for w in AbbruchWertung.allCases {
            XCTAssertNil(buchung(w, gegenComputer, kinder: true), "\(w)")
            XCTAssertNil(buchung(w, gegenComputer, arcade: true), "\(w)")
        }
    }

    /// Die Vorwarnung „Das zählt als Niederlage.“ in der Abfrage hängt an genau dieser Buchung (nil = keine Warnung).
    func testVorwarnungNurWennWirklichGebuchtWird() {
        var warnungen = 0, faelle = 0
        for w in AbbruchWertung.allCases { for t in [allein, gegenComputer, zweiMenschen] { for begonnen in [false, true] { for kinder in [false, true] { for arcade in [false, true] {
            let computer = t.filter(\.computer).count
            let erwartet = w.bucht(begonnen: begonnen, menschen: t.count - computer, computer: computer, kinder: kinder, arcade: arcade)
            XCTAssertEqual(buchung(w, t, begonnen: begonnen, kinder: kinder, arcade: arcade) != nil, erwartet)
            faelle += 1; if erwartet { warnungen += 1 }
        } } } } }
        XCTAssertEqual(faelle, 72)
        XCTAssertEqual(warnungen, 4, "nur: computer+gegenComputer, immer+allein, immer+gegenComputer, immer+zweiMenschen – je begonnen, ohne Kinder-Modus, ohne Arcade")
    }

    func testOhneMenschenWirdNieGebucht() {
        XCTAssertNil(buchung(.immer, [(name: "Computer", computer: true)]))
    }

    func testBegonnen() {
        XCTAssertFalse(AbbruchWertung.begonnen(hatZug: false, fortgesetzt: false, spielzeit: 5), "sofort wieder beendet")
        XCTAssertFalse(AbbruchWertung.begonnen(hatZug: false, fortgesetzt: false, spielzeit: AbbruchWertung.mindestSpielzeit - 0.1))
        XCTAssertTrue(AbbruchWertung.begonnen(hatZug: false, fortgesetzt: false, spielzeit: AbbruchWertung.mindestSpielzeit))
        XCTAssertTrue(AbbruchWertung.begonnen(hatZug: true, fortgesetzt: false, spielzeit: 0), "gemeldeter Zug")
        XCTAssertTrue(AbbruchWertung.begonnen(hatZug: false, fortgesetzt: true, spielzeit: 0), "fortgesetzter Stand")
        XCTAssertFalse(AbbruchWertung.begonnen(hatZug: false, fortgesetzt: false, spielzeit: .nan))
    }

    func testSpieluhrZaehltHintergrundUndPauseNichtMit() {
        let t0 = Date(timeIntervalSince1970: 1000)
        var u = Spieluhr()
        XCTAssertEqual(u.zeit(t0), 0)
        u.starten(t0)
        XCTAssertEqual(u.zeit(t0.addingTimeInterval(8)), 8)
        u.anhalten(t0.addingTimeInterval(8))                       // App in den Hintergrund
        XCTAssertEqual(u.zeit(t0.addingTimeInterval(500)), 8, "Zeit im Hintergrund zählt nicht")
        u.weiter(t0.addingTimeInterval(500)); u.weiter(t0.addingTimeInterval(505))   // doppeltes „weiter“ ändert nichts
        XCTAssertEqual(u.zeit(t0.addingTimeInterval(510)), 18)
        u.anhalten(t0.addingTimeInterval(510)); u.anhalten(t0.addingTimeInterval(600))
        XCTAssertEqual(u.zeit(t0.addingTimeInterval(700)), 18)
        u.starten(t0.addingTimeInterval(700))                      // neue Partie beginnt bei null
        XCTAssertEqual(u.zeit(t0.addingTimeInterval(703)), 3)
    }
}
