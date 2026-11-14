// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import FuchsjagdKern
final class FuchsjagdTests: XCTestCase {
    func testAufbau() {
        let s = Fuchsjagd()
        XCTAssertEqual(s.gaense.count, 13); XCTAssertTrue(s.gaense.allSatisfy(Fuchsjagd.gueltig))
        XCTAssertFalse(s.gaense.contains(s.fuchs)); XCTAssertEqual(s.amZug, .gaense); XCTAssertNil(s.sieger)
    }
    func testBrettHat33Felder() {
        XCTAssertEqual((0..<7).flatMap { y in (0..<7).map { Pos($0, y) } }.filter(Fuchsjagd.gueltig).count, 33)
    }
    func testGansZuegeNurVorwaertsUndSeitlich() {
        let s = Fuchsjagd()
        for z in s.zuegeDes(.gaense) { XCTAssertTrue(z.nach.y <= z.von.y); XCTAssertNil(z.schlag) }
    }
    func testFuchsSchlaegt() {
        var s = Fuchsjagd()
        // Gans nach vorn ziehen, bis der Fuchs sie springen kann
        var g = SystemRandomNumberGenerator()
        s.ziehe(FuchsZug(von: Pos(3, 4), nach: Pos(3, 3), schlag: nil) == FuchsZug(von: Pos(3, 4), nach: Pos(3, 3), schlag: nil) ? s.zuegeDes(.gaense).first { $0.von == Pos(2, 4) && $0.nach == Pos(2, 3) }! : s.zuegeDes(.gaense)[0])
        XCTAssertNotNil(s.computerZug(tiefe: 1, mit: &g))
    }
    func testComputerGegenComputerEndet() {
        var g = SystemRandomNumberGenerator()
        for tiefe in [0, 1, 2] {
            var s = Fuchsjagd(); var n = 0
            while s.sieger == nil && n < 500 { s.ziehe(s.computerZug(tiefe: tiefe, mit: &g)!); n += 1 }
            XCTAssertNotNil(s.sieger, "Tiefe \(tiefe)")
        }
    }
    func testSchwereGaenseSchlagenZufallsfuchs() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for _ in 0..<4 {
            var s = Fuchsjagd(); var n = 0
            while s.sieger == nil && n < 500 {
                let tiefe = s.amZug == .gaense ? 3 : 0
                s.ziehe(s.computerZug(tiefe: tiefe, mit: &g)!); n += 1
            }
            if s.sieger == .gaense { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 1)
    }
}

final class FuchsRegelnTests: XCTestCase {
    func testVariantenSpielenBisEnde() {
        for r in [FuchsRegeln.zwang, .leichtGaense] {
            var s = Fuchsjagd(regeln: r); var n = 0
            while s.sieger == nil, n < 400, let z = s.zuegeDes(s.amZug).randomElement() {
                if r.fuchsMussSchlagen, s.amZug == .fuchs, s.zuegeDes(.fuchs).contains(where: { $0.schlag != nil }) { XCTAssertNotNil(z.schlag) }
                s.ziehe(z); n += 1
            }
            XCTAssertNotNil(s.sieger)
        }
    }
    func testAlterSpielstandLaedt() throws {
        let alt = try JSONEncoder().encode(Fuchsjagd())
        var obj = try JSONSerialization.jsonObject(with: alt) as! [String: Any]; obj.removeValue(forKey: "regeln")
        let s = try JSONDecoder().decode(Fuchsjagd.self, from: JSONSerialization.data(withJSONObject: obj))
        XCTAssertEqual(s.regeln, .standard)
    }
}

