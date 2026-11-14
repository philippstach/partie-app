// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import DesignBilder
import IrrgangKern
@testable import SpielIrrgang

/// Zeichnet eine Ansicht in „Klar & Glas“ (hell und dunkel) als PNG nach `$KLAR_ZIEL` (Umgebungsvariable `TEST_RUNNER_KLAR_ZIEL`).
/// Ohne Ziel schreibt der Test nichts. Läuft unverändert im alten und im neuen Stand (Werkzeug/designwechsel_klar_vergleich_davor.sh).
@MainActor
private func klarBilder<V: View>(_ name: String, groesse: CGSize, _ ansicht: () -> V) throws {
    guard let ziel = ProcessInfo.processInfo.environment["KLAR_ZIEL"], !ziel.isEmpty else { return }
    try FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)
    // Der erste Bildlauf richtet unter Mac Catalyst die App-Umgebung ein; erst danach geht das Fenster.
    _ = ImageRenderer(content: ansicht().frame(width: groesse.width, height: groesse.height)).uiImage
    for dunkel in [false, true] {
        // Fensterweg: zeichnet auch ScrollView (ImageRenderer lässt sie leer)
        let bild = Aufnahme.fensterBild(ansicht(), design: .klar, dunkel: dunkel, groesse: groesse)
        let daten = try XCTUnwrap(bild?.pngData(), "kein Bild: \(name)")
        XCTAssertGreaterThan(Aufnahme.inhaltAnteil(bild), 0.01, "leeres Bild: \(name)")
        try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(name)-\(dunkel ? "dunkel" : "hell").png"))
        print("BILD \(name)-\(dunkel ? "dunkel" : "hell")")
    }
}

/// Fester Zufall, damit alter und neuer Stand dasselbe Rätsel zeichnen.
struct FesterZufall: RandomNumberGenerator {
    var zustand: UInt64
    mutating func next() -> UInt64 {
        zustand &+= 0x9E3779B97F4A7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Klar-Vergleich Designwechsel: Labyrinth-Spielbild, hell (Stufe 2, einige Schritte) und mit Laterne (Stufe 4).
@MainActor
final class KlarSpielTests: XCTestCase {
    static func szene() -> Irrgang {
        var z = FesterZufall(zustand: 11)
        var m = Irrgang(stufe: 2, mit: &z)
        for r in [Richtung.ost, .sued, .ost, .sued, .west, .nord] { _ = m.gleite(r) }
        return m
    }
    static func laterne() -> Irrgang {
        var z = FesterZufall(zustand: 13)
        var m = Irrgang(stufe: 4, mit: &z)
        for r in [Richtung.sued, .ost, .sued, .ost, .nord, .west] { _ = m.gleite(r) }
        return m
    }
    func testSpielbild() throws {
        let m = Self.szene()
        try klarBilder("irrgang-spiel", groesse: CGSize(width: 390, height: 844)) {
            IrrgangSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: m)
        }
    }
    func testLaterne() throws {
        let m = Self.laterne()
        try klarBilder("irrgang-laterne", groesse: CGSize(width: 390, height: 844)) {
            IrrgangSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: m)
        }
    }
}
#endif
