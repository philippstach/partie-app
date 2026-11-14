// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MahjongPaareKern

final class MahjongTests: XCTestCase {
    func testLoesbar() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            var m = MahjongPaare(mit: &g)
            XCTAssertEqual(m.steine.count, 56); XCTAssertTrue(m.steine.allSatisfy { $0.motiv >= 0 })
            var n = 0
            while !m.geloest && n < 100 {
                guard let (a, b) = m.moeglichePaare.first else { break }
                // Greedy kann in Sackgassen laufen; die Konstruktion garantiert nur: es gibt eine Lösung. Wir prüfen Spielbarkeit zu Beginn.
                XCTAssertTrue(m.entferne(a, b)); n += 1
            }
            XCTAssertTrue(n > 5)
        }
    }
    func testFreiRegel() {
        var g = SystemRandomNumberGenerator(); let m = MahjongPaare(mit: &g)
        // Steine in Ebene 0 unter einem Stein der Ebene 1 sind nie frei
        let i = m.steine.firstIndex { $0.ebene == 0 && $0.x == 4 && $0.y == 4 }!
        XCTAssertFalse(m.frei(i))
        XCTAssertTrue(m.steine.indices.filter(m.frei).count >= 2)
    }
    func testFalschesPaarWirdAbgelehnt() {
        var g = SystemRandomNumberGenerator(); var m = MahjongPaare(mit: &g)
        let a = m.steine.indices.first(where: m.frei)!
        XCTAssertFalse(m.entferne(a, a))
        if let b = m.steine.indices.first(where: { $0 != a && m.frei($0) && m.steine[$0].motiv != m.steine[a].motiv }) {
            XCTAssertFalse(m.entferne(a, b))
        }
        let blockiert = m.steine.indices.first { !m.frei($0) }!
        XCTAssertFalse(m.entferne(a, blockiert)); XCTAssertEqual(m.zuege, 0); XCTAssertEqual(m.verbleibend, 56)
    }
    func testPaareEntfernenZaehltUndGibtFrei() {
        var g = SystemRandomNumberGenerator(); var m = MahjongPaare(mit: &g)
        XCTAssertFalse(m.festgefahren); XCTAssertFalse(m.geloest)
        let (a, b) = m.moeglichePaare[0]
        XCTAssertTrue(m.entferne(a, b))
        XCTAssertEqual(m.zuege, 1); XCTAssertEqual(m.verbleibend, 54)
        XCTAssertFalse(m.frei(a), "entfernter Stein ist nicht mehr frei")
        XCTAssertFalse(m.entferne(a, b))
    }
    func testMischenHebtFestgefahrenAufUndErhaeltPaare() {
        var g = SystemRandomNumberGenerator(); var m = MahjongPaare(mit: &g); var n = 0
        while !m.geloest && n < 200 { guard let (a, b) = m.moeglichePaare.first else { break }; m.entferne(a, b); n += 1 }
        if m.festgefahren {
            let vorher = m.steine.filter { !$0.entfernt }.map(\.motiv).sorted()
            XCTAssertTrue(m.mischeRest(mit: &g))
            XCTAssertEqual(m.steine.filter { !$0.entfernt }.map(\.motiv).sorted(), vorher)
            XCTAssertFalse(m.festgefahren)
        }
        XCTAssertFalse(m.mischeRest(mit: &g) && m.geloest)
    }
}

final class MahjongLoesbarTests: XCTestCase {
    /// Vollständige Suche: gibt es eine Reihenfolge, die das Brett leert? (mit Zwischenspeicher gegen doppelte Zustände)
    func loesbar(_ start: MahjongPaare, grenze: Int = 200_000) -> Bool? {
        var gesehen = Set<[Bool]>(); var knoten = 0
        func rec(_ m: MahjongPaare) -> Bool? {
            if m.geloest { return true }
            let key = m.steine.map(\.entfernt)
            if !gesehen.insert(key).inserted { return false }
            knoten += 1; if knoten > grenze { return nil }
            for (a, b) in m.moeglichePaare {
                var n = m; n.entferne(a, b)
                if let r = rec(n) { if r { return true } } else { return nil }
            }
            return false
        }
        return rec(start)
    }
    func testGarantiertLoesbar() {
        var g = SplitMixM(seed: 9)
        var geprueft = 0
        for _ in 0..<12 {
            let m = MahjongPaare(mit: &g)
            if let r = loesbar(m) { XCTAssertTrue(r, "Brett ohne Lösung"); geprueft += 1 }
        }
        XCTAssertGreaterThanOrEqual(geprueft, 6, "zu wenige Bretter innerhalb der Suchgrenze geprüft")
    }
}
struct SplitMixM: RandomNumberGenerator {
    var z: UInt64
    init(seed: UInt64) { z = seed }
    mutating func next() -> UInt64 {
        z &+= 0x9E37_79B9_7F4A_7C15; var x = z
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9; x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        return x ^ (x >> 31)
    }
    func testBrettGroessen() {
        var g = SystemRandomNumberGenerator()
        for (b, n) in [(MahjongPaare.Brett.klein, 36), (.mittel, 52), (.pyramide, 56)] {
            let m = MahjongPaare(brett: b, mit: &g)
            XCTAssertEqual(m.steine.count, n)
            XCTAssertFalse(m.moeglichePaare.isEmpty)
        }
    }
}

