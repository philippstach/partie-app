// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

/// Computer „lieb“ (SPEZIFIKATION 7.3), Regeltest `lieb.json`.
@Suite("Computer lieb")
struct LiebTests {
    typealias JSON = Regeltests.JSON

    @Test func einzelfaelle() throws {
        let faelle = [JSON](try Regeltests.laden("lieb.json")["faelle"])
        #expect(faelle.count >= 4)
        for f in faelle {
            let lage = try Regeltests.decode(Lage.self, f["lage"])
            let opt = try Regeltests.optionen(f["optionen"])
            let p = f["spieler"] as! Int, w = f["augen"] as! Int
            let menschen = Set(f["menschen"] as! [Int])
            let soll = f["erwartet"] as! JSON
            let name = "\(f["name"] ?? "")"
            let erlaubt = lage.moeglicheZuege(p, w, opt)
            #expect(erlaubt == (try Regeltests.decode([Zug].self, soll["erlaubt"])), "erlaubt: \(name)")
            #expect(erlaubt.map { Computer.bewerteLieb(lage, p, $0, menschen: menschen) } == soll["liebWerte"] as? [Int], "liebWerte: \(name)")
            #expect(Computer.entscheide(.lieb, lage, p, erlaubt, menschen: menschen) == (try Regeltests.decode(Zug.self, soll["lieb"])), "lieb: \(name)")
        }
    }

    @Test func ganzePartienMitMenschen() throws {
        let partien = [JSON](try Regeltests.laden("lieb.json")["partien"])
        #expect(!partien.isEmpty)
        for p in partien {
            let name = "\(p["name"] ?? "lieb")"
            let opt = try Regeltests.optionen(p["optionen"])
            let strategien = (p["strategien"] as! [String]).map { Strategie(rawValue: $0)! }
            let menschen = Set(p["menschen"] as! [Int])
            var quelle = ListenQuelle(p["wuerfel"] as! [Int])
            var partie = Partie.neu(sitze: p["sitze"] as! [Int], beginner: p["beginner"] as! Int, optionen: opt)
            let erwartet = p["erwartet"] as! JSON
            for (i, e) in [JSON](erwartet["zuege"]).enumerated() {
                let spieler = e["spieler"] as! Int
                let soll = try Regeltests.decode([Wurf].self, e["wuerfe"])
                guard partie.amZug == spieler else { Issue.record("\(name) Spielzug \(i): falscher Spieler"); return }
                let vorher = partie.verlauf.count
                var n = 0
                while partie.verlauf.count == vorher && n < 100 {
                    partie.wuerfeln(&quelle)
                    if partie.spielzug.stand == .wahl {
                        partie.waehle(Computer.entscheide(strategien[spieler], partie.lage, spieler, partie.spielzug.erlaubt, menschen: menschen))
                    } else { partie.weiter() }
                    n += 1
                }
                let sollEintrag = Verlaufseintrag(spieler: spieler, wuerfe: soll, figuren: try Regeltests.decode([[Int]].self, e["figuren"]))
                guard partie.verlauf.count == vorher + 1, partie.verlauf.last?.gleichWieRegeltest(sollEintrag) == true else {
                    Issue.record("\(name) Spielzug \(i): weicht ab"); return
                }
            }
            #expect(partie.platzierung == erwartet["platzierung"] as? [Int], "\(name): Platzierung")
            #expect(quelle.verbraucht == quelle.folge.count && !quelle.ueberzogen)
        }
    }

    @Test func werfenMenschenNurRausWennNichtsAnderes() {
        // Computer 0 (lieb), Mensch 1: mit zwei Zügen wählt er den ohne Rauswurf, mit nur dem Rauswurf schlägt er trotzdem
        let lage = Lage(sitze: [0, 1], figuren: [[5, 20, -1, -1], [37, -1, -1, -1]])
        let beide = lage.moeglicheZuege(0, 2)
        #expect(beide.count == 2 && beide.contains { $0.schlaegt == 1 })
        #expect(Computer.entscheide(.lieb, lage, 0, beide, menschen: [1]).schlaegt == nil)
        #expect(Computer.entscheide(.gut, lage, 0, beide, menschen: [1]).schlaegt == 1)
        let nur = beide.filter { $0.schlaegt != nil }
        #expect(Computer.entscheide(.lieb, lage, 0, nur, menschen: [1]).schlaegt == 1)
        // Computer als Opfer: lieb schlägt normal
        #expect(Computer.entscheide(.lieb, lage, 0, beide, menschen: []).schlaegt == 1)
    }
}
