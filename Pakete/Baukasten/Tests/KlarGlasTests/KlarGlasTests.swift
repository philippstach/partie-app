// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import Foundation
@testable import KlarGlas

// Logik des Design-Pakets, prüfbar auf dem Mac ohne Simulator (`swift test`). Die Ansichten selbst prüft der Prüfbogen (T2).

@Suite("Paket")
struct PaketTests {
    @Test("Versionsnummer hat die Form X.Y")
    func version() {
        let teile = KlarGlas.version.split(separator: ".")
        #expect(teile.count == 2 && teile.allSatisfy { Int($0) != nil })
    }

    @Test("Theme-Werte entsprechen dem Handbuch (A.4)")
    func theme() {
        #expect(Theme.tapSize == 44 && Theme.hauptKnopfHoehe == 54 && Theme.titelGroesse == 56)
        #expect(Theme.cardRadius == 20 && Theme.leistenRadius == 28 && Theme.sheetRadius == 32 && Theme.feldRadius == 12)
        #expect(Theme.seitenRand == 16 && Theme.kartenAbstand == 12 && Theme.innen == 16)
    }
}

@Suite("Gruß")
struct GrussTests {
    var kal: Calendar { var k = Calendar(identifier: .gregorian); k.timeZone = TimeZone(identifier: "UTC")!; return k }
    func um(_ h: Int) -> Date { kal.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: h))! }

    @Test("Anrede nach Tageszeit, ohne Namen (E2)")
    func tageszeit() {
        #expect(Gruss.text(datum: um(6), kalender: kal).hasPrefix("Guten Morgen") || Gruss.text(datum: um(6), kalender: kal).hasPrefix("Good morning"))
        #expect(Gruss.text(datum: um(10), kalender: kal) != Gruss.text(datum: um(11), kalender: kal))
        #expect(Gruss.text(datum: um(17), kalender: kal) != Gruss.text(datum: um(18), kalender: kal))
        #expect(Gruss.text(datum: um(23), kalender: kal) == Gruss.text(datum: um(2), kalender: kal))
        #expect(!Gruss.text(datum: um(12), kalender: kal).contains(","))
    }

    @Test("Mit Namen: Komma, leerer Name wie kein Name")
    func name() {
        #expect(Gruss.text(name: "Philipp", datum: um(12), kalender: kal).hasSuffix(", Philipp"))
        #expect(Gruss.text(name: "", datum: um(12), kalender: kal) == Gruss.text(datum: um(12), kalender: kal))
    }
}

@Suite("Zeitformat")
struct ZeitformatTests {
    @Test("m:ss, ab einer Stunde h:mm:ss (Q16)")
    func formate() {
        #expect(Zeitformat.text(sekunden: 0) == "0:00")
        #expect(Zeitformat.text(sekunden: 34) == "0:34")
        #expect(Zeitformat.text(sekunden: 754) == "12:34")
        #expect(Zeitformat.text(sekunden: 3600) == "1:00:00")
        #expect(Zeitformat.text(sekunden: 3725) == "1:02:05")
        #expect(Zeitformat.text(sekunden: -5) == "0:00")
        #expect(Zeitformat.text(89.9) == "1:29")
        #expect(Zeitformat.text(.nan) == "0:00")
    }

    @Test("Gesprochene Form ist nie leer")
    func gesprochen() {
        #expect(!Zeitformat.gesprochen(sekunden: 252).isEmpty)
        #expect(!Zeitformat.gesprochen(sekunden: 0).isEmpty)
    }
}

@Suite("Tagesrätsel")
struct TagesTests {
    var kal: Calendar { var k = Calendar(identifier: .gregorian); k.timeZone = TimeZone(identifier: "UTC")!; return k }
    func tag(_ d: Int, monat: Int = 11) -> Date { kal.date(from: DateComponents(year: 2026, month: monat, day: d, hour: 12))! }
    func s(_ d: Int, monat: Int = 11) -> String { Tagesschluessel.text(tag(d, monat: monat), kalender: kal) }

    @Test("Tagesschlüssel JJJJ-MM-TT, hin und zurück")
    func schluessel() {
        #expect(s(4) == "2026-11-04")
        #expect(Tagesschluessel.datum("2026-11-04", kalender: kal).map { kal.isDate($0, inSameDayAs: tag(4)) } == true)
        #expect(Tagesschluessel.datum("quatsch", kalender: kal) == nil)
    }

    @Test("Serie: zusammenhängende Tage bis heute oder innerhalb der Toleranz")
    func serie() {
        let drei: Set<String> = [s(2), s(3), s(4)]
        #expect(TagesSerie.laenge(geloest: drei, heute: tag(4), kalender: kal) == 3)
        #expect(TagesSerie.laenge(geloest: [s(2), s(3)], heute: tag(4), toleranz: 1, kalender: kal) == 2)   // gestern gelöst, Serie lebt
        #expect(TagesSerie.laenge(geloest: [s(2)], heute: tag(4), toleranz: 1, kalender: kal) == 0)        // zu lange her
        #expect(TagesSerie.laenge(geloest: [s(2)], heute: tag(4), toleranz: 2, kalender: kal) == 1)        // Ruhetag erlaubt (Sudoku)
        #expect(TagesSerie.laenge(geloest: [s(4), s(2)], heute: tag(4), kalender: kal) == 1)               // Lücke bricht die Serie
        #expect(TagesSerie.laenge(geloest: [], heute: tag(4), kalender: kal) == 0)
        #expect(TagesSerie.laenge(geloest: [s(31, monat: 10), s(1), s(2), s(3), s(4)], heute: tag(4), kalender: kal) == 5)   // über den Monatswechsel
    }

