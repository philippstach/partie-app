// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SpieleKern
@testable import SpielRauswurf

@Suite("Teams 2 gegen 2")
struct TeamTests {
    @Test func teamsGeltenNurMitVierSpielern() {
        var opt = Optionen(); opt.teams = true
        #expect(Partie.neu(sitze: [0, 1, 2, 3], beginner: 0, optionen: opt).teamsAktiv)
        #expect(!Partie.neu(sitze: [0, 2], beginner: 0, optionen: opt).teamsAktiv)
        #expect(!Partie.neu(sitze: [0, 1, 2, 3], beginner: 0, optionen: .standard).teamsAktiv)
        #expect(Partie.team(von: 0) == Partie.team(von: 2) && Partie.team(von: 1) == Partie.team(von: 3) && Partie.team(von: 0) != Partie.team(von: 1))
    }

    /// RT-040: Der Partner (gegenübersitzend) wird nicht geschlagen, Gegner schon; ohne Teams bleibt alles beim Alten.
    @Test func partnerWirdNichtGeschlagen() {
        var opt = Optionen(); opt.teams = true
        // Spieler 0 steht auf relativ 5 (abs 5), Partner 2 und Gegner 1 jeweils so, dass ein Wurf von 1 ihr Feld trifft.
        func lage(ziel: Int) -> Lage {
            var l = Lage.neu(sitze: [0, 1, 2, 3], opt)
            l.figuren[0][0] = 5
            let abs = 6
            l.figuren[ziel][0] = ((abs - ziel * Brettmass.abstand) % Brettmass.lauf + Brettmass.lauf) % Brettmass.lauf
            return l
        }
        let gegenPartner = lage(ziel: 2)
        #expect(gegenPartner.besetzer(6)?.spieler == 2)
        #expect(!gegenPartner.alleZuege(0, 1, opt).contains { $0.von == 5 })
        let gegenGegner = lage(ziel: 1)
        #expect(gegenGegner.alleZuege(0, 1, opt).contains { $0.von == 5 && $0.schlaegt == 1 })
        #expect(gegenPartner.alleZuege(0, 1, .standard).contains { $0.von == 5 && $0.schlaegt == 2 })
    }

    @Test func ganzePartienEndenMitBeidenPartnernImZiel() {
        var opt = Optionen(); opt.teams = true
        for spiel in 0 ..< 30 {
            var quelle = SeedQuelle(seed: UInt64(77 + spiel))
            var partie = Partie.neu(sitze: [0, 1, 2, 3], beginner: quelle.naechster(unter: 4), optionen: opt)
            let strategien: [Strategie] = (0 ..< 4).map { ($0 + spiel) % 2 == 0 ? .gut : .einfach }
            var schritte = 0
            while !partie.vorbei && schritte < 80_000 {
                schritte += 1
                partie.wuerfeln(&quelle)
                if partie.spielzug.stand == .wahl {
                    let p = partie.amZug
                    partie.waehle(Computer.entscheide(strategien[p], partie.lage, p, partie.spielzug.erlaubt))
                } else if partie.spielzug.stand == .verfallen { partie.weiter() }
            }
            #expect(partie.vorbei, "Teampartie \(spiel) endet nicht")
            guard let erster = partie.platzierung.first else { Issue.record("keine Platzierung"); continue }
            let gewinner = Partie.team(von: erster)
            // Beide Spieler des Gewinnerteams sind fertig und stehen vorn
            #expect(partie.lage.fertig(gewinner) && partie.lage.fertig(gewinner + 2))
            #expect(partie.platzierung.prefix(2).allSatisfy { Partie.team(von: $0) == gewinner })
            #expect(Set(partie.platzierung).count == partie.platzierung.count)
        }
    }

    @Test func optionenAlterSpielstandOhneTeamsLaedt() throws {
        let o = try JSONDecoder().decode(Optionen.self, from: Data("{}".utf8))
        #expect(o.teams == false)
        var neu = Optionen(); neu.teams = true
        #expect(try JSONDecoder().decode(Optionen.self, from: JSONEncoder().encode(neu)).teams)
    }

    @Test func endeMeldetPartnerAlsGemeinsameSieger() {
        var opt = Optionen(); opt.teams = true
        let namen = ["Anna", "Ben", "Clara", "Dora"]
        let t = namen.map { SpielTeilnehmer(name: $0, computer: true) }
        for seed in 1 ... 6 {
            let s = NeuLogik.spieler(t, computer: .gut, echteWuerfel: false)
            var z = Spielzustand(spieler: s, optionen: opt, seed: UInt64(seed))
            var schritte = 0
            while z.phase != Spielzustand.Phase.vorbei && schritte < 80_000 { z.computerSchritt(); schritte += 1 }
            #expect(z.phase == Spielzustand.Phase.vorbei)
            let e = NeuLogik.ende(z)
            #expect(e.plaetze == [1, 1, 2, 2], "Teamplätze Seed \(seed)")
            #expect(Set(e.reihenfolge).count == 4)
            let gewinner = Partie.team(von: z.partie.platzierung.first!)
            #expect(Set(e.reihenfolge.prefix(2)) == Set([namen[gewinner], namen[gewinner + 2]]))
        }
    }
}
