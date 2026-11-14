// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import Foundation

/// Prüft, ob die gefundenen Augen zu einem echten Würfelbild passen (1…6), auch gedreht, und ergänzt ein übersehenes Auge.
/// Statt nur zu zählen: 5 Augen, die kein „Fünf“ ergeben, aber eine „Sechs“ ohne ein Auge sind, zählen als 6.
/// Reine Geometrie, ohne Kamera testbar.
enum Augenmuster {
    struct Treffer {
        var augen: Int
        var mitte: CGPoint        // Mittelpunkt des Würfels (Pixel)
        var seite: Double         // Kantenlänge des Würfels (Pixel)
        var winkel: Double        // Drehung in Bogenmaß
    }

    /// Augenlagen auf einem Würfel der Kantenlänge 1, Mitte bei (0, 0).
    static let lagen: [Int: [(Double, Double)]] = {
        let a = 0.25
        return [
            1: [(0, 0)],
            2: [(-a, -a), (a, a)],
            3: [(-a, -a), (0, 0), (a, a)],
            4: [(-a, -a), (a, -a), (-a, a), (a, a)],
            5: [(-a, -a), (a, -a), (0, 0), (-a, a), (a, a)],
            6: [(-a, -a), (a, -a), (-a, 0), (a, 0), (-a, a), (a, a)],
        ]
    }()

    /// Verhältnis Würfelkante zu Augendurchmesser (übliche Würfel: Auge ≈ 0,2 der Kante).
    static let kantenFaktoren: [Double] = [4.4, 5.0, 5.8]

    /// Beste Deutung: erst ein exakter Treffer mit genau so vielen Augen, sonst die Deutung mit einem übersehenen Auge.
    /// `nil`, wenn keine Deutung passt (der Aufrufer fällt dann auf die reine Zählung zurück).
    static func deute(_ punkte: [(x: Double, y: Double)], augenDurchmesser dm: Double) -> Treffer? {
        let n = punkte.count
        guard (1...6).contains(n), dm > 0 else { return nil }
        if let t = beste(punkte, ziel: n, dm: dm) { return t }
        if n < 6, let t = beste(punkte, ziel: n + 1, dm: dm) { return t }
        return nil
    }

    private static func beste(_ p: [(x: Double, y: Double)], ziel: Int, dm: Double) -> Treffer? {
        guard let lage = lagen[ziel] else { return nil }
        let toleranz = 0.55 * dm
        var bester: (Treffer, Double)?
        for faktor in kantenFaktoren {
            let seite = faktor * dm
            var winkel = 0.0
            while winkel < Double.pi {
                let c = cos(winkel), s = sin(winkel)
                let ziele = lage.map { (x: ($0.0 * c - $0.1 * s) * seite, y: ($0.0 * s + $0.1 * c) * seite) }
                // Jedes gefundene Auge muss auf eine Zielposition fallen; die Verschiebung kommt vom ersten Auge.
                for z in ziele {
                    let dx = p[0].x - z.x, dy = p[0].y - z.y
                    var fehler = 0.0, benutzt = Set<Int>(), ok = true
                    for q in p {
                        var nah: (Int, Double)?
                        for (i, t) in ziele.enumerated() where !benutzt.contains(i) {
                            let d = hypot(q.x - (t.x + dx), q.y - (t.y + dy))
                            if d <= toleranz, nah == nil || d < nah!.1 { nah = (i, d) }
                        }
                        guard let (i, d) = nah else { ok = false; break }
                        benutzt.insert(i); fehler += d
                    }
                    guard ok else { continue }
                    if bester == nil || fehler < bester!.1 {
                        // Würfelmitte = Mitte der Zielpositionen verschoben (Zielmitte ist (0, 0)).
                        bester = (Treffer(augen: ziel, mitte: CGPoint(x: dx, y: dy), seite: seite, winkel: winkel), fehler)
                    }
                }
                winkel += Double.pi / 45   // 4°-Schritte, der Würfel ist nach 90° wieder derselbe
            }
        }
        return bester?.0
    }
}
