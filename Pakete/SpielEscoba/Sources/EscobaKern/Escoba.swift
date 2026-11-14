// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Spanisches 40er-Blatt: 4 Farben, Rang 1–10 (Rang = Zählwert; 8–10 sind Bube, Reiter, König).
public struct EscobaKarte: Equatable, Hashable, Sendable, Codable {
    public let farbe: Int      // 0 = Münzen, 1 = Becher, 2 = Schwerter, 3 = Stäbe
    public let rang: Int       // 1...10
    public init(farbe: Int, rang: Int) { self.farbe = farbe; self.rang = rang }
    public var wert: Int { rang }
    public var istSiebenMuenzen: Bool { farbe == 0 && rang == 7 }
}

/// Escoba (15 machen): Mit einer Handkarte und Tischkarten genau 15 erreichen und alle einsammeln.
/// Fegt man den Tisch leer, gibt es eine „Escoba“. Zwei Spieler, eine Runde.
public struct Escoba: Equatable, Sendable, Codable {
    public static let ziel = 15
    public private(set) var stapel: [EscobaKarte]
    public private(set) var tisch: [EscobaKarte]
    public private(set) var haende: [[EscobaKarte]] = [[], []]
    public private(set) var gewonnen: [[EscobaKarte]] = [[], []]
    public private(set) var escobas = [0, 0]
    public private(set) var amZug = 0
    public private(set) var letzterFaenger: Int?
    public private(set) var vorbei = false

    public init<G: RandomNumberGenerator>(mit g: inout G) {
        var k = (0..<4).flatMap { f in (1...10).map { EscobaKarte(farbe: f, rang: $0) } }
        k.shuffle(using: &g)
        stapel = k; tisch = []
        austeilen()
        tisch = Array(stapel.prefix(4)); stapel.removeFirst(4)
    }

    /// Für Tests: feste Lage.
    public init(stapel: [EscobaKarte], tisch: [EscobaKarte], haende: [[EscobaKarte]], amZug: Int = 0) {
        self.stapel = stapel; self.tisch = tisch; self.haende = haende; self.amZug = amZug
    }

    private mutating func austeilen() {
        for s in 0..<2 { let n = min(3, stapel.count); haende[s] = Array(stapel.prefix(n)); stapel.removeFirst(n) }
    }

    /// Alle Tischkarten-Mengen (Indizes), die mit `karte` genau 15 ergeben.
    public func faenge(_ karte: EscobaKarte) -> [[Int]] {
        let rest = Self.ziel - karte.wert
        guard rest > 0 else { return [] }
        var treffer: [[Int]] = []
        func such(_ i: Int, _ summe: Int, _ wahl: [Int]) {
            if summe == rest, !wahl.isEmpty { treffer.append(wahl); return }
            guard i < tisch.count, summe < rest else { return }
            such(i + 1, summe + tisch[i].wert, wahl + [i])
            such(i + 1, summe, wahl)
        }
        such(0, 0, [])
        return treffer
    }

    /// Spielen: `fang` = Tischindizes (müssen zu `faenge` gehören) oder nil zum Ablegen (nur erlaubt, wenn kein Fang möglich ist).
    @discardableResult
    public mutating func spiele(hand i: Int, fang: [Int]?) -> Bool {
        guard !vorbei, haende[amZug].indices.contains(i) else { return false }
        let karte = haende[amZug][i]
        let moeglich = faenge(karte)
        if let f = fang {
            let key = Set(f)
            guard moeglich.contains(where: { Set($0) == key }) else { return false }
            haende[amZug].remove(at: i)
            gewonnen[amZug].append(karte)
            for idx in key.sorted(by: >) { gewonnen[amZug].append(tisch.remove(at: idx)) }
            letzterFaenger = amZug
            if tisch.isEmpty, !(stapel.isEmpty && haende[0].isEmpty && haende[1].isEmpty) { escobas[amZug] += 1 }
        } else {
            guard moeglich.isEmpty else { return false }
            haende[amZug].remove(at: i)
            tisch.append(karte)
        }
        weiter()
        return true
    }

    private mutating func weiter() {
        if haende[0].isEmpty && haende[1].isEmpty {
            if stapel.isEmpty {
                if let l = letzterFaenger { gewonnen[l].append(contentsOf: tisch); tisch = [] }
                vorbei = true; return
            }
            austeilen()
        }
        amZug = 1 - amZug
        if haende[amZug].isEmpty { amZug = 1 - amZug }
    }

