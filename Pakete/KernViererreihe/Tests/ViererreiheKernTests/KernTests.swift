// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielViererreihe

private func jetzt() -> UInt64 { DispatchTime.now().uptimeNanoseconds }

@Suite("Kern")
struct KernTests {
    typealias JSON = Regeltests.JSON

    // MARK: Partie

    @Test func einwerfenLiefertZeileUndWechseltDenSpieler() throws {
        var p = try Partie()
        #expect(p.amZug == 1)
        #expect(try p.einwerfen(3) == 0)
        #expect(p.amZug == 2)
        #expect(try p.einwerfen(3) == 1)
        #expect(p.amZug == 1)
        #expect(p.steine(von: 1) == 1 && p.steine(von: 2) == 1)
        var blau = try Partie(beginner: 2)
        #expect(blau.amZug == 2)
        try blau.einwerfen(0)
        #expect(blau.brett[0][0] == 2 && blau.amZug == 1)
    }

    @Test func codableBeginnerUndZuege() throws {
        let p = try Partie(beginner: 2, zuege: [3, 3, 4, 2, 5])
        let daten = try JSONEncoder().encode(p)
        let text = String(decoding: daten, as: UTF8.self)
        #expect(text.contains("beginner") && text.contains("zuege") && !text.contains("brett"))
        #expect(try JSONDecoder().decode(Partie.self, from: daten) == p)
        // Fehlende Felder → Standardwerte, ungültige Züge → Fehler
        #expect(try JSONDecoder().decode(Partie.self, from: Data("{}".utf8)) == (try Partie()))
        #expect(throws: (any Error).self) { try JSONDecoder().decode(Partie.self, from: Data(#"{"zuege":[9]}"#.utf8)) }
    }

    @Test func letzterSteinUndBild() throws {
        let p = try Partie(zuege: [3, 3, 0])
        #expect(p.letzterStein == Zelle(spalte: 0, zeile: 0))
        #expect(p.bild == [".......", ".......", ".......", ".......", "...B...", "G..G..."])
        #expect(try Partie().letzterStein == nil)
    }

    // MARK: Bitbrett = Bewertung

    @Test func bitbrettBewertungGleichSpielfeldBewertung() throws {
        var q = SpielViererreihe.SplitMix64(seed: 42)
        var pruefungen = 0
        for _ in 0..<60 {
            var p = try Partie(beginner: q.naechste(2) + 1)
            while p.status == .laeuft {
                try p.einwerfen(Computer.zufaellig(p.legaleSpalten, &q))
                let (ich, maske) = Bitbrett.von(p)
                #expect(Bitbrett.bewertung(ich: ich, maske: maske) == Bewertung.wert(p, fuer: p.naechsterSpieler))
                pruefungen += 1
            }
        }
        #expect(pruefungen > 500)
    }

    // MARK: Stark

    @Test func starkJson() throws {
        let root = try Regeltests.laden("stark.json")
        let maxTiefe = try #require(root["maxTiefe"] as? Int)
        let faelle = Regeltests.faelle(root)
        #expect(faelle.count >= 3)
        for f in faelle {
            let name = f["name"] as? String ?? "?"
            let p = try Regeltests.partie(f)
            let haltend = Regeltests.ints((f["erwartet"] as! JSON)["haltend"])
            var q = ListenQuelle([])
            let wahl = Computer.waehle(.stark, p, zufall: &q, zeitlimit: nil, maxTiefe: maxTiefe)
            #expect(haltend.contains(wahl), "\(name) (\(f["art"] ?? "")): Wahl \(wahl), erlaubt \(haltend)")
        }
    }

    @Test func starkAntwortetInnerhalbDesZeitlimits() throws {
        let root = try Regeltests.laden("stark.json")
        let fall = try #require(Regeltests.faelle(root).first { $0["name"] as? String == "gewinnen1" })
        let p = try Regeltests.partie(fall)
        var q = ListenQuelle([])
        let start = jetzt()
        _ = Computer.waehle(.stark, p, zufall: &q, zeitlimit: 1.0)
        let dauer = Double(jetzt() - start) / 1e9
        #expect(dauer <= 1.2, "Dauer \(dauer) s")
    }

    @Test func starkAufLeeremBrettUndMitSofortgewinn() throws {
        var q = ListenQuelle([])
        #expect(Computer.waehle(.stark, try Partie(), zufall: &q, zeitlimit: 0.2) == 3)
        // Gold hat 0,1,2 unten: Sofortgewinn in Spalte 3
        #expect(Computer.waehle(.stark, try Partie(zuege: [0, 0, 1, 1, 2, 2]), zufall: &q, zeitlimit: 0.2) == 3)
        // Blau droht mit 0,1,2 unten: Gold muss in 3 blocken
        #expect(Computer.waehle(.stark, try Partie(zuege: [6, 0, 6, 1, 5, 2]), zufall: &q, zeitlimit: 0.2) == 3)
    }

    /// Spielt stark gegen `gegner` (Seeds 1…20, stark abwechselnd Gold und Blau). Gibt (Siege, Niederlagen) von stark zurück.
    private func starkSpielt(gegen gegner: Stufe, zeitlimit: Double? = 0.3, maxTiefe: Int = Partie.felder) throws -> (siege: Int, niederlagen: Int, remis: Int) {
        var siege = 0, niederlagen = 0, remis = 0
        for seed in 1...20 {
            var q = SpielViererreihe.SplitMix64(seed: UInt64(seed))
            let stark = seed % 2 == 1 ? 1 : 2
            var p = try Partie(beginner: 1)
            while p.status == .laeuft {
                var ungenutzt = ListenQuelle([])
                let s = p.naechsterSpieler == stark
                    ? Computer.waehle(.stark, p, zufall: &ungenutzt, zeitlimit: zeitlimit, maxTiefe: maxTiefe)
                    : Computer.waehle(gegner, p, zufall: &q)
                try p.einwerfen(s)
            }
            if p.gewinner == stark { siege += 1 } else if p.gewinner == nil { remis += 1 } else { niederlagen += 1 }
        }
        return (siege, niederlagen, remis)
    }

    @Test func starkSchlaegtLeicht() throws {
        let erg = try starkSpielt(gegen: .leicht)
        #expect(erg.siege == 20, "stark gegen leicht: \(erg)")
    }

    /// Feste Suchtiefe statt Zeitlimit: deterministisch, unabhängig von der freien Rechenzeit.
    @Test func starkSchlaegtMittel() throws {
        let erg = try starkSpielt(gegen: .mittel, zeitlimit: nil, maxTiefe: 8)
        #expect(erg.siege >= 17, "stark (Tiefe 8) gegen mittel: \(erg)")
    }

    // MARK: Zufallsquelle

    @Test func listenQuelleUndZustandSpeichern() throws {
        var l = ListenQuelle([7, 8, 9])
        #expect(l.naechste(5) == 2 && l.naechste(5) == 3 && !l.aufgebraucht && l.naechste(2) == 1 && l.aufgebraucht)
        var q = SpielViererreihe.SplitMix64(seed: 12345)
        _ = q.weiter()
        let kopie = try JSONDecoder().decode(SpielViererreihe.SplitMix64.self, from: JSONEncoder().encode(q))
        #expect(kopie == q)
        var a = q, b = kopie
        #expect(a.weiter() == b.weiter())
        // Zustände über Int64 hinaus bleiben exakt
        let gross = SpielViererreihe.SplitMix64(seed: UInt64.max - 3)
        #expect(try JSONDecoder().decode(SpielViererreihe.SplitMix64.self, from: JSONEncoder().encode(gross)) == gross)
    }
}
