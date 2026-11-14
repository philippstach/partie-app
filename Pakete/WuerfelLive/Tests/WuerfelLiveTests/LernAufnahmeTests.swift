// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import CoreGraphics
@testable import WuerfelLive

final class LernAufnahmeTests: XCTestCase {
    private func tempOrdner() throws -> URL {
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("lern-test-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: u) }
        return u
    }

    func testCrc32BekannterWert() {
        XCTAssertEqual(ZipSchreiber.Crc32.summe(Data("123456789".utf8)), 0xCBF4_3926)
        XCTAssertEqual(ZipSchreiber.Crc32.summe(Data()), 0)
    }

    func testFundeWerdenBestaetigtenWuerfelnZugeordnet() {
        let k = 9.0 / 16.0
        let bestaetigt = [
            LernWuerfel(id: 1, augen: 3, x: 0.20, y: 0.30, breite: 0.10, hoehe: 0.056, sicher: true),
            LernWuerfel(id: 2, augen: 5, x: 0.60, y: 0.50, breite: 0.10, hoehe: 0.056, sicher: true),
        ]
        let gesehen = [
            GesehenerWuerfel(augen: 4, rahmen: CGRect(x: 0.21, y: 0.305, width: 0.10, height: 0.056), sicherheit: 0.7),   // nah an Würfel 1, falsch gelesen
            GesehenerWuerfel(augen: 5, rahmen: CGRect(x: 0.61, y: 0.50, width: 0.10, height: 0.056), sicherheit: 0.9),
            GesehenerWuerfel(augen: 2, rahmen: CGRect(x: 0.90, y: 0.90, width: 0.05, height: 0.03), sicherheit: 0.4),     // Fehlfund
        ]
        let funde = LernAufnahme.funde(gesehen, bestaetigt: bestaetigt, seitenverhaeltnis: k)
        XCTAssertEqual(funde.map(\.richtig), [3, 5, nil])
        XCTAssertEqual(funde.map(\.augen), [4, 5, 2])
    }

    func testEinWuerfelWirdNurEinmalZugeordnet() {
        let bestaetigt = [LernWuerfel(id: 1, augen: 6, x: 0.4, y: 0.4, breite: 0.1, hoehe: 0.056, sicher: true)]
        let g = GesehenerWuerfel(augen: 6, rahmen: CGRect(x: 0.4, y: 0.4, width: 0.1, height: 0.056))
        let funde = LernAufnahme.funde([g, g], bestaetigt: bestaetigt, seitenverhaeltnis: 9.0 / 16.0)
        XCTAssertEqual(funde.map(\.richtig), [6, nil])
    }

    func testGeschaetzterRahmenSitztUmDenTippunkt() {
        // Bild 1080 × 1920, übliche Kante 10 % der kurzen Seite = 108 px.
        let e = LernErgaenzung(tipp: CGPoint(x: 0.5, y: 0.5), ueblicheKante: 0.1, erkannt: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3))
        let r = LernAufnahme.geschaetzterRahmen(e, breite: 1080, hoehe: 1920)
        XCTAssertEqual(r.breite, 0.1, accuracy: 1e-9)
        XCTAssertEqual(r.hoehe, 108.0 / 1920.0, accuracy: 1e-9)
        XCTAssertEqual(r.x + r.breite / 2, 0.5, accuracy: 1e-9)
        XCTAssertEqual(r.y + r.hoehe / 2, 0.5, accuracy: 1e-9)
        // Am Rand wird der Rahmen ins Bild geschoben.
        let rand = LernAufnahme.geschaetzterRahmen(LernErgaenzung(tipp: CGPoint(x: 0.99, y: 0.01), ueblicheKante: 0.1, erkannt: .zero), breite: 1080, hoehe: 1920)
        XCTAssertEqual(rand.x + rand.breite, 1, accuracy: 1e-9)
        XCTAssertEqual(rand.y, 0, accuracy: 1e-9)
        // Ohne übliche Größe gilt die Größe des Nah-Finders.
        let ohne = LernAufnahme.geschaetzterRahmen(LernErgaenzung(tipp: CGPoint(x: 0.5, y: 0.5), ueblicheKante: nil, erkannt: CGRect(x: 0, y: 0, width: 0.1, height: 0.05625)), breite: 1080, hoehe: 1920)
        XCTAssertEqual(ohne.breite, 0.1, accuracy: 1e-9)
    }

