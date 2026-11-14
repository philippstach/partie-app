// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct DamenZug: Equatable, Hashable, Sendable {
    public let pfad: [Int]          // Start, Zwischenlandungen, Ziel
    public let geschlagen: [Int]
    public var start: Int { pfad[0] }
    public var ziel: Int { pfad[pfad.count - 1] }
}

/// Regelvarianten der Dame. Standard = deutsche Art.
public struct DameRegeln: Equatable, Sendable, Codable {
    /// Schlagen ist Pflicht.
    public var schlagzwang = true
    /// Damen ziehen und schlagen beliebig weit (sonst nur ein Feld, wie in der englischen Dame).
    public var fliegendeDame = true
    /// Männer dürfen auch rückwärts schlagen (sonst nur vorwärts).
    public var maennerSchlagenRueckwaerts = true
    public init(schlagzwang: Bool = true, fliegendeDame: Bool = true, maennerSchlagenRueckwaerts: Bool = true) {
        self.schlagzwang = schlagzwang; self.fliegendeDame = fliegendeDame; self.maennerSchlagenRueckwaerts = maennerSchlagenRueckwaerts
    }
    public static let deutsch = DameRegeln()
    public static let englisch = DameRegeln(fliegendeDame: false, maennerSchlagenRueckwaerts: false)
    public static let locker = DameRegeln(schlagzwang: false)
}

/// Dame (deutsche Art): Männer ziehen vorwärts und schlagen in alle Richtungen, Damen fliegen. Schlagzwang.
/// Steine: 0 leer, 1/2 Mann von Spieler 1/2, 3/4 Dame von Spieler 1/2. Spieler 1 steht unten und beginnt.
public struct Dame: Equatable, Sendable, Codable {
    public private(set) var brett = [Int](repeating: 0, count: 64)
    public private(set) var dran = 1
    /// Halbzüge ohne Schlag und ohne Männerzug; bei 80 (40 pro Seite) ist die Partie remis.
    public private(set) var ruhigeZuege = 0
    public private(set) var regeln = DameRegeln.deutsch
    public var remis: Bool { ruhigeZuege >= 80 }
    public var vorbei: Bool { remis || zuege.isEmpty }

    public init(regeln: DameRegeln = .deutsch) {
        self.regeln = regeln
        for i in 0..<64 {
            let r = i / 8, c = i % 8
            guard (r + c) % 2 == 1 else { continue }
            if r < 3 { brett[i] = 2 } else if r > 4 { brett[i] = 1 }
        }
    }

    /// Beliebige Stellung (Tests, Aufgaben).
    public init(brett: [Int], dran: Int, regeln: DameRegeln = .deutsch) { self.brett = brett; self.dran = dran; self.regeln = regeln }

    private enum CodingKeys: String, CodingKey { case brett, dran, ruhigeZuege, regeln }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        brett = try c.decode([Int].self, forKey: .brett)
        dran = try c.decode(Int.self, forKey: .dran)
        ruhigeZuege = try c.decodeIfPresent(Int.self, forKey: .ruhigeZuege) ?? 0
        regeln = try c.decodeIfPresent(DameRegeln.self, forKey: .regeln) ?? .deutsch   // alte Spielstände: deutsche Regeln
    }

    static func gehoertZu(_ stein: Int) -> Int { stein == 0 ? 0 : (stein % 2 == 1 ? 1 : 2) }
    static func istDame(_ stein: Int) -> Bool { stein >= 3 }
    static let diagonalen = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    static func inBrett(_ r: Int, _ c: Int) -> Bool { (0..<8).contains(r) && (0..<8).contains(c) }

    public func steine(_ s: Int) -> Int { brett.filter { Dame.gehoertZu($0) == s }.count }

    public var zuege: [DamenZug] {
        var schlaege: [DamenZug] = [], leise: [DamenZug] = []
        for i in 0..<64 where Dame.gehoertZu(brett[i]) == dran {
            sammleSchlaege(von: i, stein: brett[i], pfad: [i], geschlagen: [], erg: &schlaege)
            leise += leiseZuege(i)
        }
        return schlaege.isEmpty || !regeln.schlagzwang ? schlaege + leise : schlaege
    }
    /// Gibt es einen Schlag, den man machen müsste?
    public var schlagPflicht: Bool { regeln.schlagzwang && zuege.first?.geschlagen.isEmpty == false }

    private func leiseZuege(_ i: Int) -> [DamenZug] {
        let stein = brett[i], r = i / 8, c = i % 8
        var erg: [DamenZug] = []
        for (dr, dc) in Dame.diagonalen {
            if !Dame.istDame(stein), dr != (dran == 1 ? -1 : 1) { continue }
            var rr = r + dr, cc = c + dc
            while Dame.inBrett(rr, cc), brett[rr * 8 + cc] == 0 {
                erg.append(DamenZug(pfad: [i, rr * 8 + cc], geschlagen: []))
                if !(Dame.istDame(stein) && regeln.fliegendeDame) { break }
                rr += dr; cc += dc
            }
        }
        return erg
    }

    private func sammleSchlaege(von i: Int, stein: Int, pfad: [Int], geschlagen: [Int], erg: inout [DamenZug]) {
        let r = i / 8, c = i % 8
        var weiter = false
        let fliegt = Dame.istDame(stein) && regeln.fliegendeDame
        for (dr, dc) in Dame.diagonalen {
            if !Dame.istDame(stein), !regeln.maennerSchlagenRueckwaerts, dr != (dran == 1 ? -1 : 1) { continue }
            var rr = r + dr, cc = c + dc
            if fliegt {
                while Dame.inBrett(rr, cc), brett[rr * 8 + cc] == 0 || rr * 8 + cc == pfad[0] { rr += dr; cc += dc }
            }
            guard Dame.inBrett(rr, cc) else { continue }
            let p = rr * 8 + cc
            guard Dame.gehoertZu(brett[p]) == 3 - dran, !geschlagen.contains(p) else { continue }
            var lr = rr + dr, lc = cc + dc
            var landungen: [Int] = []
            while Dame.inBrett(lr, lc), brett[lr * 8 + lc] == 0 || lr * 8 + lc == pfad[0] {
                landungen.append(lr * 8 + lc)
                if !fliegt { break }
                lr += dr; lc += dc
            }
            for l in landungen {
                weiter = true
                sammleSchlaege(von: l, stein: stein, pfad: pfad + [l], geschlagen: geschlagen + [p], erg: &erg)
            }
        }
        if !weiter, !geschlagen.isEmpty { erg.append(DamenZug(pfad: pfad, geschlagen: geschlagen)) }
    }

    @discardableResult
    public mutating func spiele(_ z: DamenZug) -> Bool {
        guard zuege.contains(z) else { return false }
        var stein = brett[z.start]
        if z.geschlagen.isEmpty, Dame.istDame(stein) { ruhigeZuege += 1 } else { ruhigeZuege = 0 }
        brett[z.start] = 0
        for g in z.geschlagen { brett[g] = 0 }
        let zr = z.ziel / 8
        if !Dame.istDame(stein), (dran == 1 && zr == 0) || (dran == 2 && zr == 7) { stein += 2 }
        brett[z.ziel] = stein
        dran = 3 - dran
        return true
    }

    public var sieger: Int? { remis ? nil : (zuege.isEmpty ? 3 - dran : nil) }
}

