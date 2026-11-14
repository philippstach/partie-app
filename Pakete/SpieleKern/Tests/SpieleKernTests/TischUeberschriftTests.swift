// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// NICHT SYNTAXGEPRÜFT (Cloud-Chat, Blatt 23 FS-K).
#if canImport(UIKit)
import XCTest
import SwiftUI
@testable import SpieleKern

@MainActor
final class TischUeberschriftTests: XCTestCase {
    func testBeideInitialisiererBauen() {
        let a = TischUeberschrift("Diese Runde")
        let b = TischUeberschrift(verbatim: "Anna")
        XCTAssertEqual(a.text, Text("Diese Runde"))
        XCTAssertEqual(b.text, Text(verbatim: "Anna"))
    }
}
#endif
