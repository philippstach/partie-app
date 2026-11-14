// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
import DesignBilder
@testable import SpielElferRaus

private struct Saat3: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s ^ (s >> 29) }
}

/// Elfer raus in allen Designs, iPhone SE, normal und Pro Max (F-AWS-G-013, K-029, K-018). Nur mit `TEST_RUNNER_DESIGN_BILDER`.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        let ansicht = { (v: ErVariante) -> ElferNeuSpiel in
            var g = Saat3(s: 7)
            let spiel = ErSpiel(spieler: 2, regeln: .fuer(v), mit: &g)
            // Der Mensch ist am Zug, damit die Hand sichtbar ist (sonst Sichtschutz bzw. Computerzug)
            let t = [SpielTeilnehmer(name: "Anna", computer: spiel.dran != 0), SpielTeilnehmer(name: "Ben", computer: spiel.dran != 1)]
            return ElferNeuSpiel(teilnehmer: t, ende: { _ in }, abbrechen: {}, vorgabe: spiel)
        }
        _ = ImageRenderer(content: ansicht(.echt).frame(width: 390, height: 844)).uiImage
        for (gname, g) in [("se", CGSize(width: 375, height: 667)), ("normal", CGSize(width: 390, height: 844)), ("gross", CGSize(width: 430, height: 932)), ("ipad", CGSize(width: 820, height: 1180))] {
            for v in [ErVariante.echt, .kartendomino] {
                for d in DesignArt.allCases { for dunkel in [false, true] {
                    let b = Aufnahme.fensterBild(ansicht(v), design: d, dunkel: dunkel, groesse: g)
                    XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "elfer-\(v)-\(gname)")))
                } }
            }
        }
        Design.art = .klar
    }
}
#endif
