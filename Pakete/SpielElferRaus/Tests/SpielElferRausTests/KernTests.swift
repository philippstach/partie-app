// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielElferRaus

struct Saat: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s ^ (s >> 29) }
}

final class KernTests: XCTestCase {
    func neu(_ n: Int, _ r: ErRegeln, _ seed: UInt64 = 1) -> ErSpiel { var g = Saat(s: seed); return ErSpiel(spieler: n, regeln: r, mit: &g) }

    /// RT-003: Der automatische Startzug sperrt Variantenwahl und Neuverteilung nicht.
    func testStartzugSperrtVarianteNicht() {
        for r in [ErRegeln.echt, ErRegeln.kartendomino] {
            for seed in 1...20 as ClosedRange<UInt64> {
                var s = neu(3, r, seed)
                XCTAssertLessThanOrEqual(s.verlauf.count, 1)
                XCTAssertTrue(s.vorErstemEigenenZug, "Nur der Startzug liegt: Variante bleibt wählbar")
                if let k = s.moegliche.first, s.lege(k) { XCTAssertEqual(s.vorErstemEigenenZug, s.verlauf.count <= 1) }
            }
        }
    }

    func testBlattGroessen() {
        XCTAssertEqual(ErRegeln.echt.blatt.count, 80)
        XCTAssertEqual(Set(ErRegeln.echt.blatt).count, 80)
        XCTAssertEqual(ErRegeln.kartendomino.blatt.count, 32)
    }

    func testAustreilenEchtMitStapel() {
        let s = neu(3, .echt)
        let imSpiel = s.haende.reduce(0) { $0 + $1.count } + s.stapel.count + s.reihen.compactMap { $0 }.count
        XCTAssertEqual(imSpiel, 80)
        XCTAssertNotNil(s.reihen[0], "Rote 11 liegt zu Beginn")
        XCTAssertEqual(s.reihen[0], 11...11)
    }

    func testDominoTeiltAllesAus() {
        for seed in 1...10 as ClosedRange<UInt64> {
            let s = neu(4, .kartendomino, seed)
            XCTAssertEqual(s.haende.reduce(0) { $0 + $1.count } + 1, 32)
            XCTAssertTrue(s.stapel.isEmpty)
            XCTAssertEqual(s.reihen[2], 11...11)
        }
    }

    func testAnlegenRegeln() {
        let s = ErSpiel(regeln: .echt, haende: [[ErKarte(0, 12), ErKarte(0, 14), ErKarte(1, 11), ErKarte(1, 5)], [ErKarte(2, 1)]],
                        reihen: [11...11, nil, nil, nil], dran: 0)
        XCTAssertTrue(s.darfAnlegen(ErKarte(0, 12)))
        XCTAssertTrue(s.darfAnlegen(ErKarte(0, 10)))
        XCTAssertFalse(s.darfAnlegen(ErKarte(0, 14)))
        XCTAssertTrue(s.darfAnlegen(ErKarte(1, 11)), "Jede 11 eröffnet ihre Farbe")
        XCTAssertFalse(s.darfAnlegen(ErKarte(1, 5)))
        XCTAssertFalse(s.darfAnlegen(ErKarte(2, 21)))
    }

    func testMehrereKartenJeZug() {
        var s = ErSpiel(regeln: .echt, haende: [[ErKarte(0, 12), ErKarte(0, 13), ErKarte(0, 3)], [ErKarte(2, 1)]], reihen: [11...11, nil, nil, nil], dran: 0)
        XCTAssertTrue(s.lege(ErKarte(0, 12))); XCTAssertEqual(s.dran, 0)
        XCTAssertTrue(s.lege(ErKarte(0, 13))); XCTAssertEqual(s.dran, 0)
        XCTAssertEqual(s.reihen[0], 11...13)
        XCTAssertTrue(s.kannBeenden)
        XCTAssertTrue(s.beende()); XCTAssertEqual(s.dran, 1)
        XCTAssertFalse(s.beende(), "Nichts gelegt: nicht beenden")
    }

    func testEineKarteJeZugImKartendomino() {
        var s = ErSpiel(regeln: .kartendomino, haende: [[ErKarte(2, 12), ErKarte(2, 13)], [ErKarte(0, 9)]], reihen: [nil, nil, 11...11, nil], dran: 0)
        XCTAssertTrue(s.lege(ErKarte(2, 12)))
        XCTAssertEqual(s.dran, 1)
    }

