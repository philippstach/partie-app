// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Klappbrett (Shut the Box): Zahlen 1–9, Würfelsumme durch Zuklappen offener Zahlen abbauen.
public struct Klappbrett: Equatable, Sendable, Codable {
    public static let zahlen = Array(1...9)
    public private(set) var offen: Set<Int> = Set(Klappbrett.zahlen)
    public private(set) var wurf: [Int] = []

    public init() {}

    /// Mit einem Würfel, sobald 7, 8 und 9 zu sind.
    public var einWuerfel: Bool { !offen.contains(7) && !offen.contains(8) && !offen.contains(9) }
    public var summe: Int { wurf.reduce(0, +) }
    public var punkte: Int { offen.reduce(0, +) }
    public var geschafft: Bool { offen.isEmpty }

    /// Alle Zahlenmengen aus `offen`, die genau `summe` ergeben.
    public static func kombinationen(summe: Int, offen: Set<Int>) -> [[Int]] {
        let z = offen.sorted()
        var erg: [[Int]] = []
        func suche(_ i: Int, _ rest: Int, _ aktuell: [Int]) {
            if rest == 0 { erg.append(aktuell); return }
            guard i < z.count, z[i] <= rest else { return }
            suche(i + 1, rest - z[i], aktuell + [z[i]])
            suche(i + 1, rest, aktuell)
        }
        suche(0, summe, [])
        return erg
    }

    public var moeglicheZuege: [[Int]] { Klappbrett.kombinationen(summe: summe, offen: offen) }
    public var zugMoeglich: Bool { !wurf.isEmpty && !moeglicheZuege.isEmpty }

    /// Würfelt (Anzahl nach Regel); gibt zurück, ob ein Zug möglich ist.
    @discardableResult
    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        let n = einWuerfel ? 1 : 2
        wurf = (0..<n).map { _ in Int.random(in: 1...6, using: &g) }
        return zugMoeglich
    }

    /// Für Tests und echte Würfel: Augen vorgeben.
    public mutating func setzeWurf(_ augen: [Int]) { wurf = augen }

    /// Klappt die gewählten Zahlen zu, wenn sie genau die Würfelsumme ergeben und offen sind.
    @discardableResult
    public mutating func klappen(_ gewaehlt: [Int]) -> Bool {
        guard !wurf.isEmpty, Set(gewaehlt).count == gewaehlt.count, !gewaehlt.isEmpty,
              gewaehlt.allSatisfy({ offen.contains($0) }), gewaehlt.reduce(0, +) == summe else { return false }
        gewaehlt.forEach { offen.remove($0) }
        wurf = []
        return true
    }
}

/// Rangfolge: wenigste Restpunkte gewinnt; gleiche Punkte teilen den Platz.
public func klappbrettRangfolge(punkte: [Int]) -> [Int] {
    punkte.map { p in punkte.filter { $0 < p }.count + 1 }
}

public enum KlappbrettComputer {
    /// Würfelsummen mit Wahrscheinlichkeit (zwei Würfel, in 36stel).
    private static let zweiWuerfel: [(summe: Int, p: Double)] = (2...12).map { s in (s, Double((1...6).filter { (1...6).contains(s - $0) }.count) / 36) }
    private static let einWuerfel: [(summe: Int, p: Double)] = (1...6).map { ($0, 1.0 / 6) }

    private static func maske(_ o: Set<Int>) -> Int { o.reduce(0) { $0 | (1 << ($1 - 1)) } }
    nonisolated(unsafe) private static var cache: [Int: Double] = [:]

    /// Erwartete Restpunkte am Rundenende, wenn man mit den offenen Zahlen optimal weiterspielt.
    public static func erwartung(offen: Set<Int>) -> Double {
        if offen.isEmpty { return 0 }
        let m = maske(offen)
        if let v = cache[m] { return v }
        let ein = !offen.contains(7) && !offen.contains(8) && !offen.contains(9)
        let punkte = Double(offen.reduce(0, +))
        var e = 0.0
        for (s, p) in (ein ? einWuerfel : zweiWuerfel) {
            let k = Klappbrett.kombinationen(summe: s, offen: offen)
            e += p * (k.map { erwartung(offen: offen.subtracting($0)) }.min() ?? punkte)
        }
        cache[m] = e
        return e
    }

    /// `stufe` 1 leicht (zufällige Kombination), 2 mittel (hohe Zahlen zuerst), 3 schwer (kleinste erwartete Restpunkte).
    public static func zug(_ b: Klappbrett, stufe: Int) -> [Int]? {
        let k = b.moeglicheZuege
        guard !k.isEmpty else { return nil }
        switch stufe {
        case ...1: return k.randomElement()
        case 2: return k.max { ($0.max() ?? 0, $0.count) < ($1.max() ?? 0, $1.count) }
        default: return k.min { erwartung(offen: b.offen.subtracting($0)) < erwartung(offen: b.offen.subtracting($1)) }
        }
    }
}
