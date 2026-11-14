// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Sechseck (Hex-Art): Auf einem Raster aus Sechsecken setzen zwei Spieler abwechselnd Steine.
/// Spieler 1 (Blau) verbindet oben mit unten, Spieler 2 (Rot) links mit rechts. Unentschieden gibt es nicht.
public struct Sechseck: Equatable, Sendable, Codable {
    public let n: Int
    public private(set) var zellen: [Int]         // 0 leer, 1 oder 2
    public private(set) var amZug = 1
    public private(set) var zuege = 0
    public private(set) var sieger: Int?
    public private(set) var letzter: Int?

    /// Nachbarn in Rautenanordnung (x + y/2).
    public static let nachbarn = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, -1), (-1, 1)]

    public init(groesse: Int) { n = groesse; zellen = Array(repeating: 0, count: groesse * groesse) }

    public func index(_ x: Int, _ y: Int) -> Int { y * n + x }
    public func nachbarIndizes(_ i: Int) -> [Int] {
        let x = i % n, y = i / n
        return Sechseck.nachbarn.compactMap { d in
            let nx = x + d.0, ny = y + d.1
            return (0..<n).contains(nx) && (0..<n).contains(ny) ? ny * n + nx : nil
        }
    }

    public var freie: [Int] { zellen.indices.filter { zellen[$0] == 0 } }

    @discardableResult
    public mutating func setze(_ i: Int) -> Bool {
        guard sieger == nil, zellen.indices.contains(i), zellen[i] == 0 else { return false }
        zellen[i] = amZug; letzter = i; zuege += 1
        if verbunden(amZug) { sieger = amZug } else { amZug = 3 - amZug }
        return true
    }

    public func verbunden(_ s: Int) -> Bool { Sechseck.verbunden(zellen, n, s) }

    static func verbunden(_ z: [Int], _ n: Int, _ s: Int) -> Bool {
        var gesehen = Array(repeating: false, count: z.count); var stapel: [Int] = []
        for k in 0..<n { let i = s == 1 ? k : k * n; if z[i] == s { gesehen[i] = true; stapel.append(i) } }
        while let i = stapel.popLast() {
            let x = i % n, y = i / n
            if s == 1 ? y == n - 1 : x == n - 1 { return true }
            for d in nachbarn {
                let nx = x + d.0, ny = y + d.1
                guard (0..<n).contains(nx), (0..<n).contains(ny) else { continue }
                let j = ny * n + nx
                if z[j] == s && !gesehen[j] { gesehen[j] = true; stapel.append(j) }
            }
        }
        return false
    }

    // MARK: Computer (Monte Carlo)

    /// Wählt einen Zug durch zufällige Zuspiele. `spiele` = Zuspiele je Kandidat.
    public func computerZug<G: RandomNumberGenerator>(spiele: Int, mit g: inout G) -> Int? {
        let frei = freie
        guard !frei.isEmpty else { return nil }
        if zuege == 0 { return index(n / 2, n / 2) }
        // Sofortiger Gewinn und sofortige Abwehr
        for s in [amZug, 3 - amZug] {
            for i in frei { var z = zellen; z[i] = s; if Sechseck.verbunden(z, n, s) { return i } }
        }
        if spiele <= 0 { return frei.randomElement(using: &g) }
        // Kandidaten: Felder in der Nähe von Steinen (und Mitte)
        var kandidaten = frei.filter { i in nachbarIndizes(i).contains { zellen[$0] != 0 } || nachbarIndizes(i).contains { j in nachbarIndizes(j).contains { zellen[$0] != 0 } } }
        if kandidaten.isEmpty { kandidaten = frei }
        var bester = kandidaten[0]; var bestRate = -1.0
        for i in kandidaten {
            var siege = 0
            for _ in 0..<spiele {
                var z = zellen; z[i] = amZug
                var rest = frei.filter { $0 != i }; rest.shuffle(using: &g)
                var s = 3 - amZug
                for j in rest { z[j] = s; s = 3 - s }
                if Sechseck.verbunden(z, n, amZug) { siege += 1 }
            }
            let rate = Double(siege) / Double(spiele)
            if rate > bestRate { bestRate = rate; bester = i }
        }
        return bester
    }
}
