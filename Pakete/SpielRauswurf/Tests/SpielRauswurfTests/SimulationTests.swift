// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

/// Viele ganze Partien mit allen Spielarten und Strategien: Sie enden immer, und die Lage bleibt gültig.
@Suite("Simulation")
struct SimulationTests {
    static func pruefe(_ lage: Lage, _ opt: Optionen) -> String? {
        var belegt = Set<Int>()
        for (p, fs) in lage.figuren.enumerated() {
            if fs.count != opt.figuren { return "falsche Figurenzahl" }
            var eigene = Set<Int>()
            for r in fs {
                if r < -1 || r > Brettmass.zielLetztes { return "Position \(r) ungültig" }
                if r >= 0 && !eigene.insert(r).inserted { return "zwei eigene Figuren auf \(r)" }
                if r >= 0 && r < Brettmass.lauf && !belegt.insert(feld(lage.sitze[p], r)).inserted { return "zwei Figuren auf einem Feld" }
            }
        }
        return nil
    }

    @Test func vieleGanzePartien() {
        var spielarten = Spielart.allCases.map(\.optionen)
        var alle = Optionen(); alle.spielende = .alle; spielarten.append(alle)
        var ohneAlles = Optionen(); ohneAlles.rausPflicht = false; ohneAlles.startfeldRaeumen = false; ohneAlles.sechsNochmal = false; spielarten.append(ohneAlles)
        var fertig = 0
        for (i, opt) in spielarten.enumerated() {
            for spiel in 0 ..< 25 {
                let n = 2 + (spiel % 3)
                let sitze = n == 2 ? [0, 2] : Array(0 ..< n)
                var quelle = SeedQuelle(seed: UInt64(1000 * i + spiel))
                let beginner = quelle.naechster(unter: n)
                var partie = Partie.neu(sitze: sitze, beginner: beginner, optionen: opt)
                let strategien: [Strategie] = (0 ..< n).map { ($0 + spiel) % 2 == 0 ? .gut : .einfach }
                var schritte = 0
                while !partie.vorbei && schritte < 60_000 {
                    schritte += 1
                    partie.wuerfeln(&quelle)
                    if partie.spielzug.stand == .wahl {
                        let p = partie.amZug
                        partie.waehle(Computer.entscheide(strategien[p], partie.lage, p, partie.spielzug.erlaubt))
                    } else if partie.spielzug.stand == .verfallen { partie.weiter() }
                    if let fehler = Self.pruefe(partie.lage, opt) { Issue.record("\(fehler) (Regeln \(i), Partie \(spiel))"); return }
                }
                #expect(partie.vorbei, "Partie \(spiel) mit Regeln \(i) endet nicht")
                if partie.vorbei {
                    fertig += 1
                    #expect(partie.lage.fertig(partie.platzierung[0]))
                    #expect(Set(partie.platzierung).count == partie.platzierung.count)
                    if opt.spielende == .alle { #expect(partie.platzierung.count == n) }
                }
            }
        }
        #expect(fertig == spielarten.count * 25)
    }
}