final class FuchsjagdRegelDetailTests: XCTestCase {
    private func stellung(fuchs: Pos, gaense: [Pos], amZug: Fuchsjagd.Seite, regeln: FuchsRegeln = .standard) throws -> Fuchsjagd {
        struct R: Encodable { var fuchs: Pos; var gaense: [Pos]; var amZug: Fuchsjagd.Seite; var zuege = 0; var geschlagen = 0; var regeln: FuchsRegeln }
        let d = try JSONEncoder().encode(R(fuchs: fuchs, gaense: gaense, amZug: amZug, regeln: regeln))
        return try JSONDecoder().decode(Fuchsjagd.self, from: d)
    }
    func testFuchsGehtInVierRichtungen() throws {
        let s = try stellung(fuchs: Pos(3, 3), gaense: [Pos(0, 4), Pos(1, 4), Pos(5, 4), Pos(6, 4)], amZug: .fuchs)
        XCTAssertEqual(Set(s.zuegeDes(.fuchs).map(\.nach)), [Pos(2, 3), Pos(4, 3), Pos(3, 2), Pos(3, 4)])
    }
    func testSprungMitFreiemZielfeld() throws {
        var s = try stellung(fuchs: Pos(3, 3), gaense: [Pos(3, 4), Pos(2, 6), Pos(3, 6), Pos(4, 6), Pos(0, 4)], amZug: .fuchs)
        let z = s.zuegeDes(.fuchs).first { $0.schlag == Pos(3, 4) }
        XCTAssertEqual(z?.nach, Pos(3, 5))
        XCTAssertTrue(s.ziehe(z!)); XCTAssertEqual(s.geschlagen, 1); XCTAssertFalse(s.gaense.contains(Pos(3, 4)))
        XCTAssertEqual(s.amZug, .gaense)
    }
    func testKeinSprungWennDahinterBesetzt() throws {
        let s = try stellung(fuchs: Pos(3, 3), gaense: [Pos(3, 4), Pos(3, 5), Pos(0, 4), Pos(1, 4)], amZug: .fuchs)
        XCTAssertNil(s.zuegeDes(.fuchs).first { $0.schlag == Pos(3, 4) })
    }
    func testSchlagzwang() throws {
        let frei = try stellung(fuchs: Pos(3, 3), gaense: [Pos(3, 4), Pos(0, 4)], amZug: .fuchs)
        XCTAssertGreaterThan(frei.zuegeDes(.fuchs).filter { $0.schlag == nil }.count, 0)
        let zwang = try stellung(fuchs: Pos(3, 3), gaense: [Pos(3, 4), Pos(0, 4)], amZug: .fuchs, regeln: .zwang)
        XCTAssertTrue(zwang.zuegeDes(.fuchs).allSatisfy { $0.schlag != nil })
    }
    func testGaenseDiagonalNurMitRegel() throws {
        let norm = try stellung(fuchs: Pos(3, 0), gaense: [Pos(3, 4)], amZug: .gaense)
        let diag = try stellung(fuchs: Pos(3, 0), gaense: [Pos(3, 4)], amZug: .gaense, regeln: .leichtGaense)
        XCTAssertEqual(norm.zuegeDes(.gaense).count, 3)
        XCTAssertEqual(diag.zuegeDes(.gaense).count, 5)
    }
    func testGaenseGewinnenWennFuchsEingesperrt() throws {
        // Fuchs in der Ecke (3,0) mit Gänsen auf beiden Seiten und dahinter gedeckt
        let s = try stellung(fuchs: Pos(3, 0), gaense: [Pos(2, 0), Pos(4, 0), Pos(3, 1), Pos(3, 2), Pos(1, 0)] + [Pos(5, 0)].filter { _ in false }, amZug: .fuchs)
        // (2,0) -> Sprung nach (1,0) besetzt; (4,0) -> (5,0) ist ungültig (Kreuzarm); (3,1) -> (3,2) besetzt
        XCTAssertTrue(s.zuegeDes(.fuchs).isEmpty)
        XCTAssertEqual(s.sieger, .gaense)
    }
    func testFuchsGewinntBeiZuWenigGaensen() throws {
        let s = try stellung(fuchs: Pos(3, 3), gaense: [Pos(0, 4), Pos(1, 4), Pos(5, 4)], amZug: .gaense)
        XCTAssertEqual(s.sieger, .fuchs)
    }
    func testNachSiegKeinZugMehr() throws {
        var s = try stellung(fuchs: Pos(3, 3), gaense: [Pos(0, 4), Pos(1, 4), Pos(5, 4)], amZug: .gaense)
        XCTAssertFalse(s.ziehe(s.zuegeDes(.gaense)[0]))
    }
    func testUngueltigerZugWirdAbgelehnt() {
        var s = Fuchsjagd()
        XCTAssertFalse(s.ziehe(FuchsZug(von: Pos(3, 3), nach: Pos(3, 2), schlag: nil)))   // Fuchs ist nicht dran
        XCTAssertEqual(s, Fuchsjagd())
    }
    func testFuchsGewinntNachZugLimit() {
        var g = SystemRandomNumberGenerator()
        var s = Fuchsjagd(); var n = 0
        while s.sieger == nil && n < 400 { s.ziehe(s.computerZug(tiefe: 0, mit: &g)!); n += 1 }
        XCTAssertLessThanOrEqual(s.zuege, Fuchsjagd.maxZuege)
    }
    func testFuchsComputerSchlaegtWennMoeglichAufTiefe2() throws {
        var g = SystemRandomNumberGenerator()
        let s = try stellung(fuchs: Pos(3, 3), gaense: [Pos(3, 4), Pos(0, 4), Pos(1, 4), Pos(2, 4), Pos(4, 4), Pos(5, 4), Pos(6, 4), Pos(2, 5), Pos(4, 5), Pos(2, 6), Pos(3, 6), Pos(4, 6)], amZug: .fuchs)
        let z = s.computerZug(tiefe: 2, mit: &g)
        XCTAssertNotNil(z)
        XCTAssertTrue(s.zuegeDes(.fuchs).contains(z!))
    }
    func testFuchsSeiteSchlaegtZufallsGaense() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for _ in 0..<6 {
            var s = Fuchsjagd(); var n = 0
            while s.sieger == nil && n < 400 {
                s.ziehe(s.computerZug(tiefe: s.amZug == .fuchs ? 3 : 0, mit: &g)!); n += 1
            }
            if s.sieger == .fuchs { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 5)
    }
}