/// Spielstärke des Computers: Suchtiefe und Wahrscheinlichkeit eines absichtlichen Patzers (Zug aus der besseren Hälfte).
public enum DameStaerke: CaseIterable, Sendable {
    case leicht, mittel, schwer
    public var tiefe: Int { switch self { case .leicht: 2; case .mittel: 4; case .schwer: 7 } }
    public var fehler: Double { switch self { case .leicht: 0.3; case .mittel: 0.08; case .schwer: 0 } }
}

public enum DameComputer {
    public static func wahl(_ d: Dame, staerke: DameStaerke) -> DamenZug? { wahl(d, tiefe: staerke.tiefe, fehler: staerke.fehler) }

    public static func wahl(_ d: Dame, tiefe: Int = 5, fehler: Double = 0) -> DamenZug? {
        let z = d.zuege
        guard !z.isEmpty else { return nil }
        if z.count == 1 { return z[0] }
        let ich = d.dran
        var bewertet: [(DamenZug, Int)] = []
        var alpha = -1_000_000
        for m in sortiert(z.shuffled(), d) {
            var n = d; n.spiele(m)
            let w = suche(n, tiefe - 1, fehler > 0 ? -1_000_000 : alpha - 3, Int.max, ich)
            bewertet.append((m, w))
            if fehler == 0 { alpha = max(alpha, w) }
        }
        bewertet.sort { $0.1 > $1.1 }
        if fehler > 0, bewertet.count > 2, Double.random(in: 0..<1) < fehler {
            return bewertet[0..<max(2, bewertet.count / 2)].randomElement()!.0
        }
        let top = bewertet[0].1
        let toleranz = abs(top) > 90000 ? 0 : 2     // Matt-Abstände nie verwischen
        return bewertet.filter { $0.1 >= top - toleranz }.randomElement()!.0
    }

    /// Schläge zuerst (und die längsten), dann Züge Richtung Damenreihe: bessere Beschneidung.
    private static func sortiert(_ z: [DamenZug], _ d: Dame) -> [DamenZug] {
        z.sorted { $0.geschlagen.count > $1.geschlagen.count }
    }

    private static func bewerte(_ d: Dame, _ ich: Int) -> Int {
        var w = 0
        for i in 0..<64 where d.brett[i] != 0 {
            let s = d.brett[i], eigen = Dame.gehoertZu(s) == ich
            var v = Dame.istDame(s) ? 30 : 10
            if !Dame.istDame(s) { let reihe = i / 8; v += Dame.gehoertZu(s) == 1 ? (7 - reihe) : reihe }
            w += eigen ? v : -v
        }
        return w
    }

    private static func suche(_ d: Dame, _ t: Int, _ alpha: Int, _ beta: Int, _ ich: Int) -> Int {
        if d.remis { return 0 }
        if let s = d.sieger { return s == ich ? 100_000 + t : -100_000 - t }
        if t == 0 { return bewerte(d, ich) }
        var a = alpha, b = beta
        let m = d.dran == ich
        var wert = m ? Int.min : Int.max
        for z in sortiert(d.zuege, d) {
            var n = d; n.spiele(z)
            let v = suche(n, t - 1, a, b, ich)
            if m { wert = max(wert, v); a = max(a, v) } else { wert = min(wert, v); b = min(b, v) }
            if b <= a { break }
        }
        return wert
    }
}
