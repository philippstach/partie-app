// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSchocken

/// Spielt jede Partie aus `Shared/regeltests/partien` zweimal nach:
/// (a) mit den aufgezeichneten Aktionen, (b) mit den Computer-Strategien.
@Suite("Partien")
struct PartienTests {
    typealias JSON = Regeltests.JSON

    @Test func dateienVorhanden() throws {
        #expect(try Regeltests.partien().count >= 7)
    }

    @Test func nachspielenMitAktionen() throws {
        for (name, p) in try Regeltests.partien() { try spiele(name, p, computer: false) }
    }

    @Test func nachspielenMitStrategien() throws {
        for (name, p) in try Regeltests.partien() { try spiele(name, p, computer: true) }
    }

    /// Der aufgebaute Rundenverlauf muss genau `erwartet.haelften[i].runden[j]` entsprechen (SPEZIFIKATION 13.2).
    private func pruefeVerlauf(_ e: RundenEintrag, _ r: JSON, _ tag: String) throws {
        #expect(e.beginner == r["beginner"] as? Int, "\(tag) Verlauf beginner")
        #expect(e.verlierer == r["verlierer"] as? Int, "\(tag) Verlauf verlierer")
        #expect(e.gewinner == r["gewinner"] as? Int, "\(tag) Verlauf gewinner")
        #expect(e.deckel == r["deckel"] as? Int, "\(tag) Verlauf deckel")
        #expect(e.ausStock == r["ausStock"] as? Bool, "\(tag) Verlauf ausStock")
        #expect(e.stock == r["stock"] as? Int, "\(tag) Verlauf stock")
        #expect(e.stand == r["stand"] as? [Int], "\(tag) Verlauf stand")
        #expect(e.raus == r["raus"] as? [Int], "\(tag) Verlauf raus")
        let zuege = [JSON](r["zuege"])
        #expect(e.zuege.count == zuege.count, "\(tag) Verlauf Züge")
        for (zp, zd) in zip(e.zuege, zuege) {
            #expect(zp.spieler == zd["spieler"] as? Int, "\(tag) Verlauf spieler")
            #expect(zp.wuerfel == zd["wuerfel"] as? [Int], "\(tag) Verlauf würfel")
            #expect(zp.ergebnis.wuerfe == zd["wuerfe"] as? Int, "\(tag) Verlauf würfe")
            #expect(zp.ergebnis.wertung == (try Regeltests.wertung(zd["wertung"])), "\(tag) Verlauf wertung")
            let soll = try [JSON](zd["aktionen"]).map { try Regeltests.decode(Aktion.self, $0) }
            #expect(zp.aktionen == soll, "\(tag) Verlauf aktionen")
        }
    }

