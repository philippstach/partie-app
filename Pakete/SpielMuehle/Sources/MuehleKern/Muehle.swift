// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public enum MuehleZug: Equatable, Hashable, Sendable {
    case setze(Int)
    case ziehe(Int, Int)
    case entferne(Int)
}

/// Regelvarianten der Mühle. Standard = klassische Neunermühle.
public struct MuehleRegeln: Equatable, Sendable, Codable {
    /// Steine je Spieler (9 klassisch, 6 = kürzere Sechsermühle).
    public var steine = 9
    /// Bei drei Steinen darf man springen.
    public var springen = true
    /// Steine aus einer Mühle dürfen auch dann geschlagen werden, wenn es andere gibt.
    public var schlagenAusMuehle = false
    public init(steine: Int = 9, springen: Bool = true, schlagenAusMuehle: Bool = false) {
        self.steine = steine; self.springen = springen; self.schlagenAusMuehle = schlagenAusMuehle
    }
    public static let klassisch = MuehleRegeln()
    public static let kurz = MuehleRegeln(steine: 6)
    public static let ohneSpringen = MuehleRegeln(springen: false)
    public static let streng = MuehleRegeln(schlagenAusMuehle: true)
}

/// Mühle (Nine Men's Morris): 24 Punkte in drei Quadraten, je neun Steine. Spieler 1 und 2.
public struct Muehle: Equatable, Sendable, Codable {
    public private(set) var brett = [Int](repeating: 0, count: 24)
    public private(set) var vorrat = [0, 9, 9]
    public private(set) var regeln = MuehleRegeln.klassisch
    public private(set) var dran = 1
    public private(set) var mussEntfernen = false
    /// Züge in der Zugphase seit der letzten Mühle; ab 60 ist die Partie remis.
    public private(set) var ruhigeZuege = 0
    /// Blatt 22 (Schritt 2): geschlossene Mühlen je Spieler (Index 1 und 2, Index 0 unbenutzt). Optional: Ein alter Stand lädt mit `nil`, dann wird nicht gezählt.
    public private(set) var geschlosseneMuehlen: [Int]? = [0, 0, 0]
    public var remis: Bool { ruhigeZuege >= 60 && sieger == nil }
    public var vorbei: Bool { sieger != nil || remis }

    /// 1.0 (M7): `beginner` (1 = Weiß, 2 = Schwarz) setzt den ersten Stein; Standard bleibt Weiß.
    public init(regeln: MuehleRegeln = .klassisch, beginner: Int = 1) {
        self.regeln = regeln; vorrat = [0, regeln.steine, regeln.steine]; dran = beginner == 2 ? 2 : 1
    }