    func testZiehenStattPassenUndPasst() {
        var s = ErSpiel(regeln: .echt, haende: [[ErKarte(1, 3)], [ErKarte(0, 12)]], stapel: [ErKarte(3, 2), ErKarte(2, 11)], reihen: [11...11, nil, nil, nil], dran: 0)
        XCTAssertTrue(s.kannZiehenOderPassen)
        XCTAssertTrue(s.ziehenOderPassen())          // zieht 2. Stapelkarte = Herz... (letzte Karte) 
        XCTAssertEqual(s.haende[0].count, 2)
        XCTAssertEqual(s.dran, 0, "Gezogene 11 passt: weiter am Zug")
        XCTAssertFalse(s.kannZiehenOderPassen)
        XCTAssertTrue(s.lege(ErKarte(2, 11)))
    }

    func testPassenGesperrtSolangeKartePasst() {
        var s = ErSpiel(regeln: .echt, haende: [[ErKarte(0, 12)], [ErKarte(1, 3)]], stapel: [ErKarte(3, 2)], reihen: [11...11, nil, nil, nil], dran: 0)
        XCTAssertFalse(s.ziehenOderPassen())
    }

    func testPassenOhneZiehenRegel() {
        var s = ErSpiel(regeln: .kartendomino, haende: [[ErKarte(1, 8)], [ErKarte(0, 9)]], reihen: [nil, nil, 11...11, nil], dran: 0)
        XCTAssertTrue(s.ziehenOderPassen()); XCTAssertEqual(s.dran, 1)
    }

    func testSiegBeendetRundeUndWertung() {
        var s = ErSpiel(regeln: .echt, haende: [[ErKarte(0, 12)], [ErKarte(3, 20), ErKarte(1, 4)], [ErKarte(2, 1)]], reihen: [11...11, nil, nil, nil], dran: 0)
        XCTAssertTrue(s.lege(ErKarte(0, 12)))
        XCTAssertTrue(s.rundeBeendet); XCTAssertEqual(s.sieger, 0)
        XCTAssertEqual(s.rest, [0, 24, 1])
        XCTAssertEqual(s.rangfolge, [0, 2, 1])
        XCTAssertFalse(s.lege(ErKarte(0, 10)))
    }

    func testFestgefahrenEndetMitGeringstemRest() {
        var s = ErSpiel(regeln: .kartendomino, haende: [[ErKarte(1, 8)], [ErKarte(1, 7), ErKarte(1, 9)]], reihen: [nil, nil, 11...11, nil], dran: 0)
        XCTAssertTrue(s.ziehenOderPassen()); XCTAssertTrue(s.ziehenOderPassen())
        XCTAssertTrue(s.rundeBeendet); XCTAssertEqual(s.sieger, 0)
    }

    func testComputerSpieltPartienZuEnde() {
        for variante in ErVariante.allCases {
            for seed in 1...20 as ClosedRange<UInt64> {
                var g = Saat(s: seed)
                var s = ErSpiel(spieler: 2 + Int(seed % 4), regeln: .fuer(variante), mit: &g)
                var schritte = 0
                while !s.rundeBeendet && schritte < 5000 {
                    let a = s.computerSchritt(fehler: seed % 3 == 0 ? 0.3 : 0, mit: &g)
                    XCTAssertTrue(s.fuehreAus(a), "\(variante) seed \(seed) \(a)")
                    schritte += 1
                }
                XCTAssertTrue(s.rundeBeendet, "\(variante) seed \(seed) endet nicht")
                XCTAssertNotNil(s.sieger)
            }
        }
    }

    func testCodable() throws {
        let s = neu(4, .echt, 7)
        XCTAssertEqual(try JSONDecoder().decode(ErSpiel.self, from: JSONEncoder().encode(s)), s)
    }

    func testNamen() {
        XCTAssertEqual(ErNamen.name(ErKarte(0, 14), .kartendomino), "A")
        XCTAssertEqual(ErNamen.name(ErKarte(0, 14), .echt), "14")
        XCTAssertEqual(ErNamen.zeichen(1, .echt), "■")
    }
}
