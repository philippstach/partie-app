// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SpieleKern
@testable import SpielRauswurf

/// „Rauswurf“: Spielerliste aus den Teilnehmern des Rahmens, Computer-Stärke, Ende, Verlauf, Fortsetzen.
@MainActor
@Suite("Rauswurf")
struct NeuTests {
    private func teilnehmer(_ namen: [String], computer: Set<Int> = []) -> [SpielTeilnehmer] {
        namen.enumerated().map { SpielTeilnehmer(name: $1, computer: computer.contains($0)) }
    }

    @Test func sitzeZuZweitGegenueber() {
        #expect(NeuLogik.sitze(2) == [0, 2])
        #expect(NeuLogik.sitze(3) == [0, 1, 2])
        #expect(NeuLogik.sitze(4) == [0, 1, 2, 3])
    }

    @Test func spielerAusTeilnehmern() {
        let s = NeuLogik.spieler(teilnehmer(["Anna", "Computer", "Ben"], computer: [1]), computer: .gut, echteWuerfel: true, bekannt: [("Anna", "🦊", 0)])
        #expect(s.map(\.name) == ["Anna", "Computer", "Ben"])
        #expect(s.map(\.sitz) == [0, 1, 2])
        #expect(s[0].avatar == "🦊")
        #expect(Set(s.map(\.avatar)).count == 3, "jeder Platz hat ein eigenes Zeichen")
        #expect(s[1].strategie == .gut && s[0].strategie == .mensch)
        // Echte Würfel nur für Menschen, Computer würfeln immer in der App
        #expect(s[0].wuerfel == .echt && s[2].wuerfel == .echt && s[1].wuerfel == .app)
    }

    @Test func gleichesZeichenWirdErsetzt() {
        let s = NeuLogik.spieler(teilnehmer(["Anna", "Ben"]), computer: .gut, echteWuerfel: false, bekannt: [("Anna", "🦊", 0), ("Ben", "🦊", 0)])
        #expect(s[0].avatar != s[1].avatar)
    }

    @Test func computerStaerke() {
        #expect(NeuLogik.strategie(stufe: .leicht, lieb: false) == .einfach)
        #expect(NeuLogik.strategie(stufe: .mittel, lieb: false) == .gut)
        #expect(NeuLogik.strategie(stufe: .schwer, lieb: false) == .gut)
        #expect(NeuLogik.strategie(stufe: .leicht, lieb: true) == .lieb)
    }

    /// Ganze Partien nur mit Computern, für 2, 3 und 4 Spieler und mehrere Seeds: enden immer, Ende nennt alle genau einmal.
    @Test(arguments: [2, 3, 4]) func partieEndetUndMeldetAlle(anzahl: Int) {
        for seed in 1...5 {
            let t = teilnehmer((1...anzahl).map { "Computer \($0)" }, computer: Set(0 ..< anzahl))
            let s = NeuLogik.spieler(t, computer: .gut, echteWuerfel: false)
            var z = Spielzustand(spieler: s, optionen: .standard, seed: UInt64(seed))
            var schritte = 0
            while z.phase != .vorbei && schritte < 20_000 { z.computerSchritt(); schritte += 1 }
            #expect(z.phase == .vorbei, "Partie \(anzahl) Spieler, Seed \(seed) endet nicht")
            let e = NeuLogik.ende(z)
            #expect(e.reihenfolge.count == anzahl && Set(e.reihenfolge).count == anzahl)
            #expect(e.reihenfolge.first == s[z.partie.platzierung.first!].name)
        }
    }

    @Test func hausUndZiel() {
        #expect(NeuLogik.hausZiel([-1, -1, 5, 40]) == (2, 1))
        #expect(NeuLogik.hausZiel([43, 42, 41, 40]) == (0, 4))
    }

    @Test func verlaufTexte() {
        let s = NeuLogik.spieler(teilnehmer(["Anna", "Ben"]), computer: .gut, echteWuerfel: false)
        let z = Spielzustand(spieler: s, optionen: .standard, seed: 1)
        let figuren = z.lage.figuren
        let schlag = Verlaufseintrag(spieler: 0, wuerfe: [Wurf(augen: 6, zug: Zug(von: -1, nach: 0)), Wurf(augen: 3, zug: Zug(von: 0, nach: 3, schlaegt: 1))], figuren: figuren)
        #expect(NeuLogik.verlaufText(schlag, z).hasPrefix("Anna: 6, 3"))
        #expect(NeuLogik.verlaufText(schlag, z).contains("Ben"))
        let keiner = Verlaufseintrag(spieler: 1, wuerfe: [Wurf(augen: 2, zug: nil)], figuren: figuren)
        #expect(NeuLogik.verlaufText(keiner, z).hasPrefix("Ben: 2"))
        let ziel = Verlaufseintrag(spieler: 0, wuerfe: [Wurf(augen: 1, zug: Zug(von: 39, nach: 40))], figuren: figuren)
        #expect(NeuLogik.verlaufText(ziel, z).hasPrefix("Anna: 1"))
    }

    @Test func standLaesstSichFortsetzen() throws {
        let ud = UserDefaults(suiteName: "rauswurf-neu-test-\(UUID().uuidString)")!
        let s = NeuLogik.spieler(teilnehmer(["Anna", "Computer"], computer: [1]), computer: .gut, echteWuerfel: false)
        var z = Spielzustand(spieler: s, optionen: .standard, seed: 3)
        for _ in 0..<30 where z.phase == .computer { z.computerSchritt() }
        SpielStand.sichern(Spielstand(zustand: z, dauerSekunden: 12), spiel: NeuLogik.id, defaults: ud)
        let geladen = try #require(SpielStand.laden(Spielstand.self, spiel: NeuLogik.id, defaults: ud))
        #expect(geladen.zustand == z && geladen.zustand.istPlausibel && geladen.dauerSekunden == 12)
        // Über die interne Datei in den Store (so macht es die Wurzel)
        let url = FileManager.default.temporaryDirectory.appending(path: "rauswurf-neu-test-\(UUID().uuidString).json")
        let repo = GameRepository(url: url)
        try repo.speichern(geladen)
        let store = GameStore(repository: repo)
        #expect(store.zustand == z && store.hatSpielstand)
        repo.loeschen()
    }

    @Test func modulNebenAltemModul() {
        let neu = RauswurfModul()
        #expect(neu.id == "rauswurf-neu" && neu.name == "Rauswurf" && neu.gattung == .brett && neu.spielerzahl == 2...4)
        #expect(NeuLayout.entscheide(breite: 390, hoehe: 844, sizeClass: .compact) == .kompakt)
        #expect(NeuLayout.entscheide(breite: 1180, hoehe: 820, sizeClass: .regular) == .breitQuer)
        #expect(NeuLayout.entscheide(breite: 820, hoehe: 1180, sizeClass: .regular) == .breitHoch)
        #expect(NeuLayout.entscheide(breite: 1180, hoehe: 820, sizeClass: .regular, grosseSchrift: true) == .breitHoch)
    }
}
