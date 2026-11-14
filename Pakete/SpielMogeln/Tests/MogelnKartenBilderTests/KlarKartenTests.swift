// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import MogelnKern
@testable import SpielMogeln

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

/// Klar-Vergleich Designwechsel: Mogeln-Handkarten. Im alten Stand steht die Zeichnung noch in `MogelnSpiel` und wird hier
/// wörtlich nachgebaut (`#else`); im neuen Stand ist es die Ansicht `MHandKarte` (`NEU`, siehe Package.swift).
@MainActor
final class KlarKartenTests: XCTestCase {
    func testHand() throws {
        try klarBilder("mogeln", groesse: CGSize(width: 390, height: 120)) {
            HStack(spacing: 6) {
                ForEach(Array([MoKarte(2, 13), MoKarte(1, 7), MoKarte(3, 10), MoKarte(0, 14), MoKarte(2, 8)].enumerated()), id: \.offset) { i, k in
                    #if NEU
                    MHandKarte(karte: k, gewaehlt: i == 2)
                    #else
                    VStack(spacing: 0) { Text(k.kurz).font(.system(.title3, design: Design.zahlDesign).weight(.bold)); Text(k.symbol).font(.title2) }
                        .foregroundStyle(k.farbe >= 2 ? Color.red : Color.primary)
                        .frame(width: 52, height: 76)
                        .background(Color(.systemBackground), in: .rect(cornerRadius: Design.Ecke.klein))
                        .overlay(RoundedRectangle(cornerRadius: Design.Ecke.klein).strokeBorder(i == 2 ? Color.appFlaeche : Color.secondary.opacity(0.4), lineWidth: i == 2 ? 3 : 1))
                    #endif
                }
            }
        }
    }
}
#endif
