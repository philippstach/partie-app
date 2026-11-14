// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Halma (8×8, je zehn Steine): Alle Steine ins gegenüberliegende Lager bringen. Ziehen: ein Feld in jede Richtung oder in Sprüngen über Steine.
public struct Halma: Equatable, Sendable, Codable {
    public static let n = 8
    public private(set) var brett = [Int](repeating: 0, count: 64)
    public private(set) var dran = 1
    /// Anzahl gespielter Züge beider Seiten; nach 300 Zügen entscheidet der Fortschritt.
    public private(set) var zuege = 0
    public static let zeitlimit = 300

    public init() {
        for i in Halma.lager(1) { brett[i] = 1 }
        for i in Halma.lager(2) { brett[i] = 2 }
    }

    /// Startlager: Spieler 1 unten links, Spieler 2 oben rechts.
    public static func lager(_ s: Int) -> [Int] {
        (0..<64).filter { i in
            let r = i / 8, c = i % 8
            return s == 1 ? (c + (7 - r) <= 3) : (r + (7 - c) <= 3)
        }
    }
    public static func ziel(_ s: Int) -> [Int] { lager(3 - s) }

    public func steine(_ s: Int) -> [Int] { (0..<64).filter { brett[$0] == s } }
    public var sieger: Halma.Sieger? { Halma.pruefe(brett) }
    public var zeitUm: Bool { zuege >= Halma.zeitlimit && sieger == nil }
    public var vorbei: Bool { sieger != nil || zeitUm }

    /// Abstand eines Feldes zur Zielecke des Spielers `s` (Summe aus Zeilen- und Spaltenabstand).
    public static func abstand(_ i: Int, _ s: Int) -> Int {
        let r = i / 8, c = i % 8
        return s == 1 ? r + (7 - c) : (7 - r) + c
    }
    /// Fortschritt: je näher die Steine an der Zielecke, desto höher.
    public func fortschritt(_ s: Int) -> Int { steine(s).reduce(0) { $0 + (14 - Halma.abstand($1, s)) } }
    /// Nach Zeitablauf: Sieger nach Fortschritt (nil bei Gleichstand).
    public var siegerNachZeit: Int? {
        guard zeitUm else { return nil }
        let a = fortschritt(1), b = fortschritt(2)
        return a == b ? nil : (a > b ? 1 : 2)
    }
    public enum Sieger: Equatable, Sendable { case spieler(Int) }

    static func pruefe(_ b: [Int]) -> Sieger? {
        for s in [1, 2] {
            let z = ziel(s)
            if z.allSatisfy({ b[$0] != 0 }) && z.contains(where: { b[$0] == s }) { return .spieler(s) }
        }
        return nil
    }

    /// Erreichbare Felder für den Stein auf `von` (Schritt oder Sprungkette).
    public func ziele(von: Int) -> Set<Int> {
        guard brett[von] != 0 else { return [] }
        var erg = Set<Int>()
        let r = von / 8, c = von % 8
        for dr in -1...1 { for dc in -1...1 where !(dr == 0 && dc == 0) {
            let nr = r + dr, nc = c + dc
            if (0..<8).contains(nr), (0..<8).contains(nc), brett[nr * 8 + nc] == 0 { erg.insert(nr * 8 + nc) }
        } }
        var besucht: Set<Int> = [von], offen = [von]
        while let p = offen.popLast() {
            let pr = p / 8, pc = p % 8
            for dr in -1...1 { for dc in -1...1 where !(dr == 0 && dc == 0) {
                let mr = pr + dr, mc = pc + dc, lr = pr + 2 * dr, lc = pc + 2 * dc
                guard (0..<8).contains(lr), (0..<8).contains(lc), brett[mr * 8 + mc] != 0, brett[lr * 8 + lc] == 0 || lr * 8 + lc == von else { continue }
                let l = lr * 8 + lc
                if !besucht.contains(l) { besucht.insert(l); offen.append(l); erg.insert(l) }
            } }
        }
        erg.remove(von)
        return erg
    }

    @discardableResult
    public mutating func ziehe(von: Int, nach: Int) -> Bool {
        guard !vorbei, brett[von] == dran, ziele(von: von).contains(nach) else { return false }
        brett[nach] = dran; brett[von] = 0
        dran = 3 - dran; zuege += 1
        return true
    }

