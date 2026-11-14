// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SudokuKern
@testable import SpielSudoku

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

/// Klar-Vergleich Designwechsel: Sudoku-Feld (`NeuFeld`) mit Vorgaben, Eigeneinträgen, Notizen, Fehler, Auswahl und Ziffernblock.
@MainActor
final class KlarFeldTests: XCTestCase {
    func testFeld() throws {
        let form = SudokuForm.klassisch
        let muster: [UInt8] = [5, 3, 0, 0, 7, 0, 0, 0, 0, 6, 0, 0, 1, 9, 5, 0, 0, 0, 0, 9, 8, 0, 0, 0, 0, 6, 0, 8, 0, 0, 0, 6, 0, 0, 0, 3,
                               4, 0, 0, 8, 0, 3, 0, 0, 1, 7, 0, 0, 0, 2, 0, 0, 0, 6, 0, 6, 0, 0, 0, 0, 2, 8, 0, 0, 0, 0, 4, 1, 9, 0, 0, 5, 0, 0, 0, 0, 8, 0, 0, 7, 9]
        var notizen = [UInt16](repeating: 0, count: 81)
        notizen[2] = SudokuForm.bit(1) | SudokuForm.bit(2) | SudokuForm.bit(4)
        notizen[3] = SudokuForm.bit(2) | SudokuForm.bit(6)
        try klarBilder("sudoku-feld", groesse: CGSize(width: 390, height: 520)) {
            VStack(spacing: 14) {
                NeuFeld(form: form, werte: muster, notizen: notizen, fest: { muster[$0] != 0 && $0 % 4 != 1 }, seite: 358, gewaehlt: 11, rot: [13], tippen: { _ in })
                NeuZiffern(n: 9, fehlt: { $0 == 5 ? 0 : 3 }, hervorgehoben: 3, tippen: { _ in }).padding(.horizontal, 16)
            }
        }
    }
}
#endif