    func testRingBehaeltNurDieLetztenBilder() {
        let ring = LernRing(kapazitaet: 3)
        for i in 0..<5 { ring.merke(LernRingBild(jpeg: Data([UInt8(i)]), funde: [], zeit: Date(timeIntervalSince1970: Double(i)), seitenverhaeltnis: 0.5625)) }
        XCTAssertEqual(ring.alle().map { $0.jpeg[0] }, [2, 3, 4])
        ring.leeren()
        XCTAssertTrue(ring.alle().isEmpty)
    }

    func testSpeichernZaehlenPackenLoeschen() throws {
        let wurzel = try tempOrdner().appendingPathComponent("w", isDirectory: true)
        let wuerfel = [LernWuerfel(id: 1, augen: 2, x: 0.3, y: 0.3, breite: 0.1, hoehe: 0.056, sicher: true, korrigiertVon: 5)]
        let vorher = (0..<2).map { LernRingBild(jpeg: Data([1, 2, 3, UInt8($0)]), funde: [GesehenerWuerfel(augen: 2, rahmen: CGRect(x: 0.3, y: 0.3, width: 0.1, height: 0.056))],
                                                zeit: Date(timeIntervalSince1970: Double($0)), seitenverhaeltnis: 0.5625) }
        for korrigiert in [true, false] {
            let kennung = LernAufnahme.neueKennung(korrigiert: korrigiert)
            let wurf = LernWurf(id: kennung.id, zeit: kennung.iso, breite: 1080, hoehe: 1920, erwartet: 5, korrigiert: korrigiert, wuerfel: wuerfel, falscheFunde: [])
            let ordner = try LernAufnahme.speichere(wurf: wurf, ordnerName: kennung.ordnerName, standbild: Data([9, 9]), vorher: vorher, in: wurzel)
            XCTAssertTrue(FileManager.default.fileExists(atPath: ordner.appendingPathComponent("standbild.jpg").path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: ordner.appendingPathComponent("vorher-02.jpg").path))
            let gelesen = try JSONDecoder().decode(LernWurf.self, from: Data(contentsOf: ordner.appendingPathComponent("wurf.json")))
            XCTAssertEqual(gelesen.vorher.count, 2)
            XCTAssertEqual(gelesen.vorher.first?.funde.first?.richtig, 2)
            XCTAssertEqual(gelesen.vorher.first?.sekundenVorher, 1)
            XCTAssertEqual(ordner.lastPathComponent.hasSuffix("-k"), korrigiert)
        }
        XCTAssertEqual(LernAufnahme.anzahl(in: wurzel), 2)
        XCTAssertEqual(LernAufnahme.anzahlKorrigiert(in: wurzel), 1)

        let zip = try LernAufnahme.packe(in: wurzel, nach: wurzel.deletingLastPathComponent().appendingPathComponent("t.zip"))
        let daten = try Data(contentsOf: zip)
        XCTAssertEqual(Array(daten.prefix(4)), [0x50, 0x4B, 0x03, 0x04])
        // Ende des Verzeichnisses: 1 Textdatei + 2 Würfe × 4 Dateien = 9 Einträge.
        let ende = daten.count - 22
        XCTAssertEqual(Array(daten[ende..<ende + 4]), [0x50, 0x4B, 0x05, 0x06])
        XCTAssertEqual(Int(daten[ende + 10]) | Int(daten[ende + 11]) << 8, 9)

        LernAufnahme.loescheAlle(in: wurzel)
        XCTAssertEqual(LernAufnahme.anzahl(in: wurzel), 0)
    }
}