    private func spiele(_ name: String, _ p: JSON, computer: Bool) throws {
        let opt = try Regeltests.optionen(p["optionen"])
        let strategien = (p["strategien"] as! [String]).map { Strategie(rawValue: $0)! }
        let namen = strategien.indices.map { "S\($0)" }
        var quelle = ListenQuelle(p["wuerfel"] as! [Int])
        let erwartet = p["erwartet"] as! JSON
        let haelften = [JSON](erwartet["haelften"])
        var z = Spielzustand(namen: namen, strategien: strategien, optionen: opt, beginner: p["beginner"] as! Int)
        let tag = "\(name) \(computer ? "Strategien" : "Aktionen")"

        for (hi, h) in haelften.enumerated() {
            #expect(z.haelfte.spieler == h["spieler"] as? [Int], "\(tag) Hälfte \(hi)")
            #expect(z.haelfte.beginner == h["beginner"] as? Int, "\(tag) Hälfte \(hi)")
            for (ri, r) in [JSON](h["runden"]).enumerated() {
                let rt = "\(tag) Hälfte \(hi) Runde \(ri)"
                #expect(z.runde.beginner == r["beginner"] as? Int, "\(rt)")
                for (zi, zd) in [JSON](r["zuege"]).enumerated() {
                    let zt = "\(rt) Zug \(zi)"
                    #expect(z.aktuellerSpieler == zd["spieler"] as? Int, "\(zt)")
                    z.wuerfeln(&quelle)
                    if z.phase == .zugEnde { z.zugWeiter() }
                    if computer {
                        let strategie = z.strategien[z.aktuellerSpieler ?? 0]
                        var aktionen: [Aktion] = []
                        while z.zugLaeuft {
                            let a = Computer.entscheide(strategie == .mensch ? .einfach : strategie, z.lage!)
                            aktionen.append(a)
                            z.fuehreAus(a, &quelle)
                            if z.phase == .zugEnde { z.zugWeiter() }
                            if aktionen.count > 5 { break }
                        }
                        let soll = try [JSON](zd["aktionen"]).map { try Regeltests.decode(Aktion.self, $0) }
                        #expect(aktionen == soll, "\(zt)")
                    } else {
                        for a in [JSON](zd["aktionen"]) {
                            #expect(z.zugLaeuft, "\(zt)")
                            z.fuehreAus(try Regeltests.decode(Aktion.self, a), &quelle)
                            if z.phase == .zugEnde { z.zugWeiter() }
                        }
                    }
                    #expect(!z.zugLaeuft, "\(zt)")
                    let letzter = try #require(z.runde.zuege.last)
                    #expect(letzter.wuerfel == zd["wuerfel"] as? [Int], "\(zt)")
                    #expect(letzter.ergebnis.wuerfe == zd["wuerfe"] as? Int, "\(zt)")
                    #expect(letzter.ergebnis.wertung == (try Regeltests.wertung(zd["wertung"])), "\(zt)")
                }
                #expect(z.phase == .rundenwertung, "\(rt)")
                let a = try #require(z.runde.ausgang)
                #expect(a.verlierer == r["verlierer"] as? Int, "\(rt)")
                #expect(a.gewinner == r["gewinner"] as? Int, "\(rt)")
                #expect(a.deckel == r["deckel"] as? Int, "\(rt)")
                #expect(a.ausStock == r["ausStock"] as? Bool, "\(rt)")
                #expect(z.haelfte.stock == r["stock"] as? Int, "\(rt)")
                #expect(z.haelfte.stand == r["stand"] as? [Int], "\(rt)")
                #expect(z.haelfte.raus == r["raus"] as? [Int], "\(rt)")
                try pruefeVerlauf(z.verlaeufe[hi].runden[ri], r, "\(rt)")
                z.rundeWeiter()
            }
            #expect(z.verlaeufe[hi].runden.count == [JSON](h["runden"]).count, "\(tag) Hälfte \(hi) Verlauf")
            #expect(z.haelftenVerlierer.last == h["verlierer"] as? Int, "\(tag) Hälfte \(hi)")
            if z.phase == .haelfteVorbei { z.haelfteWeiter() }
        }
        #expect(z.phase == .partieVorbei, "\(tag)")
        #expect(z.partieVerlierer == erwartet["verlierer"] as? Int, "\(tag)")
        #expect(!quelle.ueberzogen, "\(tag) Würfelfolge zu kurz")
        #expect(quelle.verbraucht == quelle.folge.count, "\(tag) Würfel nicht aufgebraucht")
    }

