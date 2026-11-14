// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import SpielSolitaer

/// Prüft jede Datei aus `Shared/regeltests/` vollständig – der Beweis, dass iOS wie die Referenz spielt.
final class RegeltestsTests: XCTestCase {
    func testZufall() throws {
        for f in try TestJSON.cases("zufall") {
            let seed = UInt64(f["seed"] as! String)!
            var rng = SplitMix64(seed: seed)
            let erwartet = (f["werte"] as! [String]).map { UInt64($0)! }
            XCTAssertEqual((0..<erwartet.count).map { _ in rng.next() }, erwartet, "Seed \(seed)")

            let below = f["below"] as! [String: Any]
            var rng2 = SplitMix64(seed: seed)
            let ns = below["n"] as! [Int]
            XCTAssertEqual(ns.map { rng2.below($0) }, below["werte"] as! [Int], "below, Seed \(seed)")

            XCTAssertEqual(Deal.shuffledDeck(seed: seed).map(\.shortName), f["gemischt"] as! [String], "gemischt, Seed \(seed)")
        }
    }

    func testGeben() throws {
        let faelle = try TestJSON.cases("geben")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let seed = UInt64(f["seed"] as! Int)
            let draw = f["ziehen"] as! Int
            XCTAssertEqual(Deal.deal(seed: seed, draw: draw), TestJSON.state(f["zustand"] as! [String: Any]), "Seed \(seed)")
        }
    }

    func testZuege() throws {
        let faelle = try TestJSON.cases("zuege")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = TestJSON.state(f["start"] as! [String: Any])
            let ergebnis = KlondikeRules.apply(start, TestJSON.move(f["zug"] as! [String: Any]))
            if f["erlaubt"] as! Bool {
                XCTAssertEqual(ergebnis, TestJSON.state(f["danach"] as! [String: Any]), titel)
            } else {
                XCTAssertNil(ergebnis, "\(titel): sollte unerlaubt sein")
            }
        }
    }

    func testTippen() throws {
        let faelle = try TestJSON.cases("tippen")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let start = TestJSON.state(f["start"] as! [String: Any])
            let ziel = KlondikeRules.tapTarget(start, from: TestJSON.place(f["quelle"] as! String), count: f["anzahl"] as! Int)
            let erwartet = (f["zug"] as? [String: Any]).map(TestJSON.move)
            XCTAssertEqual(ziel, erwartet, f["titel"] as! String)
        }
    }

    func testAutoAblegen() throws {
        let faelle = try TestJSON.cases("autoablegen")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let start = TestJSON.state(f["start"] as! [String: Any])
            XCTAssertEqual(KlondikeRules.autoFoundationMoves(start), TestJSON.moves(f["zuege"]), f["titel"] as! String)
        }
    }

    func testBeenden() throws {
        let faelle = try TestJSON.cases("beenden")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = TestJSON.state(f["start"] as! [String: Any])
            XCTAssertEqual(KlondikeRules.canAutoFinish(start), f["moeglich"] as! Bool, titel)
            if f["moeglich"] as! Bool {
                XCTAssertEqual(KlondikeRules.autoFinishMoves(start), TestJSON.moves(f["zuege"]), titel)
            }
        }
    }

    func testTipp() throws {
        let faelle = try TestJSON.cases("tipp")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = TestJSON.state(f["start"] as! [String: Any])
            let erwartet = (f["tipp"] as? [String: Any]).map(TestJSON.move)
            XCTAssertEqual(KlondikeRules.hint(start), erwartet, titel)
            XCTAssertEqual(KlondikeRules.isStuck(start), f["festgefahren"] as! Bool, titel)
        }
    }

    func testPartien() throws {
        let faelle = try TestJSON.cases("partien")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            var s = Deal.deal(seed: UInt64(f["seed"] as! Int), draw: f["ziehen"] as! Int)
            for (i, m) in TestJSON.moves(f["zuege"]).enumerated() {
                guard let n = KlondikeRules.apply(s, m) else { return XCTFail("\(titel): Zug \(i) \(m) unerlaubt") }
                s = n
            }
            XCTAssertEqual(s, TestJSON.state(f["ende"] as! [String: Any]), titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
        }
    }
}