    public var alleZuege: [(Int, Int)] { steine(dran).flatMap { v in ziele(von: v).map { (v, $0) } } }
}

public enum HalmaComputer {
    private static func abstand(_ i: Int, _ s: Int) -> Int { Halma.abstand(i, s) }

    /// Stellungswert aus Sicht von `s`: eigener Fortschritt minus gegnerischer, Nachzügler werden bestraft, Steine im Ziel belohnt.
    static func bewerte(_ h: Halma, _ s: Int) -> Double {
        func wert(_ p: Int) -> Double {
            let st = h.steine(p)
            let ziel = Set(Halma.ziel(p))
            var w = Double(st.reduce(0) { $0 + (14 - abstand($1, p)) }) * 2
            w += Double(st.filter { ziel.contains($0) }.count) * 3
            if let schlecht = st.map({ abstand($0, p) }).max() { w -= Double(schlecht) * 1.5 }     // letzter Stein bremst
            return w
        }
        return wert(s) - wert(3 - s)
    }

    private static func zuegeGeordnet(_ h: Halma, _ s: Int, _ breite: Int) -> [(Int, Int)] {
        let ziel = Set(Halma.ziel(s))
        func vor(_ z: (Int, Int)) -> Double {
            var w = Double(abstand(z.0, s) - abstand(z.1, s)) * 2
            if ziel.contains(z.1) && !ziel.contains(z.0) { w += 3 }
            if ziel.contains(z.0) && !ziel.contains(z.1) { w -= 8 }
            w += Double(abstand(z.0, s)) * 0.1      // hinten liegende Steine zuerst
            return w
        }
        return Array(h.alleZuege.sorted { vor($0) > vor($1) }.prefix(breite))
    }

    private static func suche(_ h: Halma, _ tiefe: Int, _ alpha: Double, _ beta: Double, _ ich: Int, _ breite: Int) -> Double {
        if case .spieler(let s)? = h.sieger { return s == ich ? 10_000 + Double(tiefe) : -10_000 - Double(tiefe) }
        if h.zeitUm { return 0 }
        if tiefe == 0 { return bewerte(h, ich) }
        let max_ = h.dran == ich
        var a = alpha, b = beta
        var best = max_ ? -Double.infinity : Double.infinity
        for z in zuegeGeordnet(h, h.dran, breite) {
            var n = h; n.ziehe(von: z.0, nach: z.1)
            let w = suche(n, tiefe - 1, a, b, ich, breite)
            if max_ { best = max(best, w); a = max(a, w) } else { best = min(best, w); b = min(b, w) }
            if b <= a { break }
        }
        return best.isFinite ? best : bewerte(h, ich)
    }

    /// `tiefe` 1 = einfacher Zug mit etwas Zufall; ab 2 Vorausschau (Alpha-Beta) über die `breite` besten Kandidaten je Ebene.
    public static func wahl<G: RandomNumberGenerator>(_ h: Halma, tiefe: Int = 1, breite: Int = 12, mit g: inout G) -> (Int, Int)? {
        let s = h.dran
        guard !h.alleZuege.isEmpty else { return nil }
        if tiefe <= 1 {
            let ziel = Set(Halma.ziel(s))
            func wert(_ z: (Int, Int)) -> Double {
                var w = Double(abstand(z.0, s) - abstand(z.1, s)) * 2
                if ziel.contains(z.1) && !ziel.contains(z.0) { w += 3 }
                if ziel.contains(z.0) && !ziel.contains(z.1) { w -= 8 }
                return w + Double.random(in: 0..<1.5, using: &g)
            }
            return h.alleZuege.max { wert($0) < wert($1) }
        }
        var beste: (Int, Int)?; var bw = -Double.infinity
        for z in zuegeGeordnet(h, s, breite) {
            var n = h; n.ziehe(von: z.0, nach: z.1)
            let w = suche(n, tiefe - 1, -Double.infinity, Double.infinity, s, breite) + Double.random(in: 0..<0.3, using: &g)
            if w > bw { bw = w; beste = z }
        }
        return beste
    }
}
