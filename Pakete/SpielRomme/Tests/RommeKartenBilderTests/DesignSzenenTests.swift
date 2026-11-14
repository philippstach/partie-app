// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
import DesignBilder
import RommeKern
@testable import SpielRomme

private struct Saat3: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s ^ (s >> 29) }
}

/// Rommé nach dem Ziehen in allen Designs (F-AWS-K-037, G-005, M-003, P-016, M-025, K-021). Nur mit `TEST_RUNNER_DESIGN_BILDER`.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        let szene = { () -> Romme in var g = Saat3(s: 3); var r = Romme(spieler: 2, mit: &g); r.ziehe(vomStapel: true, mit: &g); return r }
        let ansicht = { (s: DynamicTypeSize) in
            RommeSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben", computer: true)], ende: { _ in }, abbrechen: {}, vorgabe: szene())
                .environment(\.dynamicTypeSize, s)
        }
        _ = ImageRenderer(content: ansicht(.large).frame(width: 390, height: 844)).uiImage
        for (gname, g) in [("mini", CGSize(width: 375, height: 812)), ("gross", CGSize(width: 430, height: 932))] {
            for (sname, s) in [("normal", DynamicTypeSize.large), ("a11y", .accessibility3)] {
                for d in DesignArt.allCases { for dunkel in [false, true] {
                    let b = Aufnahme.fensterBild(ansicht(s), design: d, dunkel: dunkel, groesse: g)
                    XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "romme-\(gname)-\(sname)")))
                } }
            }
        }
        Design.art = .klar
    }
}
#endif
