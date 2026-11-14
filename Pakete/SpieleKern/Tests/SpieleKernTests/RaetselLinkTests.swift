// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

final class RaetselLinkTests: XCTestCase {
    private func defaults(kinder: Bool) -> UserDefaults {
        let d = UserDefaults(suiteName: "RaetselLinkTests-\(UUID().uuidString)")!
        d.set(kinder, forKey: TeilenFreigabe.kinderKey)
        return d
    }

    func testLinkHinUndZurueck() throws {
        let l = RaetselLink(spiel: "sudoku-neu", werte: ["form": "klassisch", "stufe": "mittel", "seed": "12345"])
        let url = try XCTUnwrap(l.url)
        XCTAssertEqual(url.absoluteString, "partie://raetsel/sudoku-neu?form=klassisch&seed=12345&stufe=mittel")
        XCTAssertEqual(RaetselLink(url: url), l)
        XCTAssertEqual(l.zahl("seed"), 12345)
    }

    func testFremdeAdressenWerdenAbgelehnt() {
        XCTAssertNil(RaetselLink(url: URL(string: "https://raetsel/sudoku?seed=1")!))
        XCTAssertNil(RaetselLink(url: URL(string: "partie://spiel/sudoku")!))
        XCTAssertNil(RaetselLink(url: URL(string: "partie://raetsel/")!))
        XCTAssertNil(RaetselLink(url: URL(string: "partie://raetsel/a/b?seed=1")!))
        XCTAssertNil(RaetselLink(url: URL(string: "partie://raetsel/a?seed=1&seed=2")!))
    }

    func testTeilenTextEnthaeltSatzUndLink() {
        let l = RaetselLink(spiel: "minensuche", werte: ["seed": "7", "stufe": "leicht"])
        let t = l.teilenText(satz: "Schaffst du das?")
        XCTAssertTrue(t.hasPrefix("Schaffst du das?\npartie://raetsel/minensuche?"))
    }

    @MainActor func testKindermodusSperrtTeilenUndLink() {
        XCTAssertFalse(TeilenFreigabe.erlaubt(defaults(kinder: true)))
        XCTAssertTrue(TeilenFreigabe.erlaubt(defaults(kinder: false)))
        XCTAssertNil(TeilenFreigabe.aktion({}, defaults: defaults(kinder: true)))
        XCTAssertNotNil(TeilenFreigabe.aktion({}, defaults: defaults(kinder: false)))
        let l = RaetselLink(spiel: "x", werte: [:])
        XCTAssertFalse(RaetselPost.ablegen(l, defaults: defaults(kinder: true)))
        XCTAssertNil(RaetselPost.abholen(spiel: "x"))
    }

    @MainActor func testPostGehtNurAnDasRichtigeSpielUndVerfaellt() {
        let l = RaetselLink(spiel: "x", werte: ["seed": "1"])
        XCTAssertTrue(RaetselPost.ablegen(l, defaults: defaults(kinder: false)))
        XCTAssertNil(RaetselPost.abholen(spiel: "y"))
        XCTAssertEqual(RaetselPost.abholen(spiel: "x"), l)
        XCTAssertNil(RaetselPost.abholen(spiel: "x"))      // nur einmal
        RaetselPost.ablegen(l, defaults: defaults(kinder: false))
        XCTAssertNil(RaetselPost.abholen(spiel: "x", jetzt: Date().addingTimeInterval(RaetselPost.gueltig + 1)))
    }
}
