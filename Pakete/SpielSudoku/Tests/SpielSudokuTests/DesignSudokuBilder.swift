// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SudokuKern
@testable import SpielSudoku

/// Designwechsel D.4: Sudoku-Feld (`NeuFeld`) und Ziffernblock in allen drei Designs, hell und dunkel (nur mit `DESIGN_BILDER`, sonst kein Bild).
@MainActor
final class DesignSudokuBilder: XCTestCase {
    private func szene(_ form: SudokuForm) -> some View {
        let n = form.n
        let muster: [UInt8] = [5, 3, 0, 0, 7, 0, 0, 0, 0, 6, 0, 0, 1, 9, 5, 0, 0, 0, 0, 9, 8, 0, 0, 0, 0, 6, 0, 8, 0, 0, 0, 6, 0, 0, 0, 3,
                               4, 0, 0, 8, 0, 3, 0, 0, 1, 7, 0, 0, 0, 2, 0, 0, 0, 6, 0, 6, 0, 0, 0, 0, 2, 8, 0, 0, 0, 0, 4, 1, 9, 0, 0, 5, 0, 0, 0, 0, 8, 0, 0, 7, 9]
        let werte: [UInt8] = form == .klassisch || form == .x ? muster : Array(repeating: 0, count: n * n)
        var notizen = [UInt16](repeating: 0, count: n * n)
        notizen[2] = SudokuForm.bit(1) | SudokuForm.bit(2) | SudokuForm.bit(4)
        notizen[3] = SudokuForm.bit(2) | SudokuForm.bit(6)
        return VStack(spacing: 14) {
            NeuFeld(form: form, werte: werte, notizen: notizen, fest: { werte[$0] != 0 && $0 % 4 != 1 }, seite: 358, gewaehlt: 11, rot: [13], tippen: { _ in })
            NeuZiffern(n: 9, fehlt: { $0 == 5 ? 0 : 3 }, hervorgehoben: 3, tippen: { _ in }).padding(.horizontal, 16)
        }
    }

    func testFeld() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = szene(.klassisch).padding(16).frame(width: 390, height: 520, alignment: .top)
                    .background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-sudoku-feld.png"))
            }
        }
        Design.art = .klar
    }
}
#endif
