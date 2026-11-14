// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Achsenparalleles Rechteck. Koordinaten nach SwiftUI-Art: y wächst nach unten.
public struct Kasten: Equatable, Sendable {
    public var x: Double, y: Double, b: Double, h: Double
    public init(x: Double, y: Double, b: Double, h: Double) { self.x = x; self.y = y; self.b = b; self.h = h }
    public var rechts: Double { x + b }
    public var unten: Double { y + h }
    public var mitteX: Double { x + b / 2 }
    public var mitteY: Double { y + h / 2 }
    public func schneidet(_ o: Kasten) -> Bool { x < o.rechts && o.x < rechts && y < o.unten && o.y < unten }
    /// Etwas kleiner/größer machen (Nachsicht bei Zusammenstößen: Treffer-Kästen sind kleiner als die Grafik).
    public func geweitet(_ d: Double) -> Kasten { Kasten(x: x - d, y: y - d, b: b + 2 * d, h: h + 2 * d) }
}

/// Seite, von der ein Ball ein Rechteck berührt hat.
public enum Seite: Sendable { case links, rechts, oben, unten }

public enum Treffer {
    /// Kreis (Mitte, Radius) gegen Kasten. Liefert die Seite mit der geringsten Eindringtiefe und diese Tiefe, sonst `nil`.
    public static func kreis(x: Double, y: Double, r: Double, kasten k: Kasten) -> (seite: Seite, tiefe: Double)? {
        let nx = min(max(x, k.x), k.rechts), ny = min(max(y, k.y), k.unten)
        let dx = x - nx, dy = y - ny
        guard dx * dx + dy * dy < r * r else { return nil }
        if dx == 0 && dy == 0 {   // Mitte liegt im Kasten: kürzesten Weg nach draußen nehmen
            let t: [(Seite, Double)] = [(.links, x - k.x), (.rechts, k.rechts - x), (.oben, y - k.y), (.unten, k.unten - y)]
            let m = t.min { $0.1 < $1.1 }!
            return (m.0, m.1 + r)
        }
        if abs(dx) > abs(dy) { return (dx < 0 ? .links : .rechts, r - abs(dx)) }
        return (dy < 0 ? .oben : .unten, r - abs(dy))
    }
}

public func begrenze(_ v: Double, _ lo: Double, _ hi: Double) -> Double { min(max(v, lo), hi) }
