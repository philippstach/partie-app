// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WuerfelLive

final class AugenmusterTests: XCTestCase {
    private func punkte(_ n: Int, winkel: Double = 0, seite: Double = 100, mitte: (Double, Double) = (300, 200), ohne: Int? = nil) -> [(x: Double, y: Double)] {
        var l = Augenmuster.lagen[n]!
        if let o = ohne { l.remove(at: o) }
        let c = cos(winkel), s = sin(winkel)
        return l.map { (x: mitte.0 + ($0.0 * c - $0.1 * s) * seite, y: mitte.1 + ($0.0 * s + $0.1 * c) * seite) }
    }
    private let dm = 20.0

    func testAlleMusterGedreht() {
        for n in 1...6 { for grad in stride(from: 0.0, to: 180.0, by: 17.0) {
            let t = Augenmuster.deute(punkte(n, winkel: grad * .pi / 180), augenDurchmesser: dm)
            XCTAssertEqual(t?.augen, n, "\(n) bei \(grad)°")
        } }
    }

    func testSechsMitFehlendemAugeIstSechs() {
        for fehlt in 0..<6 {
            XCTAssertEqual(Augenmuster.deute(punkte(6, ohne: fehlt), augenDurchmesser: dm)?.augen, 6, "Sechs ohne Auge \(fehlt)")
            XCTAssertEqual(Augenmuster.deute(punkte(6, winkel: 0.6, ohne: fehlt), augenDurchmesser: dm)?.augen, 6, "gedreht, ohne Auge \(fehlt)")
        }
    }

    func testFuenfMitFehlendemEckaugeIstFuenf() {
        for fehlt in [0, 1, 3, 4] { XCTAssertEqual(Augenmuster.deute(punkte(5, ohne: fehlt), augenDurchmesser: dm)?.augen, 5, "Fünf ohne Auge \(fehlt)") }
    }

    func testVierMitFehlendemAugeIstVierNichtDrei() {
        // Drei Ecken (L-Form) sind keine „Drei“ (die liegt auf der Diagonale), sondern eine Vier mit übersehenem Auge.
        for fehlt in 0..<4 { XCTAssertEqual(Augenmuster.deute(punkte(4, ohne: fehlt), augenDurchmesser: dm)?.augen, 4, "Vier ohne Auge \(fehlt)") }
    }

    func testEchteDreiBleibtDrei() {
        XCTAssertEqual(Augenmuster.deute(punkte(3), augenDurchmesser: dm)?.augen, 3)
        XCTAssertEqual(Augenmuster.deute(punkte(2), augenDurchmesser: dm)?.augen, 2)
    }

    func testWuerfelMitteUndSeite() throws {
        let t = try XCTUnwrap(Augenmuster.deute(punkte(5, seite: 110, mitte: (400, 250)), augenDurchmesser: 22))
        XCTAssertEqual(Double(t.mitte.x), 400, accuracy: 4)
        XCTAssertEqual(Double(t.mitte.y), 250, accuracy: 4)
        XCTAssertEqual(t.seite, 110, accuracy: 12)
    }

    func testUnsinnigeAnordnungFaelltDurch() {
        XCTAssertNil(Augenmuster.deute([(x: 0, y: 0), (x: 30, y: 0), (x: 200, y: 5)], augenDurchmesser: dm))
    }
}
