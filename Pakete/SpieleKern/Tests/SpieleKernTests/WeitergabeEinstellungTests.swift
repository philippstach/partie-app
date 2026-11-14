// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

final class WeitergabeEinstellungTests: XCTestCase {
    private func frischeDefaults() -> UserDefaults {
        let name = "WeitergabeEinstellungTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testStandardIstAutomatisch() {
        XCTAssertTrue(WeitergabeEinstellung.automatisch(defaults: frischeDefaults()))
    }

    func testAusgeschaltetWirdGelesen() {
        let d = frischeDefaults()
        d.set(false, forKey: WeitergabeEinstellung.schluessel)
        XCTAssertFalse(WeitergabeEinstellung.automatisch(defaults: d))
        d.set(true, forKey: WeitergabeEinstellung.schluessel)
        XCTAssertTrue(WeitergabeEinstellung.automatisch(defaults: d))
    }
}
