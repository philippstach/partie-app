// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Raster-Geometrie des Bretts (11 × 11, (0,0) oben links), gleich wie `brett()` in `Referenz/maedn.py`
/// und `Shared/regeltests/brett.json` (der Test vergleicht beides).
struct Rasterpunkt: Hashable, Sendable {
    var x: Int
    var y: Int
}

enum Brettgeometrie {
    static let raster = 11

    /// 90° im Uhrzeigersinn um die Mitte (5,5), `mal`-mal.
    private static func drehe(_ p: Rasterpunkt, _ mal: Int) -> Rasterpunkt {
        var (x, y) = (p.x, p.y)
        for _ in 0 ..< mal { (x, y) = (10 - y, x) }
        return Rasterpunkt(x: x, y: y)
    }

    private static let laufSitz0 = [(0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (4, 3), (4, 2), (4, 1), (4, 0), (5, 0)]
        .map { Rasterpunkt(x: $0.0, y: $0.1) }
    private static let hausSitz0 = [(0, 0), (1, 0), (0, 1), (1, 1)].map { Rasterpunkt(x: $0.0, y: $0.1) }
    private static let zielSitz0 = [(1, 5), (2, 5), (3, 5), (4, 5)].map { Rasterpunkt(x: $0.0, y: $0.1) }

    /// Absolutes Laufbahnfeld 0…39.
    static let laufbahn: [Rasterpunkt] = (0 ..< Brettmass.lauf).map {
        drehe(laufSitz0[$0 % Brettmass.abstand], $0 / Brettmass.abstand)
    }
    /// Die 4 Hausfelder je Sitz (Index = Figur-Index).
    static let haus: [[Rasterpunkt]] = (0 ..< Brettmass.sitze).map { s in hausSitz0.map { drehe($0, s) } }
    /// Die 4 Zielfelder je Sitz (Index 0 = rel 40).
    static let ziel: [[Rasterpunkt]] = (0 ..< Brettmass.sitze).map { s in zielSitz0.map { drehe($0, s) } }
    /// Absolutes Startfeld je Sitz.
    static let start: [Int] = (0 ..< Brettmass.sitze).map { $0 * Brettmass.abstand }

    /// Rasterpunkt einer Figur auf rel-Position `rel` (Haus: `figur` wählt das Hausfeld).
    static func punkt(sitz: Int, rel: Int, figur: Int) -> Rasterpunkt {
        if rel == Brettmass.haus { return haus[sitz][figur] }
        if rel >= Brettmass.zielErstes { return ziel[sitz][rel - Brettmass.zielErstes] }
        return laufbahn[feld(sitz, rel)]
    }
}
