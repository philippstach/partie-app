// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

@Suite("Ergänzungen")
struct KernErgaenzungenTests {
    @Test func spielartenSetzenAlleSchalter() {
        #expect(Spielart.familie.optionen == .standard)
        #expect(Spielart.offiziell.optionen.startMitFigur && !Spielart.offiziell.optionen.dreiVersuche)
        #expect(!Spielart.kinder.optionen.rauswerfen)
        #expect(Spielart.schnell.optionen.figuren == 2 && Spielart.schnell.optionen.startMitFigur)
        #expect(Spielart.streng.optionen.schlagpflicht && !Spielart.streng.optionen.zielUeberspringen)
        for a in Spielart.allCases { #expect(Spielart.erkennen(a.optionen) == a) }
        var eigene = Spielart.kinder.optionen
        eigene.figuren = 3
        #expect(Spielart.erkennen(eigene) == nil)
    }

    @Test func aufstellungMitFigurenzahlUndStart() {
        var o = Optionen(); o.figuren = 3; o.startMitFigur = true
        let lage = Lage.neu(sitze: [0, 2], o)
        #expect(lage.figuren == [[0, -1, -1], [0, -1, -1]])
        #expect(Lage.neu(sitze: [0, 1, 2]).figuren.allSatisfy { $0 == [-1, -1, -1, -1] })
        #expect(Optionen.standard.figuren == 4)
        // Werte außerhalb von 2…4 werden begrenzt
        let o2 = try? JSONDecoder().decode(Optionen.self, from: Data(#"{"figuren":9}"#.utf8))
        #expect(o2?.figuren == 4)
    }

    @Test func wuerfelstatistikAusDemVerlauf() throws {
        let p = try Regeltests.partien().first { $0.name.hasPrefix("01") }!
        let sitze = p.json["sitze"] as! [Int]
        var quelle = ListenQuelle(p.json["wuerfel"] as! [Int])
        var partie = Partie.neu(sitze: sitze, beginner: p.json["beginner"] as! Int, optionen: try Regeltests.optionen(p.json["optionen"]))
        let strategien = (p.json["strategien"] as! [String]).map { Strategie(rawValue: $0)! }
        var n = 0
        while !partie.vorbei && n < 5000 {
            n += 1
            partie.wuerfeln(&quelle)
            if partie.spielzug.stand == .wahl {
                partie.waehle(Computer.entscheide(strategien[partie.amZug], partie.lage, partie.amZug, partie.spielzug.erlaubt))
            } else { partie.weiter() }
        }
        let z = Wuerfelstatistik.zaehle(partie)
        let gesamt = z.reduce(0) { $0 + $1.wuerfe }
        #expect(gesamt == partie.verlauf.reduce(0) { $0 + $1.wuerfe.count })
        #expect(gesamt == quelle.verbraucht)
        let sechsen = PartieZaehlung.zaehle(partie)
        for i in 0 ..< partie.spielerzahl { #expect(z[i].augen[5] == sechsen[i].sechsen) }
        #expect(z.allSatisfy { $0.ohneSechs >= 1 })
    }

    @Test func durststreckeUeberSpielzuegeHinweg() {
        var partie = Partie.neu(sitze: [0, 2], beginner: 0)
        var quelle = ListenQuelle([1, 1, 2, 2, 3, 6])   // S0: 1 (3 Fehlversuche mit 1,1,2) …
        for _ in 0 ..< 6 where !partie.vorbei {
            if partie.spielzug.stand == .vorWurf { partie.wuerfeln(&quelle) }
            if partie.spielzug.stand == .verfallen { partie.weiter() }
            else if partie.spielzug.stand == .wahl { partie.waehle(partie.spielzug.erlaubt[0]) }
        }
        let z = Wuerfelstatistik.zaehle(partie)
        #expect(z[0].augen[0] == 2 && z[0].augen[1] == 1)
        #expect(z[0].ohneSechs == 3)
        #expect(z[1].ohneSechs >= 2)
    }

    @MainActor
    @Test func revancheFaengtReihumAn() throws {
        let repo = GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "ludo-\(UUID().uuidString).json"))
        let store = GameStore(repository: repo, seed: { 5 })
        let spieler = [Spieler(name: "A", avatar: "a", strategie: .mensch, sitz: 0), Spieler(name: "B", avatar: "b", strategie: .mensch, sitz: 1),
                       Spieler(name: "C", avatar: "c", strategie: .mensch, sitz: 2)]
        store.neuePartie(spieler: spieler, optionen: .standard)
        var vorher = try #require(store.zustand).amZug
        // ein paar Spielzüge machen, damit der Verlauf nicht leer ist
        for _ in 0 ..< 200 where store.zustand?.partie.verlauf.isEmpty == true { StoreTests.menschSchritt(store) }
        let ersterSpieler = try #require(store.zustand?.partie.verlauf.first?.spieler)
        #expect(ersterSpieler == vorher)
        for _ in 0 ..< 3 {
            store.revanche()
            let z = try #require(store.zustand)
            #expect(z.amZug == (vorher + 1) % 3)
            vorher = z.amZug
            for _ in 0 ..< 200 where store.zustand?.partie.verlauf.isEmpty == true { StoreTests.menschSchritt(store) }
        }
    }

    @MainActor
    @Test func partieIDWechseltBeiNeuerPartieRevancheUndBeenden() throws {
        let repo = GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "ludo-\(UUID().uuidString).json"))
        let store = GameStore(repository: repo, seed: { 1 })
        let id0 = store.partieID
        let spieler = [Spieler(name: "A", avatar: "a", strategie: .mensch, sitz: 0), Spieler(name: "B", avatar: "b", strategie: .gut, sitz: 2)]
        store.neuePartie(spieler: spieler, optionen: .standard)
        let id1 = store.partieID
        #expect(id1 != id0)
        store.revanche()
        let id2 = store.partieID
        #expect(id2 != id1, "Revanche: die Oberfläche muss ihren Ablauf neu aufsetzen")
        store.beenden()
        #expect(store.partieID != id2)
    }
}