    @Test("Widget-Regel: gespeicherte Serie lebt nur innerhalb der Toleranz")
    func lebend() {
        #expect(TagesSerie.lebend(serie: 5, letzterTag: s(3), heute: tag(4), toleranz: 1, kalender: kal) == 5)
        #expect(TagesSerie.lebend(serie: 5, letzterTag: s(4), heute: tag(4), toleranz: 0, kalender: kal) == 5)
        #expect(TagesSerie.lebend(serie: 5, letzterTag: s(2), heute: tag(4), toleranz: 1, kalender: kal) == 0)
        #expect(TagesSerie.lebend(serie: 5, letzterTag: "", heute: tag(4), kalender: kal) == 0)
        #expect(TagesSerie.lebend(serie: -2, letzterTag: s(4), heute: tag(4), kalender: kal) == 0)
    }

    @Test("Wochenpunkte Mo…So der laufenden Woche")
    func woche() {
        // 4.11.2026 ist ein Mittwoch; Woche Mo 2.11. … So 8.11.
        let w = TagesSerie.woche(geloest: [s(2), s(4), s(8)], heute: tag(4), kalender: kal)
        #expect(w == [true, false, true, false, false, false, true])
        #expect(TagesSerie.woche(geloest: [], heute: tag(4), kalender: kal).count == 7)
    }

    @Test("Seriezeile")
    func text() {
        #expect(TagesSerie.text(0) != TagesSerie.text(1))
        #expect(TagesSerie.text(5).contains("5"))
    }
}

@Suite("Spielspeicher")
struct SpielSpeicherTests {
    struct Stand: Codable, Equatable {
        var zuege: Int
        var name: String
        var toleranzFeld: Int

        init(zuege: Int, name: String, toleranzFeld: Int = 7) { self.zuege = zuege; self.name = name; self.toleranzFeld = toleranzFeld }

        enum CodingKeys: String, CodingKey { case zuege, name, toleranzFeld }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            zuege = try c.decode(Int.self, forKey: .zuege)
            name = try c.decode(String.self, forKey: .name)
            toleranzFeld = c.wert(.toleranzFeld, sonst: 7)   // fehlendes Feld → Standardwert
        }
    }

    @Test("Speichern und Laden")
    func rundreise() throws {
        let ablage = FluechtigeAblage()
        let speicher = SpielSpeicher<Stand>(ablage: ablage)
        if case .leer = speicher.laden() {} else { Issue.record("leer erwartet") }
        try speicher.speichern(Stand(zuege: 3, name: "Anna"))
        #expect(speicher.laden().stand == Stand(zuege: 3, name: "Anna"))
        try speicher.loeschen()
        #expect(speicher.laden().stand == nil)
    }

    @Test("Kaputter Stand: kein Absturz, Daten bleiben liegen")
    func defekt() {
        let ablage = FluechtigeAblage(daten: Data("{nicht json".utf8))
        let speicher = SpielSpeicher<Stand>(ablage: ablage)
        guard case .defekt(_, let daten) = speicher.laden() else { Issue.record("defekt erwartet"); return }
        #expect(daten == ablage.daten)   // nichts gelöscht
    }

    @Test("Fehlende Felder bekommen Standardwerte")
    func tolerant() {
        let ablage = FluechtigeAblage(daten: Data(#"{"zuege": 2, "name": "Ben"}"#.utf8))
        #expect(SpielSpeicher<Stand>(ablage: ablage).laden().stand == Stand(zuege: 2, name: "Ben", toleranzFeld: 7))
        let falscherTyp = FluechtigeAblage(daten: Data(#"{"zuege": 2, "name": "Ben", "toleranzFeld": "x"}"#.utf8))
        #expect(SpielSpeicher<Stand>(ablage: falscherTyp).laden().stand?.toleranzFeld == 7)
    }

    @Test("Dateiablage schreibt atomar und löscht wieder")
    func datei() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("klarglas-test-\(UUID().uuidString).json")
        let speicher = SpielSpeicher<Stand>(ablage: DateiAblage(url: url))
        try speicher.speichern(Stand(zuege: 1, name: "C"))
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(speicher.laden().stand?.zuege == 1)
        try speicher.loeschen()
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }
}

import XCTest
@testable import KlarGlas

final class DesignZentralTests: XCTestCase {
    func testVoreinstellungEntsprichtHeute() {
        Design.Regler.zuruecksetzen()
        XCTAssertEqual(Theme.seitenRand, 16); XCTAssertEqual(Theme.kartenAbstand, 12)
        XCTAssertEqual(Theme.cardRadius, 20); XCTAssertEqual(Theme.feldRadius, 12)
        XCTAssertEqual(Theme.titelGroesse, 56); XCTAssertEqual(Design.Farbe.akzentHell, 0x1658D8)
    }
    func testReglerWirktUeberall() {
        Design.Regler.abstand = 1.5; defer { Design.Regler.zuruecksetzen() }
        XCTAssertEqual(Theme.seitenRand, 24)
        Design.Regler.abstand = 9   // wird begrenzt
        XCTAssertEqual(Theme.seitenRand, 24)
    }
}
