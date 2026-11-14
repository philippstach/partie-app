// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// K-031/G-015: Der Spielstand wird bei jeder Auswertung von `Fortsetzbar` kodiert und verglichen. Ohne feste Schlüsselreihenfolge
/// lieferte `JSONEncoder` für denselben Stand wechselnde Bytes; das hielt eine Speicher-Render-Schleife am Laufen (Start-Hänger).
final class StandKodierenTests: XCTestCase {
    private struct Karte: Codable, Equatable { let farbe: Int; let wert: Int; let nummer: Int }
    private struct Stand: Codable, Equatable {
        var haende: [[Karte]]; var stapel: [Karte]; var ablage: [Karte]; var tisch: [[Karte]]
        var hatAusgelegt: [Bool]; var dran = 0; var gezogen = false; var gewinner: Int?
    }

    private func beispiel() -> Stand {
        let deck = (0..<108).map { Karte(farbe: $0 % 4, wert: $0 % 13, nummer: $0 / 54) }
        return Stand(haende: [Array(deck[0..<13]), Array(deck[13..<26]), Array(deck[26..<39])], stapel: Array(deck[39...]),
                     ablage: [], tisch: [], hatAusgelegt: [false, false, false])
    }

    func testKodierenLiefertImmerDieselbenBytes() {
        let s = beispiel()
        var ausgaben = Set<Data>()
        for _ in 0..<1000 { if let d = SpielStand.kodieren(s) { ausgaben.insert(d) } }
        XCTAssertEqual(ausgaben.count, 1, "derselbe Stand muss immer gleich kodiert werden, sonst schreibt Fortsetzbar endlos")
    }

    func testSichernSchreibtGleichenStandNichtErneut() {
        let name = "standkodieren.tests"
        let d = UserDefaults(suiteName: name)!; d.removePersistentDomain(forName: name)
        let s = beispiel()
        SpielStand.sichern(s, spiel: "t", defaults: d)
        let erst = d.data(forKey: "partie.stand.t")
        for _ in 0..<200 { SpielStand.sichern(s, spiel: "t", defaults: d) }
        XCTAssertEqual(d.data(forKey: "partie.stand.t"), erst)
        XCTAssertEqual(SpielStand.laden(Stand.self, spiel: "t", defaults: d), s, "sortierte Kodierung bleibt lesbar")
    }
}
