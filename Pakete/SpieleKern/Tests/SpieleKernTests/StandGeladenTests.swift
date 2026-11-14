// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// F5: Der Ladeschritt von `fortsetzbar` meldet, ob ein Stand übernommen wurde; erst danach stößt ein Spiel den Computer an.
final class StandGeladenTests: XCTestCase {
    private struct Stand: Codable, Equatable { var zug: Int; var computerAmZug: Bool }

    func testStandUebernehmenMeldetObGeladenWurde() {
        let d = UserDefaults(suiteName: "standgeladen.tests")!; d.removePersistentDomain(forName: "standgeladen.tests")
        var zustand = Stand(zug: 0, computerAmZug: false)
        XCTAssertFalse(SpielStand.uebernehmen(Stand.self, spiel: "t", defaults: d) { zustand = $0 }, "kein Stand: frische Partie")
        SpielStand.sichern(Stand(zug: 7, computerAmZug: true), spiel: "t", defaults: d)
        XCTAssertTrue(SpielStand.uebernehmen(Stand.self, spiel: "t", defaults: d) { zustand = $0 })
        XCTAssertEqual(zustand, Stand(zug: 7, computerAmZug: true), "der Stand steht, bevor die Rückmeldung kommt")
    }

    func testUnstimmigerStandWirdVerworfenUndMeldetFalse() {
        let d = UserDefaults(suiteName: "standgeladen.tests")!; d.removePersistentDomain(forName: "standgeladen.tests")
        SpielStand.sichern(Stand(zug: -1, computerAmZug: true), spiel: "t", defaults: d)
        var geschrieben = false
        XCTAssertFalse(SpielStand.uebernehmen(Stand.self, spiel: "t", defaults: d, pruefen: { $0.zug >= 0 }) { _ in geschrieben = true })
        XCTAssertFalse(geschrieben); XCTAssertFalse(SpielStand.vorhanden("t", defaults: d))
    }
}
