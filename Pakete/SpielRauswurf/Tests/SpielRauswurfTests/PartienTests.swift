// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

/// Spielt jede Partie aus `Shared/regeltests/partien` zweimal nach:
/// (a) mit den aufgezeichneten Zügen (wie ein Mensch), (b) mit den Computer-Strategien.
@Suite("Partien")
struct PartienTests {
    typealias JSON = Regeltests.JSON

    @Test func dateienVorhanden() throws {
        #expect(try Regeltests.partien().count >= 11)
    }

    @Test func nachspielenMitAufgezeichnetenZuegen() throws {
        for (name, p) in try Regeltests.partien() { try spiele(name, p, computer: false) }
    }

    @Test func nachspielenMitStrategien() throws {
        for (name, p) in try Regeltests.partien() { try spiele(name, p, computer: true) }
    }

    private func spiele(_ name: String, _ p: JSON, computer: Bool) throws {
        let modus = computer ? "Strategien" : "Aufzeichnung"
        let opt = try Regeltests.optionen(p["optionen"])
        let sitze = p["sitze"] as! [Int]
        let strategien = (p["strategien"] as! [String]).map { Strategie(rawValue: $0)! }
        var quelle = ListenQuelle(p["wuerfel"] as! [Int])
        let erwartet = p["erwartet"] as! JSON
        var partie = Partie.neu(sitze: sitze, beginner: p["beginner"] as! Int, optionen: opt)

        for (i, e) in [JSON](erwartet["zuege"]).enumerated() {
            let kopf = "\(name) (\(modus)), Spielzug \(i)"
            let spieler = e["spieler"] as! Int
            let soll = try Regeltests.decode([Wurf].self, e["wuerfe"])
            guard partie.amZug == spieler else { Issue.record("\(kopf): am Zug ist \(partie.amZug), erwartet \(spieler)"); return }
            let vorher = partie.verlauf.count
            var n = 0
            while partie.verlauf.count == vorher && n < 100 {
                partie.wuerfeln(&quelle)
                switch partie.spielzug.stand {
                case .wahl:
                    let erlaubt = partie.spielzug.erlaubt
                    let zug: Zug
                    if computer {
                        zug = Computer.entscheide(strategien[spieler], partie.lage, spieler, erlaubt, menschen: Set((p["menschen"] as? [Int]) ?? []))
                    } else {
                        guard n < soll.count, let z = soll[n].zug else { Issue.record("\(kopf): Wurf \(n) hat keinen aufgezeichneten Zug"); return }
                        zug = z
                    }
                    guard erlaubt.contains(zug) else { Issue.record("\(kopf): Zug \(zug) nicht erlaubt"); return }
                    partie.waehle(zug)
                case .verfallen: partie.weiter()
                default: Issue.record("\(kopf): unerwarteter Stand"); return
                }
                n += 1
            }
            let ist = partie.verlauf.last
            let sollEintrag = Verlaufseintrag(spieler: spieler, wuerfe: soll,
                                              figuren: try Regeltests.decode([[Int]].self, e["figuren"]))
            guard partie.verlauf.count == vorher + 1, ist == sollEintrag else {
                Issue.record("\(kopf): weicht ab. ist \(String(describing: ist)), soll \(sollEintrag)")
                return
            }
        }
        #expect(partie.platzierung == erwartet["platzierung"] as? [Int], "\(name) (\(modus)): Platzierung")
        #expect(partie.vorbei, "\(name) (\(modus)): vorbei")
        #expect(quelle.verbraucht == quelle.folge.count, "\(name) (\(modus)): Würfel nicht genau aufgebraucht")
        #expect(!quelle.ueberzogen, "\(name) (\(modus)): Würfel überzogen")
    }
}
