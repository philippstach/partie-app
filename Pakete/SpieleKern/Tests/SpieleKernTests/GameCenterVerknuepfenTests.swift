// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

@MainActor
final class GameCenterVerknuepfenTests: XCTestCase {
    private func verzeichnis() -> SpielerVerzeichnis { SpielerVerzeichnis(ablage: SpeicherAblage()) }

    func testVerknuepfenUndFinden() {
        let v = verzeichnis()
        _ = v.speichern(name: "Ich", avatar: "", farbeIndex: 0, ich: true)
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 1)!
        XCTAssertEqual(v.ohneGameCenter.map(\.name), ["Anna"], "Ich zählt nicht")
        XCTAssertTrue(v.verknuepfen(anna.id, gameCenterID: "G:1"))
        XCTAssertEqual(v.mitGameCenter("G:1")?.id, anna.id)
        XCTAssertTrue(v.ohneGameCenter.isEmpty)
    }

    func testEinFreundGehoertNurEinerPerson() {
        let v = verzeichnis()
        _ = v.speichern(name: "Ich", avatar: "", farbeIndex: 0, ich: true)
        let a = v.speichern(name: "Anna", avatar: "", farbeIndex: 1)!, b = v.speichern(name: "Ben", avatar: "", farbeIndex: 2)!
        v.verknuepfen(a.id, gameCenterID: "G:1"); v.verknuepfen(b.id, gameCenterID: "G:1")
        XCTAssertEqual(v.mitGameCenter("G:1")?.id, b.id)
        XCTAssertNil(v.alle.first { $0.id == a.id }?.gameCenterID)
    }

    func testNeuAnlegenMitVergebenemNamenUndLoesen() {
        let v = verzeichnis()
        _ = v.speichern(name: "Ich", avatar: "", farbeIndex: 0, ich: true)
        _ = v.speichern(name: "Anna", avatar: "", farbeIndex: 1)
        let neu = v.freundAnlegen(name: "Anna", gameCenterID: "G:2")
        XCTAssertEqual(neu?.name, "Anna 2")
        XCTAssertEqual(v.freundAnlegen(name: "Egal", gameCenterID: "G:2")?.id, neu?.id, "zweites Mal: dieselbe Person")
        v.verknuepfungLoesen(neu!.id)
        XCTAssertNil(v.mitGameCenter("G:2"))
        XCTAssertEqual(v.alle.count, 3, "Die Person bleibt")
    }

    func testAlteDatenOhneGameCenterSindLesbar() throws {
        let alt = #"[{"id":"\#(UUID().uuidString)","name":"Anna","avatar":"A","farbeIndex":0,"art":"mensch","ich":false,"angelegt":0,"zuletzt":0}]"#
        let v = SpielerVerzeichnis(ablage: SpeicherAblage(daten: Data(alt.utf8)))
        XCTAssertEqual(v.alle.count, 1)
        XCTAssertNil(v.alle[0].gameCenterID)
    }

    func testComputerLaesstSichNichtVerknuepfen() {
        let v = verzeichnis()
        let c = v.anlegen(name: "Robo", art: .computer)
        XCTAssertFalse(v.verknuepfen(c.id, gameCenterID: "G:3"))
    }
}