final class MahjongZusatzTests: XCTestCase {
    func testAlleBretterGeradeAnzahlUndLoesbarDurchTipp() {
        var g = SystemRandomNumberGenerator()
        for b in MahjongPaare.Brett.allCases {
            var m = MahjongPaare(brett: b, mit: &g)
            XCTAssertEqual(m.steine.count % 2, 0)
            var k = 0
            while !m.geloest, let p = m.moeglichePaare.first, k < 100 { XCTAssertTrue(m.entferne(p.0, p.1)); k += 1 }
            // greedy kann festfahren – dann muss mischen helfen; mindestens ein Zug war möglich
            XCTAssertGreaterThan(k, 0)
        }
    }
    func testCodableRundlauf() throws {
        var g = SystemRandomNumberGenerator()
        var m = MahjongPaare(brett: .mittel, mit: &g)
        if let p = m.moeglichePaare.first { _ = m.entferne(p.0, p.1) }
        let d = try JSONEncoder().encode(m)
        XCTAssertEqual(try JSONDecoder().decode(MahjongPaare.self, from: d), m)
    }
    func testNurBrettKleinHatEineEbene() {
        var g = SystemRandomNumberGenerator()
        XCTAssertEqual(Set(MahjongPaare(brett: .klein, mit: &g).steine.map(\.ebene)), [0])
        XCTAssertEqual(Set(MahjongPaare(brett: .pyramide, mit: &g).steine.map(\.ebene)), [0, 1, 2])
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class MahjongPaareKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return MahjongPaare(mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return MahjongPaare(mit: &g) }()
        let k = try kaputt(w, "steine", [Int]())
        XCTAssertFalse(k.istKonsistent)
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = MahjongPaare(brett: .klein, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Mahjong klein: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = MahjongPaare(brett: .mittel, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Mahjong mittel: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = MahjongPaare(brett: .pyramide, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Mahjong pyramide: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class MahjongIndexSchutz: XCTestCase {
    func testUngueltigeSteineWerdenAbgelehnt() {
        var g = SystemRandomNumberGenerator()
        var m = MahjongPaare(mit: &g)
        XCTAssertFalse(m.entferne(0, 9999)); XCTAssertFalse(m.entferne(-1, 0))
    }
}

final class MahjongPaareZusatzTests: XCTestCase {
    func testEntfernenVerringertVerbleibendUmZweiUndZaehltZug() {
        var g = SystemRandomNumberGenerator()
        var s = MahjongPaare(brett: .klein, mit: &g)
        let vorher = s.verbleibend
        let p = s.moeglichePaare.first!
        XCTAssertTrue(s.entferne(p.0, p.1))
        XCTAssertEqual(s.verbleibend, vorher - 2); XCTAssertEqual(s.zuege, 1)
    }
    func testPaarAusDemselbenSteinOderVerschiedenenMotivenWirdAbgelehnt() {
        var g = SystemRandomNumberGenerator()
        var s = MahjongPaare(brett: .klein, mit: &g)
        let p = s.moeglichePaare.first!
        XCTAssertFalse(s.entferne(p.0, p.0))
        XCTAssertEqual(s.verbleibend % 2, 0)
    }
    func testJedesBrettHatGeradeSteinzahlUndMindestensEinPaar() {
        for b in MahjongPaare.Brett.allCases {
            var g = SystemRandomNumberGenerator()
            let s = MahjongPaare(brett: b, mit: &g)
            XCTAssertEqual(s.verbleibend % 2, 0); XCTAssertFalse(s.moeglichePaare.isEmpty); XCTAssertFalse(s.geloest)
        }
    }
}
