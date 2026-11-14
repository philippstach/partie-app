// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielFarbraetsel
import SpieleKern

@Suite("Rätsel")
struct RaetselTests {
    @Test func gleicherSeedGleichesRaetsel() {
        #expect(Raetsel.erzeugen(stufe: .mittel, seed: 42) == Raetsel.erzeugen(stufe: .mittel, seed: 42))
        #expect(Raetsel.erzeugen(stufe: .mittel, seed: 42) != Raetsel.erzeugen(stufe: .mittel, seed: 43))
    }

    @Test func bestwertZaehltNurOhneTipps() {
        var s = Statistik()
        let mitTipp = s.eintragen(stufe: .leicht, zuege: 10, sekunden: 5, tag: nil, hilfen: 3)
        #expect(!mitTipp && s.werte(.leicht).bestZuege == nil && s.werte(.leicht).geloest == 1)
        let ohne = s.eintragen(stufe: .leicht, zuege: 30, sekunden: 90, tag: nil)
        #expect(ohne && s.werte(.leicht).bestZuege == 30)
    }

    @Test(arguments: Stufe.allCases)
    func startIstEinePermutationUndFestBleibtFest(stufe: Stufe) {
        for seed in UInt64(1)...20 {
            let r = Raetsel.erzeugen(stufe: stufe, seed: seed)
            #expect(r.start.count == stufe.anzahl)
            #expect(Set(r.start) == Set(0..<stufe.anzahl))
            for f in r.fest { #expect(r.start[f] == f) }
            let lose = (0..<stufe.anzahl).filter { !r.fest.contains($0) }
            #expect(lose.allSatisfy { r.start[$0] != $0 }, "keine lose Kachel liegt schon richtig")
            #expect(!Partie(raetsel: r).geloest)
        }
    }

    @Test func festeProStufe() {
        #expect(Raetsel.festePlaetze(.schwer).count == 4)
        #expect(Raetsel.festePlaetze(.mittel).count == 8)
        let leicht = Raetsel.festePlaetze(.leicht)
        #expect(leicht.count == 2 * 5 + 2 * (7 - 2))
    }

    @Test func nachbarkachelnSindUnterscheidbar() {
        for stufe in Stufe.allCases {
            for seed in UInt64(1)...300 {
                let r = Raetsel.erzeugen(stufe: stufe, seed: seed)
                #expect(Raetsel.kleinsterNachbarabstand(r.ziel, spalten: r.spalten) >= Raetsel.mindestAbstand)
            }
        }
    }

    @Test func ecken() {
        let r = Raetsel.erzeugen(stufe: .schwer, seed: 5)
        #expect(r.ziel.count == 77)
        #expect(r.fest == [0, 6, 70, 76])
    }
}

@Suite("Partie")
struct PartieTests {
    func partie(_ stufe: Stufe = .leicht, seed: UInt64 = 3) -> Partie { Partie(raetsel: .erzeugen(stufe: stufe, seed: seed)) }

    @Test func feststeheTauschenNicht() {
        var p = partie()
        let fest = p.raetsel.fest.first!
        let lose = (0..<p.raetsel.stufe.anzahl).first { !p.istFest($0) }!
        let e1 = p.tauschen(fest, lose)
        #expect(!e1)
        let e2 = p.tauschen(lose, lose)
        #expect(!e2)
        let e3 = p.tauschen(-1, lose)
        #expect(!e3)
        #expect(p.zuege == 0)
    }

    @Test func tauschenZaehltUndZurueckStelltHer() {
        var p = partie()
        let start = p.belegung
        let lose = (0..<p.raetsel.stufe.anzahl).filter { !p.istFest($0) }
        let e4 = p.tauschen(lose[0], lose[1])
        #expect(e4)
        #expect(p.zuege == 1)
        #expect(p.belegung != start)
        let e5 = p.zurueck()
        #expect(e5)
        #expect(p.belegung == start)
        #expect(p.zuege == 1, "Zähler geht nicht zurück")
        let e6 = p.zurueck()
        #expect(!e6)
    }

    @Test(arguments: Stufe.allCases)
    func hilfenLoesenDasRaetsel(stufe: Stufe) {
        var p = partie(stufe)
        var schritte = 0
        while !p.geloest, p.hilfe() != nil { schritte += 1 }
        #expect(p.geloest)
        #expect(p.hilfen == schritte)
        #expect(schritte <= stufe.anzahl)
        #expect(p.fortschritt == 1)
        let e7 = p.hilfe()
        #expect(e7 == nil)
    }

