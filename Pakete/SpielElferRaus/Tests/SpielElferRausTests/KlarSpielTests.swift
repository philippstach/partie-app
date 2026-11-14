// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import SpielElferRaus

/// Zeichnet eine Ansicht in „Klar & Glas“ (hell und dunkel) als PNG nach `$KLAR_ZIEL` (Umgebungsvariable `TEST_RUNNER_KLAR_ZIEL`).
/// Läuft unverändert im alten und im neuen Stand (Werkzeug/designwechsel_klar_vergleich_davor.sh).
@MainActor
private func klarBilder<V: View>(_ name: String, groesse: CGSize, _ ansicht: () -> V) throws {
    guard let ziel = ProcessInfo.processInfo.environment["KLAR_ZIEL"], !ziel.isEmpty else { return }
    try FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)
    for dunkel in [false, true] {
        let v = ansicht().frame(width: groesse.width, height: groesse.height, alignment: .topLeading)
            .background(Color(.systemGroupedBackground)).environment(\.colorScheme, dunkel ? .dark : .light)
        let r = ImageRenderer(content: v); r.scale = 2
        let daten = try XCTUnwrap(r.uiImage?.pngData(), "kein Bild: \(name)")
        try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(name)-\(dunkel ? "dunkel" : "hell").png"))
        print("BILD \(name)-\(dunkel ? "dunkel" : "hell")")
    }
}

private struct Saat2: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s ^ (s >> 29) }
}

/// Klar-Vergleich Designwechsel: Elfer raus, feste Austeilung, echte Fassung und Kartendomino.
@MainActor
final class KlarSpielTests: XCTestCase {
    func testSpielbild() throws {
        for v in [ErVariante.echt, .kartendomino] {
            var g = Saat2(s: 7)
            let spiel = ErSpiel(spieler: 2, regeln: .fuer(v), mit: &g)
            try klarBilder("elfer-\(v)", groesse: CGSize(width: 390, height: 844)) {
                ElferNeuSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}, vorgabe: spiel)
            }
        }
    }
}
#endif