    /// Echte Würfel (SPEZIFIKATION 15.2): In Partie 01 tippt Spieler 0 seine Würfe ein, statt sie aus der Quelle zu ziehen.
    /// Das Ergebnis muss identisch sein, und die Quelle verbraucht entsprechend weniger Würfel.
    @Test func echteWuerfelSpieler0() throws {
        let (name, p) = try #require(try Regeltests.partien().first { $0.name.hasPrefix("01") })
        let opt = try Regeltests.optionen(p["optionen"])
        let strategien = (p["strategien"] as! [String]).map { Strategie(rawValue: $0)! }
        let namen = strategien.indices.map { "S\($0)" }
        let folge = p["wuerfel"] as! [Int]
        let haelften = [JSON]((p["erwartet"] as! JSON)["haelften"])

        /// Spielt die Partie mit den aufgezeichneten Aktionen nach. `getippt`: die Würfe von Spieler 0 (nur bei `eingabe`
        /// werden sie eingetippt). Beim normalen Lauf wird aufgezeichnet, welche Stellen der Folge Spieler 0 gezogen hat.
        func spiele(_ quelle: inout ListenQuelle, getippt: inout [[Int]], gezogen: inout Set<Int>, eingabe: Bool, schnell: Bool = false) throws -> Spielzustand {
            var z = Spielzustand(namen: namen, strategien: strategien, optionen: opt, beginner: p["beginner"] as! Int,
                                 wuerfelModus: eingabe ? [.echt, .app, .app] : nil)
            var lesen = 0
            var aufgezeichnet: [[Int]] = []
            func merke(_ von: Int, _ bis: Int, _ spieler: Int) {
                guard spieler == 0, !eingabe, bis > von else { return }
                gezogen.formUnion(von..<bis)
                aufgezeichnet.append(Array(folge[von..<bis]))
            }
            for h in haelften {
                for r in [JSON](h["runden"]) {
                    for zd in [JSON](r["zuege"]) {
                        let spieler = zd["spieler"] as! Int
                        let tippt = eingabe && spieler == 0
                        if schnell && spieler == 0 {
                            // Schnelleingabe: nur Endwürfel, Würfe und „aus einem Wurf“ (Straße/General nur dann, wenn so gewertet)
                            let w = zd["wuerfel"] as! [Int]
                            let art = (zd["wertung"] as! JSON)["art"] as! String
                            let ein = !(Spielzustand.fragtNachEinemWurf(w, optionen: opt) && art == "zahl")
                            let ok = z.endergebnis(wuerfel: w, wuerfe: zd["wuerfe"] as! Int, ausEinemWurf: ein)
                            #expect(ok, "\(name) Schnelleingabe")
                            continue
                        }
                        let davor = quelle.verbraucht
                        if tippt { z.wuerfeln(eingabe: getippt[lesen]); lesen += 1 } else { z.wuerfeln(&quelle) }
                        merke(davor, quelle.verbraucht, spieler)
                        for a in [JSON](zd["aktionen"]) {
                            let aktion = try Regeltests.decode(Aktion.self, a)
                            let vor = quelle.verbraucht
                            if case let .weiter(hl, u) = aktion, tippt {
                                z.weiter(herauslegen: hl, umdrehen: u, eingabe: getippt[lesen]); lesen += 1
                            } else {
                                z.fuehreAus(aktion, &quelle)
                                merke(vor, quelle.verbraucht, spieler)
                            }
                            if z.phase == .zugEnde { z.zugWeiter() }
                        }
                        if z.phase == .zugEnde { z.zugWeiter() }
                    }
                    z.rundeWeiter()
                }
                if z.phase == .haelfteVorbei { z.haelfteWeiter() }
            }
            if !eingabe { getippt = aufgezeichnet }
            return z
        }

        var q1 = ListenQuelle(folge)
        var getippt: [[Int]] = []
        var gezogen = Set<Int>()
        let z1 = try spiele(&q1, getippt: &getippt, gezogen: &gezogen, eingabe: false)
        #expect(q1.verbraucht == folge.count && !q1.ueberzogen, "\(name) Normaldurchlauf")
        #expect(!gezogen.isEmpty)

        // Zweiter Lauf: Die Würfe von Spieler 0 fehlen in der Quelle, er tippt sie ein.
        let rest = folge.indices.filter { !gezogen.contains($0) }.map { folge[$0] }
        var q2 = ListenQuelle(rest)
        var unbenutzt = Set<Int>()
        let z2 = try spiele(&q2, getippt: &getippt, gezogen: &unbenutzt, eingabe: true)
        #expect(!q2.ueberzogen, "\(name) Quelle zu kurz")
        #expect(q2.verbraucht == folge.count - gezogen.count, "\(name) Quelle verbraucht \(q2.verbraucht)")
        #expect(z2.partieVerlierer == z1.partieVerlierer)
        #expect(z2.haelftenVerlierer == z1.haelftenVerlierer)
        #expect(z2.verlaeufe == z1.verlaeufe, "\(name) Verlauf gleich")

        // Dritter Lauf: Spieler 0 trägt jeden Zug als Endergebnis ein (Schnelleingabe), die Quelle fehlt seine Würfe ebenfalls.
        var q3 = ListenQuelle(rest)
        var unbenutzt3 = Set<Int>()
        var dummy: [[Int]] = []
        let z3 = try spiele(&q3, getippt: &dummy, gezogen: &unbenutzt3, eingabe: true, schnell: true)
        #expect(!q3.ueberzogen && q3.verbraucht == folge.count - gezogen.count, "\(name) Schnelleingabe verbraucht \(q3.verbraucht)")
        #expect(z3.partieVerlierer == z1.partieVerlierer && z3.haelftenVerlierer == z1.haelftenVerlierer)
        for (a, b) in zip(z3.verlaeufe, z1.verlaeufe) {
            #expect(a.runden.map(\.verlierer) == b.runden.map(\.verlierer))
            #expect(a.runden.map(\.deckel) == b.runden.map(\.deckel))
            #expect(a.runden.map(\.stand) == b.runden.map(\.stand))
            // Beim Schnelleingeben des Spielers 0 fehlen seine Aktionen im Verlauf (SPEZIFIKATION 15.3)
            for r in a.runden { for zug in r.zuege where zug.spieler == 0 { #expect(zug.aktionen.isEmpty) } }
        }
    }
}
