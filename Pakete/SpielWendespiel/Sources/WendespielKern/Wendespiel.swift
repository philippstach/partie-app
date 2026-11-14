// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Wendespiel (Reversi): 8×8, Spieler 1 (schwarz) und 2 (weiß). Gegnersteine zwischen zwei eigenen werden gewendet.
public struct Wendespiel: Equatable, Sendable, Codable {
    public private(set) var brett = [Int](repeating: 0, count: 64)
    public private(set) var dran = 1
    /// Verkehrt (Anti-Reversi): Wer am Ende die wenigsten Steine hat, gewinnt.
    public private(set) var verkehrt = false

    public init(verkehrt: Bool = false) {
        self.verkehrt = verkehrt
        brett[27] = 2; brett[36] = 2; brett[28] = 1; brett[35] = 1
    }

    private enum CodingKeys: String, CodingKey { case brett, dran, verkehrt }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        brett = try c.decode([Int].self, forKey: .brett)
        dran = try c.decode(Int.self, forKey: .dran)
        verkehrt = try c.decodeIfPresent(Bool.self, forKey: .verkehrt) ?? false   // alte Spielstände
    }

    static let richtungen = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

    public func zuege(fuer s: Int) -> [Int] { (0..<64).filter { !wendet($0, s).isEmpty } }
    public var zuege: [Int] { zuege(fuer: dran) }
    public func steine(_ s: Int) -> Int { brett.filter { $0 == s }.count }
    public var beendet: Bool { zuege(fuer: 1).isEmpty && zuege(fuer: 2).isEmpty }
    public var sieger: Int? {
        guard beendet else { return nil }
        let a = steine(1), b = steine(2)
        return a == b ? nil : ((a > b) != verkehrt ? 1 : 2)
    }

    /// Felder, die ein Stein von `s` auf `p` wenden würde.
    public func wendet(_ p: Int, _ s: Int) -> [Int] {
        guard brett[p] == 0 else { return [] }
        let z = p / 8, sp = p % 8
        var alle: [Int] = []
        for (dz, ds) in Wendespiel.richtungen {
            var r = z + dz, c = sp + ds, linie: [Int] = []
            while (0..<8).contains(r), (0..<8).contains(c), brett[r * 8 + c] == 3 - s { linie.append(r * 8 + c); r += dz; c += ds }
            if !linie.isEmpty, (0..<8).contains(r), (0..<8).contains(c), brett[r * 8 + c] == s { alle += linie }
        }
        return alle
    }

    @discardableResult
    public mutating func setze(_ p: Int) -> Bool {
        let w = wendet(p, dran)
        guard !w.isEmpty else { return false }
        brett[p] = dran; for i in w { brett[i] = dran }
        dran = 3 - dran
        if zuege.isEmpty && !beendet { dran = 3 - dran }   // Gegner muss passen
        return true
    }
}

public enum WendespielComputer {
    static let gewicht: [Int] = {
        let ecke = 100, kante = 10, innen = 1
        return (0..<64).map { i in
            let z = i / 8, s = i % 8
            let randZ = z == 0 || z == 7, randS = s == 0 || s == 7
            if randZ && randS { return ecke }
            if (z == 1 || z == 6) && (s == 1 || s == 6) { return -20 }
            if randZ || randS { return kante }
            return innen
        }
    }()

    /// Stellungswert aus Sicht von `ich`: Feldgewichte (Felder neben einer leeren Ecke sind schlecht), Beweglichkeit, Eckenbesitz.
    static func bewerte(_ w: Wendespiel, _ ich: Int) -> Int {
        if w.verkehrt {
            // Verkehrt: wenig eigene Steine, viel Beweglichkeit
            let beweglich = w.zuege(fuer: ich).count - w.zuege(fuer: 3 - ich).count
            return (w.steine(3 - ich) - w.steine(ich)) + beweglich * 4
        }
        var v = 0
        let ecken = [0, 7, 56, 63]
        for i in 0..<64 where w.brett[i] != 0 {
            var g = gewicht[i]
            if g == -20 || (g == 10 && false) {
                // X-Felder: nur schlecht, solange die Ecke daneben leer ist
                let nahe = ecken.min { abs($0 / 8 - i / 8) + abs($0 % 8 - i % 8) < abs($1 / 8 - i / 8) + abs($1 % 8 - i % 8) }!
                if w.brett[nahe] != 0 { g = 5 }
            }
            v += w.brett[i] == ich ? g : -g
        }
        // Randsteine (Nachbarn von leeren Feldern) geben dem Gegner Züge: wer weniger davon hat, steht besser
        var rand = [0, 0, 0]
        for i in 0..<64 where w.brett[i] != 0 {
            let z = i / 8, sp = i % 8
            outer: for dz in -1...1 { for ds in -1...1 where !(dz == 0 && ds == 0) {
                let r = z + dz, c = sp + ds
                if (0..<8).contains(r), (0..<8).contains(c), w.brett[r * 8 + c] == 0 { rand[w.brett[i]] += 1; break outer }
            } }
        }
        v -= (rand[ich] - rand[3 - ich]) * 3
        // Beweglichkeit: wer mehr Zugmöglichkeiten hat, diktiert das Spiel (wichtigster Faktor im Mittelspiel)
        v += (w.zuege(fuer: ich).count - w.zuege(fuer: 3 - ich).count) * 6
        return v
    }

    /// `tiefe`: Suchtiefe; bei höchstens 9 freien Feldern wird bis zum Ende exakt gerechnet.
    /// `fehler` (0…1): Wahrscheinlichkeit, einen zufälligen der besseren Züge zu spielen.
    public static func wahl(_ w: Wendespiel, tiefe: Int = 3, fehler: Double = 0) -> Int? {
        let z = w.zuege
        guard !z.isEmpty else { return nil }
        let frei = w.brett.filter { $0 == 0 }.count
        let exakt = frei <= 8
        let t = exakt ? frei : tiefe
        let ich = w.dran
        var bewertet: [(Int, Int)] = []
        for p in z {
            var n = w; n.setze(p)
            bewertet.append((p, suche(n, t - 1, Int.min, Int.max, ich, exakt)))
        }
        bewertet.sort { $0.1 > $1.1 }
        if fehler > 0, bewertet.count > 1, Double.random(in: 0..<1) < fehler {
            return bewertet[0..<max(2, (bewertet.count + 1) / 2)].randomElement()!.0
        }
        let top = bewertet[0].1
        return bewertet.filter { $0.1 >= top - 2 }.randomElement()!.0
    }

    private static func suche(_ w: Wendespiel, _ t: Int, _ alpha: Int, _ beta: Int, _ ich: Int, _ exakt: Bool) -> Int {
        if w.beendet { return (w.steine(ich) - w.steine(3 - ich)) * (w.verkehrt ? -50 : 50) }
        if t <= 0 { return bewerte(w, ich) }
        var a = alpha, b = beta
        let m = w.dran == ich
        var wert = m ? Int.min : Int.max
        for p in w.zuege {
            var n = w; n.setze(p)
            let v = suche(n, t - 1, a, b, ich, exakt)
            if m { wert = max(wert, v); a = max(a, v) } else { wert = min(wert, v); b = min(b, v) }
            if b <= a { break }
        }
        return wert
    }
}
