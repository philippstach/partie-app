// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import DesignBilder
import KakuroKern
@testable import SpielKakuro

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

/// Klar-Vergleich Designwechsel: Kakuro-Spielbild mit festem Rätsel, einigen Eintragungen und einem Fehler.
@MainActor
final class KlarSpielTests: XCTestCase {
    static func szene() -> Kakuro {
        var z = FesterZufall(zustand: 7)
        var k = Kakuro.zufaellig(n: 6, mit: &z)
        let frei = k.weiss.indices.filter { k.weiss[$0] && !k.vorgaben.contains($0) }
        for i in frei.prefix(6) { k.setze(i, k.loesung[i]) }
        if frei.count > 7 { k.setze(frei[6], k.loesung[frei[6]] % 9 + 1) }   // ein falscher Eintrag (rot)
        return k
    }
    func testSpielbild() throws {
        let k = Self.szene()
        try klarBilder("kakuro-spiel", groesse: CGSize(width: 390, height: 844)) {
            KakuroSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: k)
        }
    }
}
#endif
