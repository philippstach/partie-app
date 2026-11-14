// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielViererreihe

@Suite("Geübt")
struct GeuebtTests {
    typealias JSON = Regeltests.JSON

    @Test func regeltests() throws {
        let faelle = Regeltests.faelle(try Regeltests.laden("geuebt.json"))
        #expect(faelle.count == 21)
        for f in faelle {
            let name = f["name"] as! String
            let p = try Regeltests.partie(f)
            let e = f["erwartet"] as! JSON
            var quelle = ListenQuelle(Regeltests.ints(f["zufall"]))
            let spalte = Computer.waehle(.geuebt, p, zufall: &quelle)
            #expect(spalte == e["spalte"] as? Int, "\(name): spalte")
            #expect(quelle.index == e["zufallGezogen"] as? Int, "\(name): zufallGezogen")
            #expect(!quelle.ueberzogen, "\(name): Zufall überzogen")
            if let erwartet = e["werte"] as? [Any] {
                let w = GeuebterComputer.werte(p)
                #expect((0..<Partie.spalten).map { w[$0] } == erwartet.map { $0 as? Int }, "\(name): werte")
            }
        }
    }

    /// Spielt 20 Partien (Seeds 1–20) zwischen zwei Stufen; `a` ist bei ungeraden Seeds Gold, sonst Blau.
    /// Gibt (Siege von a, Siege von b, unentschieden) zurück.
    private func serie(a: Stufe, b: Stufe, starkTiefe: Int = 8) throws -> (a: Int, b: Int, remis: Int) {
        var siegeA = 0, siegeB = 0, remis = 0
        for seed in 1...20 {
            var q = SplitMix64(seed: UInt64(seed))
            let spielerA = seed % 2 == 1 ? 1 : 2
            var p = try Partie(beginner: 1)
            while p.status == .laeuft {
                let stufe = p.naechsterSpieler == spielerA ? a : b
                var leer = ListenQuelle([])
                let s = stufe == .stark
                    ? Computer.waehle(.stark, p, zufall: &leer, zeitlimit: nil, maxTiefe: starkTiefe)
                    : Computer.waehle(stufe, p, zufall: &q)
                try p.einwerfen(s)
            }
            if p.gewinner == spielerA { siegeA += 1 } else if p.gewinner == nil { remis += 1 } else { siegeB += 1 }
        }
        return (siegeA, siegeB, remis)
    }

    @Test func geuebtGegenMittelGewinntMehrAlsSieVerliert() throws {
        let erg = try serie(a: .geuebt, b: .mittel)
        #expect(erg.a > erg.b, "geübt gegen mittel: \(erg)")
    }

    @Test func starkGegenGeuebtGewinntMindestens14() throws {
        let erg = try serie(a: .stark, b: .geuebt)
        #expect(erg.a >= 14, "stark gegen geübt: \(erg)")
    }

    @Test func geuebtGegenLeichtGewinntAlle() throws {
        let erg = try serie(a: .geuebt, b: .leicht)
        #expect(erg.a == 20, "geübt gegen leicht: \(erg)")
    }

    @Test func stufenReihenfolge() {
        #expect(Stufe.allCases == [.leicht, .mittel, .geuebt, .stark])
        #expect(Stufe.geuebt.rawValue == "geuebt")
    }
}
