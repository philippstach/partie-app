// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSchocken

/// Spielt viele zufällige Partien durch (alle Optionen, 2–6 Spieler, Menschen mit zufälligen erlaubten Zügen,
/// echte Würfel mit Schnelleingabe, Computer einfach und gut) und prüft nach jedem Schritt die Grundregeln.
@Suite("Simulation")
struct SimulationTests {
    struct Zufall {
        var s: UInt64
        mutating func next(_ n: Int) -> Int {
            s = s &* 6364136223846793005 &+ 1442695040888963407
            return Int((s >> 33) % UInt64(n))
        }
    }

    /// Eine Partie bis zum Ende. Gibt die Zahl der Schritte zurück.
    static func spiele(seed: UInt64, rundreise: Bool) throws -> (schritte: Int, z: Spielzustand) {
        var r = Zufall(s: seed &* 7919 &+ 17)
        let n = 2 + r.next(5)
        let strategien = (0..<n).map { _ in Strategie.allCases[r.next(3)] }
        let opt = Optionen(jule: r.next(2) == 0, herauslegen: r.next(2) == 0 ? .einsen : .beliebig,
                           sechsenUmdrehen: r.next(4) != 0, deckel: r.next(2) == 0 ? 13 : 15,
                           spiellaenge: r.next(3) == 0 ? .haelfte : .partie)
        let echt = (0..<n).map { _ in r.next(3) == 0 ? WuerfelModus.echt : .app }
        var z = Spielzustand(namen: (0..<n).map { "S\($0)" }, strategien: strategien, optionen: opt,
                             beginner: r.next(n), wuerfelModus: echt)
        var q = SeedQuelle(seed: seed)
        var schritte = 0
        while z.phase != .partieVorbei {
            schritte += 1
            #expect(schritte < 20000, "Partie \(seed) endet nicht")
            if schritte >= 20000 { break }
            let h = z.haelfte
            #expect(h.stock + h.deckel.reduce(0, +) == h.gesamt, "Partie \(seed): Deckel gehen verloren")
            #expect(h.deckel.allSatisfy { $0 >= 0 }, "Partie \(seed): negative Deckel")
            if let a = z.aktuellerSpieler {
                #expect(!h.raus.contains(a), "Partie \(seed): ausgeschiedener Spieler ist dran")
                #expect(h.spieler.contains(a))
            }
            switch z.phase {
            case .haelfteVorbei: z.haelfteWeiter()
            case .rundenwertung: z.rundeWeiter()
            case .zugEnde: z.zugWeiter()
            case .partieVorbei: break
            case .vorWurf:
                let s = z.aktuellerSpieler!
                if z.wuerfelModus[s] == .echt, r.next(2) == 0 {
                    let w = (0..<3).map { _ in 1 + r.next(6) }
                    let ok = z.endergebnis(wuerfel: w, wuerfe: 1 + r.next(z.runde.maxWuerfe), ausEinemWurf: r.next(2) == 0)
                    #expect(ok)
                } else if z.wuerfelModus[s] == .echt {
                    z.wuerfeln(eingabe: (0..<3).map { _ in 1 + r.next(6) })
                } else {
                    z.wuerfeln(&q)
                }
            case .nachWurf:
                let zuege = z.runde.zug!.moeglicheZuege()
                let wahl = r.next(zuege.count + 1)
                if wahl == zuege.count {
                    z.stehen()
                } else {
                    let w = zuege[wahl]
                    let s = z.aktuellerSpieler!
                    if z.wuerfelModus[s] == .echt {
                        let k = 3 - z.runde.zug!.draussen.count - w.herauslegen.count - w.umdrehen
                        let werte = (0..<k).map { _ in 1 + r.next(6) }
                        let ok = z.weiter(herauslegen: w.herauslegen, umdrehen: w.umdrehen, eingabe: werte)
                        #expect(ok)
                    } else {
                        let ok = z.weiter(herauslegen: w.herauslegen, umdrehen: w.umdrehen, &q)
                        #expect(ok)
                    }
                }
            case .computer:
                if let lage = z.lage {
                    let s = z.aktuellerSpieler!
                    let a = Computer.entscheide(z.strategien[s], lage)
                    let ok = z.fuehreAus(a, &q)
                    #expect(ok, "Partie \(seed): Computer wählt unerlaubten Zug \(a)")
                } else {
                    z.wuerfeln(&q)
                }
            }
            if rundreise && schritte % 3 == 0 {
                let daten = try JSONEncoder().encode(Spielstand(zustand: z, quelle: q))
                let zurueck = try JSONDecoder().decode(Spielstand.self, from: daten)
                #expect(zurueck.zustand == z, "Partie \(seed): Rundreise ändert den Zustand")
                #expect(zurueck.quelle == q)
            }
        }
        // am Ende
        #expect(z.partieVerlierer != nil)
        #expect(z.haelftenVerlierer.count >= 1 && z.haelftenVerlierer.count <= 3)
        #expect(z.verlaeufe.count == z.haelftenVerlierer.count)
        return (schritte, z)
    }

    @Test func zufallspartien() throws {
        for seed in 1...150 { _ = try Self.spiele(seed: UInt64(seed), rundreise: seed <= 25) }
    }

    @Test func gleicherSeedGleichesErgebnis() throws {
        let a = try Self.spiele(seed: 42, rundreise: false).z
        let b = try Self.spiele(seed: 42, rundreise: false).z
        #expect(a == b)
    }
}
