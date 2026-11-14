// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Farbflut: Ein buntes Feld, die Flut beginnt in der linken oberen Ecke. Bei jedem Zug wählst du eine Farbe; die ganze Flutfläche
/// nimmt diese Farbe an und schluckt alle angrenzenden Felder dieser Farbe. Ziel: das ganze Feld in einer Farbe, bevor die Züge ausgehen.
public struct Farbflut: Equatable, Sendable, Codable {
    public let n: Int, farben: Int
    public private(set) var feld: [Int]
    public private(set) var zuege = 0
    public let limit: Int
    private var verlauf: [[Int]] = []

    public init<G: RandomNumberGenerator>(groesse: Int, farben: Int, luft: Int, mit g: inout G) {
        n = groesse; self.farben = farben
        var f = (0..<(groesse * groesse)).map { _ in Int.random(in: 0..<farben, using: &g) }
        if f.allSatisfy({ $0 == f[0] }) { f[1] = (f[0] + 1) % farben }
        feld = f
        // Limit = Länge der gierigen Lösung plus Luft: so ist die Stufe immer lösbar
        var k = Farbflut(feld: f, n: groesse, farben: farben, limit: Int.max)   // ohne Limit spielen, sonst käme die gierige Probe nie voran
        var schritte = 0
        while !k.geloest && schritte < 500 { k.zug(k.besteFarbeGierig()); schritte += 1 }
        limit = schritte + luft
    }

    private init(feld: [Int], n: Int, farben: Int, limit: Int) { self.feld = feld; self.n = n; self.farben = farben; self.limit = limit }

    /// Das Feld vom Anfang der Partie (Ergebnisseite, Blatt 22); `nil`, wenn noch kein Zug gemacht wurde. Nach dem Ende gibt es kein „Zurück“ mehr, der Anfang bleibt also sicher.
    public var anfang: [Int]? { verlauf.first }

    public var geloest: Bool { feld.allSatisfy { $0 == feld[0] } }
    public var vorbei: Bool { geloest || zuege >= limit }
    public var verbleibend: Int { limit - zuege }
    public var aktuelleFarbe: Int { feld[0] }

    /// Felder der Flut (zusammenhängend von links oben, gleiche Farbe).
    public var flut: Set<Int> {
        var s: Set<Int> = [0]; var st = [0]; let c = feld[0]
        while let i = st.popLast() {
            for j in nachbarn(i) where feld[j] == c && !s.contains(j) { s.insert(j); st.append(j) }
        }
        return s
    }

    func nachbarn(_ i: Int) -> [Int] {
        let x = i % n, y = i / n
        var r: [Int] = []
        if x > 0 { r.append(i - 1) }; if x < n - 1 { r.append(i + 1) }; if y > 0 { r.append(i - n) }; if y < n - 1 { r.append(i + n) }
        return r
    }

    @discardableResult
    public mutating func zug(_ farbe: Int) -> Bool {
        guard !vorbei, (0..<farben).contains(farbe), farbe != feld[0] else { return false }
        verlauf.append(feld)
        for i in flut { feld[i] = farbe }
        zuege += 1
        return true
    }

    /// Nach dem Ende der Partie (gelöst oder keine Züge mehr) lässt sich nichts mehr zurücknehmen:
    /// Sonst könnte man eine verlorene Partie beliebig oft zurückspulen.
    public var kannZurueck: Bool { !verlauf.isEmpty && !vorbei }
    public mutating func zurueck() {
        guard !vorbei else { return }
        if let f = verlauf.popLast(), f.count == feld.count { feld = f; zuege = max(0, zuege - 1) }
    }

    /// Die Farbe, die gerade die meisten Felder zur Flut dazubringt (gierig).
    public func besteFarbeGierig() -> Int {
        var beste = (feld[0] + 1) % farben; var meiste = -1
        for c in 0..<farben where c != feld[0] {
            var k = self
            let vorher = flut.count
            for i in flut { k.feld[i] = c }
            let gewinn = k.flut.count - vorher
            if gewinn > meiste { meiste = gewinn; beste = c }
        }
        return beste
    }
}