    private enum CodingKeys: String, CodingKey { case brett, vorrat, dran, mussEntfernen, ruhigeZuege, regeln, geschlosseneMuehlen }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        brett = try c.decode([Int].self, forKey: .brett)
        vorrat = try c.decode([Int].self, forKey: .vorrat)
        dran = try c.decode(Int.self, forKey: .dran)
        mussEntfernen = try c.decode(Bool.self, forKey: .mussEntfernen)
        ruhigeZuege = try c.decodeIfPresent(Int.self, forKey: .ruhigeZuege) ?? 0
        regeln = try c.decodeIfPresent(MuehleRegeln.self, forKey: .regeln) ?? .klassisch   // alte Spielstände
        geschlosseneMuehlen = try c.decodeIfPresent([Int].self, forKey: .geschlosseneMuehlen)   // alte Spielstände: nil
    }

    /// Nachbarpunkte: im Ring k ↔ k±1, die Mitten (k ungerade) verbinden die Ringe.
    public static let nachbarn: [[Int]] = (0..<24).map { i in
        let r = i / 8, k = i % 8
        var n = [r * 8 + (k + 1) % 8, r * 8 + (k + 7) % 8]
        if k % 2 == 1 { if r > 0 { n.append((r - 1) * 8 + k) }; if r < 2 { n.append((r + 1) * 8 + k) } }
        return n
    }

    public static let muehlen: [[Int]] = {
        var m: [[Int]] = []
        for r in 0..<3 { let b = r * 8; m += [[b, b + 1, b + 2], [b + 2, b + 3, b + 4], [b + 4, b + 5, b + 6], [b + 6, b + 7, b]] }
        for k in [1, 3, 5, 7] { m.append([k, 8 + k, 16 + k]) }
        return m
    }()

    public func steine(_ s: Int) -> Int { brett.filter { $0 == s }.count }
    public func gesamt(_ s: Int) -> Int { steine(s) + vorrat[s] }
    public var gegner: Int { 3 - dran }
    public var setzphase: Bool { vorrat[dran] > 0 }

    public func inMuehle(_ p: Int) -> Bool {
        let s = brett[p]
        return s != 0 && Muehle.muehlen.contains { $0.contains(p) && $0.allSatisfy { brett[$0] == s } }
    }

    public func zuege() -> [MuehleZug] {
        if mussEntfernen {
            let g = (0..<24).filter { brett[$0] == gegner }
            let frei = g.filter { !inMuehle($0) }
            return (frei.isEmpty || regeln.schlagenAusMuehle ? g : frei).map(MuehleZug.entferne)
        }
        let leer = (0..<24).filter { brett[$0] == 0 }
        if vorrat[dran] > 0 { return leer.map(MuehleZug.setze) }
        let eigene = (0..<24).filter { brett[$0] == dran }
        if eigene.count == 3, regeln.springen { return eigene.flatMap { a in leer.map { MuehleZug.ziehe(a, $0) } } }
        return eigene.flatMap { a in Muehle.nachbarn[a].filter { brett[$0] == 0 }.map { MuehleZug.ziehe(a, $0) } }
    }

    /// Sieger (1 oder 2), sonst nil.
    public var sieger: Int? {
        guard !mussEntfernen else { return nil }
        for s in [1, 2] where vorrat[s] == 0 && steine(s) < 3 { return 3 - s }
        if zuege().isEmpty { return gegner }
        return nil
    }

    @discardableResult
    public mutating func spiele(_ z: MuehleZug) -> Bool {
        guard zuege().contains(z) else { return false }
        switch z {
        case .setze(let p):
            brett[p] = dran; vorrat[dran] -= 1
            abschluss(p)
        case .ziehe(let a, let b):
            brett[a] = 0; brett[b] = dran
            abschluss(b)
        case .entferne(let p):
            brett[p] = 0; mussEntfernen = false; dran = gegner; ruhigeZuege = 0
        }
        if case .ziehe = z { ruhigeZuege += 1 }
        return true
    }

    private mutating func abschluss(_ p: Int) {
        if inMuehle(p) {
            mussEntfernen = true
            if var m = geschlosseneMuehlen, m.count == 3 { m[dran] += 1; geschlosseneMuehlen = m }
        } else { dran = gegner }
    }
}

/// Spielstärke des Computers: Suchtiefe (Setzphase / Zugphase) und Wahrscheinlichkeit eines absichtlichen Patzers.
public enum MuehleStaerke: CaseIterable, Sendable {
    case leicht, mittel, schwer
    public var setzTiefe: Int { switch self { case .leicht: 1; case .mittel: 2; case .schwer: 4 } }
    public var zugTiefe: Int { switch self { case .leicht: 2; case .mittel: 3; case .schwer: 4 } }
    public var fehler: Double { switch self { case .leicht: 0.35; case .mittel: 0.1; case .schwer: 0 } }
}

/// Computergegner: Minimax mit Alpha-Beta. Das Entfernen eines Steins nach einer Mühle zählt nicht als Halbzug der Tiefe.
public enum MuehleComputer {
    public static func wahl(_ m: Muehle, staerke: MuehleStaerke) -> MuehleZug? {
        wahl(m, tiefe: m.setzphase ? staerke.setzTiefe : staerke.zugTiefe, fehler: staerke.fehler)
    }

