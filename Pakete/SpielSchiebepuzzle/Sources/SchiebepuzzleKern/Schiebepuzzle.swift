// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Schiebepuzzle: n×n-Brett, 0 = Lücke. Gemischt wird durch zufällige gültige Züge, damit jedes Brett lösbar ist.
public struct Schiebepuzzle: Equatable, Sendable, Codable {
    public let n: Int
    public private(set) var felder: [Int]
    public private(set) var zuege = 0

    public init(n: Int) { self.n = n; felder = Array(1..<(n * n)) + [0] }

    public var geloest: Bool { felder == Array(1..<(n * n)) + [0] }
    public var luecke: Int { felder.firstIndex(of: 0)! }

    public func nachbarn(von i: Int) -> [Int] {
        let z = i / n, s = i % n
        var r: [Int] = []
        if z > 0 { r.append(i - n) }; if z < n - 1 { r.append(i + n) }
        if s > 0 { r.append(i - 1) }; if s < n - 1 { r.append(i + 1) }
        return r
    }

    /// Kachel an Position i verschiebt sich in die Lücke, wenn sie angrenzt (oder die ganze Reihe bis zur Lücke).
    @discardableResult
    public mutating func schiebe(_ i: Int) -> Bool {
        let l = luecke
        guard i != l else { return false }
        let zi = i / n, si = i % n, zl = l / n, sl = l % n
        guard zi == zl || si == sl else { return false }
        let schritt = zi == zl ? (i < l ? 1 : -1) : (i < l ? n : -n)
        var pos = l
        while pos != i { felder[pos] = felder[pos - schritt]; pos -= schritt }
        felder[i] = 0
        zuege += 1
        return true
    }

    /// T-086: Mischzüge wachsen mit der Feldgröße (vorher überall 200, auf 6×6 zu leicht). 3×3 bleibt bei 200.
    public static func mischZuege(n: Int) -> Int {
        switch n { case ...3: 200; case 4: 500; case 5: 1000; default: 2000 }
    }

    /// Mischt mit einem Zufallsgang aus lauter erlaubten Zügen; so bleibt jedes Brett lösbar. Ohne Angabe richtet sich die Zahl der Züge nach der Größe.
    public mutating func mischen<G: RandomNumberGenerator>(zuege anzahl: Int? = nil, mit g: inout G) {
        var letzte = -1
        for _ in 0..<(anzahl ?? Self.mischZuege(n: n)) {
            let optionen = nachbarn(von: luecke).filter { $0 != letzte }
            let wahl = optionen.randomElement(using: &g)!
            letzte = luecke
            schiebe(wahl)
        }
        if geloest { schiebe(nachbarn(von: luecke)[0]) }
        zuege = 0
    }

    private static func manhattan(_ f: [Int], _ n: Int) -> Int {
        var h = 0
        for (i, w) in f.enumerated() where w != 0 { h += abs((w - 1) / n - i / n) + abs((w - 1) % n - i % n) }
        return h
    }

    /// Tipp: die Kachel (Position), die du als Nächstes verschieben solltest. Auf 3×3 und meist auch 4×4 liegt sie auf einem kürzesten Weg
    /// (IDA* mit Manhattan-Abstand); bei sehr schwierigen Brettern wird ein Zug gewählt, der den Abstand verringert.
    public func hinweis() -> Int? {
        guard !geloest else { return nil }
        let n = n
        var f = felder
        var knoten = 0
        let grenzeKnoten = 400_000
        var bester: Int?
        func suche(_ g: Int, _ grenze: Int, _ luecke: Int, _ vorher: Int, _ h: Int) -> Int {
            let ff = g + h
            if ff > grenze { return ff }
            if h == 0 { return -1 }
            knoten += 1
            if knoten > grenzeKnoten { return Int.max }
            var minimum = Int.max
            let z = luecke / n, sp = luecke % n
            var nachbarn: [Int] = []
            if z > 0 { nachbarn.append(luecke - n) }; if z < n - 1 { nachbarn.append(luecke + n) }
            if sp > 0 { nachbarn.append(luecke - 1) }; if sp < n - 1 { nachbarn.append(luecke + 1) }
            for k in nachbarn where k != vorher {
                let w = f[k]
                let alt = abs((w - 1) / n - k / n) + abs((w - 1) % n - k % n), neu = abs((w - 1) / n - luecke / n) + abs((w - 1) % n - luecke % n)
                f[luecke] = w; f[k] = 0
                let r = suche(g + 1, grenze, k, luecke, h - alt + neu)
                f[k] = w; f[luecke] = 0
                if r == -1 { if g == 0 { bester = k }; return -1 }
                if r == Int.max { return Int.max }
                minimum = min(minimum, r)
            }
            return minimum
        }
        var grenze = Schiebepuzzle.manhattan(f, n)
        while true {
            let r = suche(0, grenze, luecke, -1, Schiebepuzzle.manhattan(f, n))
            if r == -1 { return bester }
            if r == Int.max { break }
            grenze = r
        }
        // Rückfall: Zug mit dem kleinsten Manhattan-Abstand
        let l = luecke
        return nachbarn(von: l).min { a, b in
            var fa = felder; fa.swapAt(l, a); var fb = felder; fb.swapAt(l, b)
            return Schiebepuzzle.manhattan(fa, n) < Schiebepuzzle.manhattan(fb, n)
        }
    }
}
