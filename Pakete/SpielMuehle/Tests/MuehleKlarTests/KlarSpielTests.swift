// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import MuehleKern
@testable import SpielMuehle

/// Zeichnet eine Ansicht in „Klar & Glas“ (hell und dunkel) als PNG nach `$KLAR_ZIEL` (Umgebungsvariable `TEST_RUNNER_KLAR_ZIEL`).
/// Ohne Ziel schreibt der Test nichts. Läuft unverändert im alten und im neuen Stand (Werkzeug/designwechsel_klar_vergleich_davor.sh).
@MainActor
private func klarBilder<V: View>(_ name: String, groesse: CGSize, _ ansicht: () -> V) throws {
    guard let ziel = ProcessInfo.processInfo.environment["KLAR_ZIEL"], !ziel.isEmpty else { return }
    try FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)
    for dunkel in [false, true] {
        let v = ansicht().padding(16).frame(width: groesse.width, height: groesse.height, alignment: .topLeading)
            .background(Color(.systemGroupedBackground)).environment(\.colorScheme, dunkel ? .dark : .light)
        let r = ImageRenderer(content: v); r.scale = 2
        let daten = try XCTUnwrap(r.uiImage?.pngData(), "kein Bild: \(name)")
        try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(name)-\(dunkel ? "dunkel" : "hell").png"))
        print("BILD \(name)-\(dunkel ? "dunkel" : "hell")")
    }
}

/// Fester Zufall, damit alter und neuer Stand dasselbe Rätsel zeichnen.
private struct FesterZufall: RandomNumberGenerator {
    var zustand: UInt64
    mutating func next() -> UInt64 {
        zustand &+= 0x9E3779B97F4A7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Klar-Vergleich Designwechsel: Mühle-Spielbild mit gesetzten Steinen und gewähltem Zug.
@MainActor
final class KlarSpielTests: XCTestCase {
    static func szene() -> Muehle {
        var m = Muehle()
        for p in [0, 3, 1, 11, 9, 14, 21, 22] { _ = m.spiele(.setze(p)) }
        return m
    }
    func testSpielbild() throws {
        let m = Self.szene()
        try klarBilder("muehle-spiel", groesse: CGSize(width: 390, height: 844)) {
            MuehleSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}, vorgabe: m)
        }
    }
}
#endif