    public static func wahl(_ m: Muehle, tiefe: Int = 3, fehler: Double = 0) -> MuehleZug? {
        let z = m.zuege()
        guard !z.isEmpty else { return nil }
        if z.count == 1 { return z[0] }
        let ich = m.dran
        var bewertet: [(MuehleZug, Int)] = []
        var alpha = -1_000_000
        for zug in sortiert(z, m).shuffled() {
            var k = m; k.spiele(zug)
            let w = suche(k, zug.istEntfernen ? tiefe : tiefe - 1, fehler > 0 ? -1_000_000 : alpha - 3, 1_000_000, ich)
            bewertet.append((zug, w))
            if fehler == 0 { alpha = max(alpha, w) }
        }
        bewertet.sort { $0.1 > $1.1 }
        if fehler > 0, bewertet.count > 2, Double.random(in: 0..<1) < fehler {
            return bewertet[0..<max(2, bewertet.count / 2)].randomElement()!.0
        }
        let top = bewertet[0].1
        let toleranz = abs(top) > 9000 ? 0 : 2     // Matt-Abstände nie verwischen
        return bewertet.filter { $0.1 >= top - toleranz }.randomElement()!.0
    }

    /// Zuerst Züge, die eine Mühle schließen oder eine gegnerische blockieren.
    private static func sortiert(_ z: [MuehleZug], _ m: Muehle) -> [MuehleZug] {
        func punkte(_ zug: MuehleZug) -> Int {
            switch zug {
            case .entferne(let p): return m.inMuehle(p) ? 1 : 3
            case .setze(let p), .ziehe(_, let p):
                var k = m; k.spiele(zug)
                if k.mussEntfernen { return 10 }
                let gegnerMuehle = Muehle.muehlen.contains { l in l.contains(p) && l.filter { m.brett[$0] == m.gegner }.count == 2 }
                return gegnerMuehle ? 5 : 0
            }
        }
        return z.map { ($0, punkte($0)) }.sorted { $0.1 > $1.1 }.map(\.0)
    }

    private static func suche(_ m: Muehle, _ tiefe: Int, _ alpha: Int, _ beta: Int, _ ich: Int) -> Int {
        if let s = m.sieger { return s == ich ? 10_000 + tiefe : -10_000 - tiefe }
        if m.remis { return 0 }
        if tiefe <= 0 { return bewerte(m, ich) }
        let maximiert = m.dran == ich
        var a = alpha, b = beta
        var wert = maximiert ? Int.min : Int.max
        for zug in sortiert(m.zuege(), m) {
            var k = m; k.spiele(zug)
            let w = suche(k, zug.istEntfernen ? tiefe : tiefe - 1, a, b, ich)
            if maximiert { wert = max(wert, w); a = max(a, w) } else { wert = min(wert, w); b = min(b, w) }
            if b <= a { break }
        }
        return wert
    }

    static func bewerte(_ m: Muehle, _ ich: Int) -> Int {
        let du = 3 - ich
        var w = (m.gesamt(ich) - m.gesamt(du)) * 40
        func anzahlMuehlen(_ s: Int) -> Int { Muehle.muehlen.filter { $0.allSatisfy { m.brett[$0] == s } }.count }
        w += (anzahlMuehlen(ich) - anzahlMuehlen(du)) * 8
        func beweglich(_ s: Int) -> Int { (0..<24).filter { m.brett[$0] == s }.reduce(0) { $0 + Muehle.nachbarn[$1].filter { m.brett[$0] == 0 }.count } }
        func blockiert(_ s: Int) -> Int { (0..<24).filter { m.brett[$0] == s && Muehle.nachbarn[$0].allSatisfy { m.brett[$0] != 0 } }.count }
        // Drohungen: zwei Steine einer Mühle mit freiem dritten Punkt; Zwickmühle = zwei solche Drohungen zugleich
        func drohungen(_ s: Int) -> Int { Muehle.muehlen.filter { l in l.filter { m.brett[$0] == s }.count == 2 && l.contains { m.brett[$0] == 0 } }.count }
        // Knotenpunkte mit vier Nachbarn sind wertvoller (Mitten der Ringe)
        func knoten(_ s: Int) -> Int { (0..<24).filter { m.brett[$0] == s && Muehle.nachbarn[$0].count == 4 }.count }
        let zugphase = m.vorrat[ich] == 0 && m.vorrat[du] == 0
        w += (beweglich(ich) - beweglich(du)) * (zugphase ? 3 : 2)
        w += (blockiert(du) - blockiert(ich)) * (zugphase ? 12 : 5)
        w += (drohungen(ich) - drohungen(du)) * 12
        w += (knoten(ich) - knoten(du)) * 3
        return w
    }
}

extension MuehleZug {
    var istEntfernen: Bool { if case .entferne = self { true } else { false } }
}
