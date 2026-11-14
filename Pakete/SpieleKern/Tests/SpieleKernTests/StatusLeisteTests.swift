// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// NICHT SYNTAXGEPRÜFT (Cloud-Chat, AUS-008 zweiter Anlauf).
#if canImport(UIKit)
import XCTest
@testable import SpieleKern

final class StatusLeisteTests: XCTestCase {
    func testFilzkopfObenDecktDieLeiste() {
        XCTAssertTrue(StatusLeisteRegel.bedecktOben(CGRect(x: 0, y: 0, width: 1024, height: 300)))
        XCTAssertTrue(StatusLeisteRegel.bedecktOben(CGRect(x: 0, y: -200, width: 1024, height: 300)), "halb geschoben, deckt noch")
    }

    func testGeschobenerOderTieferKopfDecktNicht() {
        XCTAssertFalse(StatusLeisteRegel.bedecktOben(CGRect(x: 0, y: -280, width: 1024, height: 300)), "fast ganz aus dem Bild")
        XCTAssertFalse(StatusLeisteRegel.bedecktOben(CGRect(x: 0, y: 80, width: 390, height: 236)), "Karte unter der Leiste")
    }
}
#endif
