// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import MauMauKern

/// Die Oberfläche braucht UIKit; hier prüft `swift test` auf dem Mac, dass die Regel-Speicherung der Oberfläche (Codable) stabil bleibt.
final class ModulTests: XCTestCase {
    func testRegelnUeberlebenSpeichern() throws {
        var r = NRegeln.wild; r.mehrrunden = true; r.zielPunkte = 150; r.aussetzen = .ass
        let d = try JSONEncoder().encode(r)
        XCTAssertEqual(try JSONDecoder().decode(NRegeln.self, from: d), r)
    }
    func testRundenstandUndSpielLassenSichSpeichern() throws {
        var g = SystemRandomNumberGenerator()
        let spiel = NMauMau(spieler: 3, mit: &g)
        let runden = NRunden(spieler: 3, ziel: 100)
        XCTAssertEqual(try JSONDecoder().decode(NMauMau.self, from: JSONEncoder().encode(spiel)), spiel)
        XCTAssertEqual(try JSONDecoder().decode(NRunden.self, from: JSONEncoder().encode(runden)), runden)
    }
}
