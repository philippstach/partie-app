// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct Stein: Hashable, Sendable, Codable {
    public var a: Int, b: Int          // Augenzahlen 0…6 (a links, b rechts in der Kette)
    public init(_ a: Int, _ b: Int) { self.a = a; self.b = b }
    public var augen: Int { a + b }
    public var istPasch: Bool { a == b }
    public var gedreht: Stein { Stein(b, a) }
}

public enum Seite: Sendable { case links, rechts }

/// Domino (Block-Domino mit Ziehen): 28 Steine, jeder legt passend an eines der beiden Kettenenden. Wer keinen passenden Stein hat,
/// zieht aus dem Vorrat; ist er leer, muss er passen. Wer zuerst alle Steine los ist, gewinnt – sitzt das Spiel fest, gewinnt die kleinste Augensumme.
public struct Domino: Equatable, Sendable, Codable {
    public private(set) var haende: [[Stein]]
    public private(set) var vorrat: [Stein]
    public private(set) var kette: [Stein] = []
    public private(set) var amZug: Int
    public private(set) var sieger: Int?
    public private(set) var blockiert = false
    private var passenInFolge = 0
    public let spieler: Int

    public let hoechstAugen: Int

    /// `hoechstAugen`: 6 = Doppel-Sechs (28 Steine), 9 = Doppel-Neun (55 Steine, z. B. Dominó Cubano). `handgroesse`: Standard 7 bei zwei, sonst 5.
    public init<G: RandomNumberGenerator>(spieler: Int, hoechstAugen: Int = 6, handgroesse: Int? = nil, mit g: inout G) {
        self.spieler = max(2, min(4, spieler))
        self.hoechstAugen = hoechstAugen
        var alle = (0...hoechstAugen).flatMap { a in (a...hoechstAugen).map { Stein(a, $0) } }
        alle.shuffle(using: &g)
        let n = handgroesse ?? (self.spieler == 2 ? 7 : 5)
        haende = (0..<self.spieler).map { Array(alle[($0 * n)..<($0 * n + n)]) }
        vorrat = Array(alle[(self.spieler * n)...])
        // Beginnt, wer den höchsten Pasch hat, sonst den schwersten Stein
        var best = 0; var wert = -1
        for (i, h) in haende.enumerated() { for s in h { let w = (s.istPasch ? 100 : 0) + s.augen; if w > wert { wert = w; best = i } } }
        amZug = best
    }

    /// Feste Verteilung (Tests, Wiederaufnahme).
    public init(haende: [[Stein]], vorrat: [Stein] = [], kette: [Stein] = [], amZug: Int = 0, hoechstAugen: Int = 6) {
        self.haende = haende; self.vorrat = vorrat; self.kette = kette; self.amZug = amZug
        spieler = haende.count; self.hoechstAugen = hoechstAugen
    }

    public var links: Int? { kette.first?.a }
    public var rechts: Int? { kette.last?.b }
    public var steinGesamt: Int { haende.reduce(0) { $0 + $1.count } + vorrat.count + kette.count }

    public func passt(_ s: Stein, an seite: Seite) -> Bool {
        guard let l = links, let r = rechts else { return true }
        let e = seite == .links ? l : r
        return s.a == e || s.b == e
    }

    public func zuege(_ spieler: Int) -> [(index: Int, seite: Seite)] {
        var z: [(Int, Seite)] = []
        for (i, s) in haende[spieler].enumerated() {
            if kette.isEmpty { z.append((i, .rechts)); continue }
            if passt(s, an: .links) { z.append((i, .links)) }
            if passt(s, an: .rechts) { z.append((i, .rechts)) }
        }
        return z
    }

    @discardableResult
    public mutating func lege(_ index: Int, seite: Seite) -> Bool {
        guard sieger == nil, haende[amZug].indices.contains(index) else { return false }
        var s = haende[amZug][index]
        if !kette.isEmpty {
            guard passt(s, an: seite) else { return false }
            if seite == .rechts { if s.a != rechts { s = s.gedreht } } else { if s.b != links { s = s.gedreht } }
        }
        haende[amZug].remove(at: index)
        if seite == .links { kette.insert(s, at: 0) } else { kette.append(s) }
        passenInFolge = 0
        if haende[amZug].isEmpty { sieger = amZug; return true }
        amZug = (amZug + 1) % spieler
        return true
    }