    // MARK: Wertung

    public struct Wertung: Equatable, Sendable {
        public var escobas = 0, siebenMuenzen = false, karten = false, muenzen = false, siebener = false
        public var summe: Int { escobas + (siebenMuenzen ? 1 : 0) + (karten ? 1 : 0) + (muenzen ? 1 : 0) + (siebener ? 1 : 0) }
    }

    /// Punkte: Escobas, Sieben der Münzen, meiste Karten, meiste Münzen, meiste Siebener (bei Gleichstand niemand).
    public func wertung(_ s: Int) -> Wertung {
        var w = Wertung(); let g = gewonnen[s], o = gewonnen[1 - s]
        w.escobas = escobas[s]
        w.siebenMuenzen = g.contains { $0.istSiebenMuenzen }
        w.karten = g.count > o.count
        w.muenzen = g.filter { $0.farbe == 0 }.count > o.filter { $0.farbe == 0 }.count
        w.siebener = g.filter { $0.rang == 7 }.count > o.filter { $0.rang == 7 }.count
        return w
    }

    /// Sieger (0/1) oder nil bei Gleichstand.
    public var sieger: Int? {
        guard vorbei else { return nil }
        let a = wertung(0).summe, b = wertung(1).summe
        return a == b ? nil : (a > b ? 0 : 1)
    }
}

public enum EscobaComputer {
    /// (Handindex, Fang) – Fang nil = ablegen.
    /// `stufe` 1 = leicht (oft zufällig), 2 = mittel, 3 = schwer (vermeidet Escoba-Vorlagen für den Gegner).
    public static func wahl(_ e: Escoba, stufe: Int = 2) -> (Int, [Int]?) {
        let hand = e.haende[e.amZug]
        if stufe <= 1, Int.random(in: 0..<10) < 6 {
            // Leicht: häufig irgendein erlaubter Zug (Einsammeln, wenn möglich)
            let faenge = hand.indices.flatMap { i in e.faenge(hand[i]).map { (i, Optional($0)) } }
            if let z = faenge.randomElement() { return z }
            return (hand.indices.randomElement()!, nil)
        }
        var best: (Int, [Int]?, Double) = (0, nil, -.infinity)
        for (i, k) in hand.enumerated() {
            let f = e.faenge(k)
            if f.isEmpty {
                // Ablegen: möglichst wertlose Karte, die dem Gegner kein 15 anbietet
                var w = -Double(wert(k)) * 0.5
                let tischSumme = e.tisch.reduce(0) { $0 + $1.wert } + k.wert
                if tischSumme <= 15 { w -= 3 }
                if stufe >= 3 {
                    // Nach dem Ablegen darf der Gegner den Tisch nicht mit einer einzigen Karte leerfegen können
                    var danach = e.tisch; danach.append(k)
                    if danach.count <= 4, (1...10).contains(15 - tischSumme) { w -= 12 }
                    if tischSumme == 15 { w -= 20 }
                }
                if w > best.2 { best = (i, nil, w) }
            } else {
                for fang in f {
                    let karten = [k] + fang.map { e.tisch[$0] }
                    var w = 10 + Double(karten.reduce(0) { $0 + wert($1) })
                    if fang.count == e.tisch.count { w += 25 }
                    if stufe >= 3 {
                        let uebrig = e.tisch.enumerated().filter { !fang.contains($0.offset) }.map(\.element.wert)
                        let rest = uebrig.reduce(0, +)
                        if !uebrig.isEmpty, rest <= 10 { w -= 8 }      // würde dem Gegner einen Fang mit 5 bis 10 bieten
                    }
                    if w > best.2 { best = (i, fang, w) }
                }
            }
        }
        return (best.0, best.1)
    }

    private static func wert(_ k: EscobaKarte) -> Int {
        (k.istSiebenMuenzen ? 8 : 0) + (k.rang == 7 ? 3 : 0) + (k.farbe == 0 ? 2 : 0) + 1
    }
}

extension Escoba {
    /// Nur für Tests (feste Wertungslage).
    mutating func setzeGewonnen(_ g: [[EscobaKarte]]) { gewonnen = g; vorbei = true }
}