    @Test func gesperrtNachDemLoesen() {
        var p = partie()
        while p.hilfe() != nil {}
        let lose = (0..<p.raetsel.stufe.anzahl).filter { !p.istFest($0) }
        let e8 = p.tauschen(lose[0], lose[1])
        #expect(!e8)
    }

    @Test func codableRundreise() throws {
        var p = partie(.mittel)
        _ = p.hilfe()
        let daten = try JSONEncoder().encode(p)
        #expect(try JSONDecoder().decode(Partie.self, from: daten) == p)
    }
}

@Suite("Statistik und Speicher")
@MainActor
struct SpeicherTests {
    func ablage() -> Ablage {
        SpielStand.loeschen(GameStore.standKennung)   // der Stand zum Fortsetzen liegt im Kern, nicht in der Datei
        return Ablage(url: FileManager.default.temporaryDirectory.appending(path: "farbraetsel-test-\(UUID().uuidString).json"))
    }

    @Test func bestwerteUndSerie() {
        var s = Statistik()
        let erster = s.eintragen(stufe: .leicht, zuege: 20, sekunden: 60, tag: nil)
        let zweiter = s.eintragen(stufe: .leicht, zuege: 25, sekunden: 40, tag: nil)
        #expect(erster)
        #expect(!zweiter)
        #expect(s.werte(.leicht).bestZuege == 20)
        #expect(s.werte(.leicht).bestSekunden == 40)
        #expect(s.werte(.leicht).geloest == 2)

        var kal = Calendar(identifier: .gregorian); kal.timeZone = .gmt
        let heute = Date(timeIntervalSince1970: 1_793_000_000)
        for i in 0..<3 {
            s.tage.insert(Tageskennung.text(kal.date(byAdding: .day, value: -i, to: heute)!, kal))
        }
        #expect(s.serie(heute: heute, kalender: kal) == 3)
        s.tage.remove(Tageskennung.text(heute, kal))
        #expect(s.serie(heute: heute, kalender: kal) == 2, "heute noch offen: Serie bis gestern")
    }

    @Test func seedProTagIstStabil() {
        let d = Date(timeIntervalSince1970: 1_793_000_000)
        #expect(Tageskennung.seed(d) == Tageskennung.seed(d.addingTimeInterval(60)))
        #expect(Tageskennung.seed(d) != Tageskennung.seed(d.addingTimeInterval(86_400 * 2)))
    }

    @Test func partieUeberlebtNeustart() {
        let a = ablage()
        defer { SpielStand.loeschen(GameStore.standKennung) }
        let s1 = GameStore(ablage: a)
        s1.neu(stufe: .leicht)
        s1.hilfe()
        s1.speichern()
        let s2 = GameStore(ablage: a)
        #expect(s2.partie == s1.partie)
    }

    @Test func kaputteDateiGibtStandard() throws {
        let a = ablage()
        try Data("{kaputt".utf8).write(to: a.url)
        #expect(GameStore(ablage: a).partie == nil)
        try Data(#"{"tagesTag":"2026-11-03"}"#.utf8).write(to: a.url)
        #expect(GameStore(ablage: a).statistik == Statistik())
    }

    @Test func loesenTraegtStatistikEin() {
        let s = GameStore(ablage: ablage())
        s.neu(stufe: .leicht)
        while s.ergebnis == nil, s.partie != nil { s.hilfe() }
        #expect(s.ergebnis?.hilfen ?? 0 > 0)
        #expect(s.statistik.werte(.leicht).geloest == 1)
        #expect(s.partie == nil)
    }

    @Test func tippenWaehltUndTauscht() {
        let s = GameStore(ablage: ablage())
        s.neu(stufe: .leicht)
        let p = s.partie!
        let lose = (0..<p.raetsel.stufe.anzahl).filter { !p.istFest($0) }
        s.tippen(p.raetsel.fest.first!)
        #expect(s.ausgewaehlt == nil, "feste Kachel nicht wählbar")
        s.tippen(lose[0]); #expect(s.ausgewaehlt == lose[0])
        s.tippen(lose[0]); #expect(s.ausgewaehlt == nil)
        s.tippen(lose[0]); s.tippen(lose[1])
        #expect(s.partie?.zuege == 1)
    }
}