    public var mussZiehen: Bool { zuege(amZug).isEmpty && !vorrat.isEmpty }
    public var mussPassen: Bool { zuege(amZug).isEmpty && vorrat.isEmpty }

    public mutating func ziehe() {
        guard sieger == nil, mussZiehen else { return }
        haende[amZug].append(vorrat.removeLast())
    }

    public mutating func passe() {
        guard sieger == nil, mussPassen else { return }
        passenInFolge += 1
        if passenInFolge >= spieler {
            blockiert = true
            let summen = haende.map { $0.reduce(0) { $0 + $1.augen } }
            sieger = summen.firstIndex(of: summen.min()!)
        } else { amZug = (amZug + 1) % spieler }
    }

    /// Augensumme der Hand.
    public func summe(_ s: Int) -> Int { haende[s].reduce(0) { $0 + $1.augen } }

    /// Ein Schritt des Computers: legt den schwersten passenden Stein (Pasch bevorzugt), zieht oder passt.
    public mutating func computerSchritt<G: RandomNumberGenerator>(fehler: Double, mit g: inout G) {
        guard sieger == nil else { return }
        let z = zuege(amZug)
        if !z.isEmpty, fehler > 0, Double.random(in: 0..<1, using: &g) < fehler, let zufall = z.randomElement(using: &g) { lege(zufall.index, seite: zufall.seite); return }
        computerSchritt()
    }

    public mutating func computerSchritt() {
        guard sieger == nil else { return }
        let z = zuege(amZug)
        if let best = z.max(by: { bewerte($0.index, $0.seite) < bewerte($1.index, $1.seite) }) { lege(best.index, seite: best.seite) }
        else if mussZiehen { ziehe() } else { passe() }
    }

    /// Einfachster Computer (nur schwerster Stein zuerst); dient als Vergleich für die Tests.
    public mutating func einfacherSchritt() {
        guard sieger == nil else { return }
        let z = zuege(amZug)
        if let best = z.max(by: { w(haende[amZug][$0.index]) < w(haende[amZug][$1.index]) }) { lege(best.index, seite: best.seite) }
        else if mussZiehen { ziehe() } else { passe() }
    }

    /// Zugwert: schwere Steine loswerden, danach offene Enden bevorzugen, die man selbst noch bedienen kann, der Gegner aber kaum
    /// (Augenzahl schon oft ausgespielt oder auf der eigenen Hand).
    func bewerte(_ index: Int, _ seite: Seite) -> Double {
        let stein = haende[amZug][index]
        var neuLinks = links, neuRechts = rechts
        if kette.isEmpty { neuLinks = stein.a; neuRechts = stein.b }
        else if seite == .links { neuLinks = stein.a == links ? stein.b : stein.a }
        else { neuRechts = stein.a == rechts ? stein.b : stein.a }
        let rest = haende[amZug].enumerated().filter { $0.offset != index }.map { $0.element }
        var wert = Double(w(stein)) * 0.6
        for ende in [neuLinks, neuRechts].compactMap({ $0 }) {
            let eigene = rest.filter { $0.a == ende || $0.b == ende }.count
            let sichtbar = kette.filter { $0.a == ende || $0.b == ende }.count + (stein.a == ende || stein.b == ende ? 1 : 0) + eigene
            let gesamt = hoechstAugen + 2            // so viele Steine tragen jede Zahl
            wert += Double(eigene) * 3
            wert += Double(max(0, sichtbar - (gesamt - 3))) * 1.5     // Zahl fast ausgespielt: Gegner kommt kaum weiter
        }
        return wert
    }
    private func w(_ s: Stein) -> Int { (s.istPasch ? 20 : 0) + s.augen }
}
