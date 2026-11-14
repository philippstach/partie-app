// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Stufenstapel: Jeder hat einen Vorrat, den er als Erster loswerden will. Karten 1…10 werden der Reihe nach auf vier gemeinsame
/// Bau-Stapel gelegt; ein Stapel ist bei 10 voll und wird abgeräumt. Der Stern (Wert 0) ersetzt jede Zahl.
/// Eigene Regeln: Vorrat 15 Karten, 5 Handkarten, drei Ablagen je Spieler; den Zug beendet man mit dem Ablegen einer Handkarte.
public struct Stufenstapel: Equatable, Sendable, Codable {
    public static let stern = 0
    public static let hoechste = 10
    public static let vorratGroesse = 15
    public static let handGroesse = 5
    public static let ablagen = 3

    public enum Quelle: Equatable, Sendable { case hand(Int), vorrat, ablage(Int) }

    public private(set) var zieh: [Int]
    private var baukarten: [[Int]] = [[], [], [], []]
    /// Zahl der gelegten Karten je Stapel = zuletzt gelegter Wert (Sterne zählen als die Zahl, die sie ersetzen).
    public var bau: [Int] { baukarten.map(\.count) }
    public private(set) var abgeraeumt: [Int] = []
    public private(set) var vorrat: [[Int]]
    public private(set) var hand: [[Int]]
    public private(set) var ablage: [[[Int]]]
    public private(set) var amZug = 0
    public private(set) var gewinner: Int?
    public let spieler: Int

    public static func satz() -> [Int] {
        var k: [Int] = []
        for w in 1...10 { k += Array(repeating: w, count: 10) }
        k += Array(repeating: 0, count: 12)
        return k
    }

    public init<G: RandomNumberGenerator>(spieler: Int, mit g: inout G) {
        self.spieler = max(2, min(4, spieler))
        var d = Stufenstapel.satz(); d.shuffle(using: &g)
        vorrat = []; hand = Array(repeating: [], count: self.spieler); ablage = Array(repeating: Array(repeating: [], count: Stufenstapel.ablagen), count: self.spieler)
        for _ in 0..<self.spieler { vorrat.append(Array(d.suffix(Stufenstapel.vorratGroesse))); d.removeLast(Stufenstapel.vorratGroesse) }
        zieh = d
        fuelleHand(mit: &g)
    }

    public var kartenGesamt: Int { zieh.count + abgeraeumt.count + baukarten.joined().count + vorrat.reduce(0) { $0 + $1.count } + hand.reduce(0) { $0 + $1.count } + ablage.joined().joined().count }

    public func kannBauen(_ wert: Int, auf b: Int) -> Bool { bau[b] < Stufenstapel.hoechste && (wert == Stufenstapel.stern || wert == bau[b] + 1) }

    public func wert(_ q: Quelle) -> Int? {
        switch q {
        case .hand(let i): return hand[amZug].indices.contains(i) ? hand[amZug][i] : nil
        case .vorrat: return vorrat[amZug].last
        case .ablage(let a): return ablage[amZug][a].last
        }
    }

    private mutating func fuelleHand<G: RandomNumberGenerator>(mit g: inout G) {
        while hand[amZug].count < Stufenstapel.handGroesse {
            if zieh.isEmpty {
                if abgeraeumt.isEmpty {
                    // Notvorrat: alle Karten unter den obersten Ablagekarten werden neu gemischt
                    for p in 0..<spieler { for a in 0..<Stufenstapel.ablagen where ablage[p][a].count > 1 { zieh += ablage[p][a].dropLast(); ablage[p][a] = [ablage[p][a].last!] } }
                } else { zieh = abgeraeumt; abgeraeumt = [] }
                guard !zieh.isEmpty else { return }
                zieh.shuffle(using: &g)
            }
            hand[amZug].append(zieh.removeLast())
        }
    }

    private mutating func entferne(_ q: Quelle) -> Int {
        switch q {
        case .hand(let i): return hand[amZug].remove(at: i)
        case .vorrat: return vorrat[amZug].removeLast()
        case .ablage(let a): return ablage[amZug][a].removeLast()
        }
    }

    /// Spielt eine Karte auf einen Bau-Stapel. Leere Hand wird sofort mit fünf Karten gefüllt.
    @discardableResult
    public mutating func baue<G: RandomNumberGenerator>(_ q: Quelle, auf b: Int, mit g: inout G) -> Bool {
        guard gewinner == nil, bau.indices.contains(b), let w0 = wert(q), kannBauen(w0, auf: b) else { return false }
        let w = entferne(q)
        baukarten[b].append(w)
        if baukarten[b].count == Stufenstapel.hoechste { abgeraeumt += baukarten[b]; baukarten[b] = [] }
        if vorrat[amZug].isEmpty { gewinner = amZug; return true }
        if hand[amZug].isEmpty { fuelleHand(mit: &g) }
        return true
    }

    /// Legt eine Handkarte auf eine eigene Ablage und beendet den Zug.
    @discardableResult
    public mutating func lege<G: RandomNumberGenerator>(handKarte i: Int, auf a: Int, mit g: inout G) -> Bool {
        guard gewinner == nil, hand[amZug].indices.contains(i), ablage[amZug].indices.contains(a) else { return false }
        ablage[amZug][a].append(hand[amZug].remove(at: i))
        amZug = (amZug + 1) % spieler
        fuelleHand(mit: &g)
        return true
    }

    // MARK: Computer

    /// Wie `computerSchritt`; mit Wahrscheinlichkeit `fehler` übersieht er mögliche Spielzüge und legt nur ab.
    @discardableResult
    public mutating func computerSchritt<G: RandomNumberGenerator>(fehler: Double, mit g: inout G) -> Bool {
        if gewinner == nil, !hand[amZug].isEmpty, fehler > 0, Double.random(in: 0..<1, using: &g) < fehler {
            lege(handKarte: Int.random(in: 0..<hand[amZug].count, using: &g), auf: Int.random(in: 0..<Stufenstapel.ablagen, using: &g), mit: &g)
            return true
        }
        return computerSchritt(mit: &g)
    }

    /// Ein Schritt des Computers (eine Aktion). Gibt `true` zurück, wenn der Zug damit zu Ende ist.
    @discardableResult
    public mutating func computerSchritt<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        guard gewinner == nil else { return true }
        let ich = amZug
        let quellen: [Quelle] = [.vorrat] + hand[ich].indices.map { Quelle.hand($0) } + (0..<Stufenstapel.ablagen).map { Quelle.ablage($0) }
        // 1. Vorratskarte spielen
        if let v = vorrat[ich].last, let b = bau.indices.first(where: { kannBauen(v, auf: $0) }) { baue(.vorrat, auf: b, mit: &g); return false }
        // 2. Dem Vorrat den Weg bereiten
        if let v = vorrat[ich].last, v > 1 {
            for q in quellen.dropFirst() { if let w = wert(q) {
                for b in bau.indices where kannBauen(w, auf: b) && bau[b] + 1 < v && (w == bau[b] + 1 || w == Stufenstapel.stern && bau[b] + 2 == v) {
                    baue(q, auf: b, mit: &g); return false
                }
            } }
        }
        // 3. Normale Karten bauen (Hand vor Ablage), Sterne nur wenn sonst nichts geht
        for q in quellen.dropFirst() { if let w = wert(q), w != Stufenstapel.stern, let b = bau.indices.first(where: { kannBauen(w, auf: $0) }) { baue(q, auf: b, mit: &g); return false } }
        if !hand[ich].isEmpty, hand[ich].count == 1 || hand[ich].allSatisfy({ $0 == Stufenstapel.stern }),
           let i = hand[ich].indices.first(where: { hand[ich][$0] == Stufenstapel.stern }), let b = bau.indices.first(where: { kannBauen(0, auf: $0) }) { baue(.hand(i), auf: b, mit: &g); return false }
        // 4. Ablegen: Karte auf eine Ablage, die oben eine größere Karte hat; sonst auf die leerste
        guard !hand[ich].isEmpty else { return true }
        let i = hand[ich].indices.min { (hand[ich][$0] == 0 ? 99 : hand[ich][$0]) < (hand[ich][$1] == 0 ? 99 : hand[ich][$1]) }!
        let w = hand[ich][i]
        let a = (0..<Stufenstapel.ablagen).min { a1, a2 in
            func schlecht(_ a: Int) -> Int {
                guard let o = ablage[ich][a].last else { return 1 }
                return o >= w && w != 0 ? 0 : 5 + ablage[ich][a].count
            }
            return schlecht(a1) < schlecht(a2)
        }!
        lege(handKarte: i, auf: a, mit: &g)
        return true
    }
}

/// Vorschlag für den Menschen (F4 Tipp): dieselbe Reihenfolge wie der Computer, ohne zu ziehen.
public enum StufenVorschlag: Equatable, Sendable {
    case bauen(Stufenstapel.Quelle, auf: Int)
    case ablegen(handKarte: Int, auf: Int)
}

public extension Stufenstapel {
    /// Vorrat zuerst, dann dem Vorrat den Weg bereiten, dann normale Karten (Hand vor Ablage); geht nichts, die Handkarte ablegen,
    /// die am besten auf eine Ablage passt (gleicher oder um eins kleinerer Wert), sonst auf die kürzeste Ablage.
    func vorschlag() -> StufenVorschlag? {
        guard gewinner == nil else { return nil }
        let ich = amZug
        let quellen: [Quelle] = [.vorrat] + hand[ich].indices.map { Quelle.hand($0) } + (0..<Stufenstapel.ablagen).map { Quelle.ablage($0) }
        if let v = vorrat[ich].last, let b = bau.indices.first(where: { kannBauen(v, auf: $0) }) { return .bauen(.vorrat, auf: b) }
        if let v = vorrat[ich].last, v > 1 {
            for q in quellen.dropFirst() { if let w = wert(q) {
                for b in bau.indices where kannBauen(w, auf: b) && bau[b] + 1 < v && (w == bau[b] + 1 || w == Stufenstapel.stern && bau[b] + 2 == v) {
                    return .bauen(q, auf: b)
                }
            } }
        }
        for q in quellen.dropFirst() { if let w = wert(q), w != Stufenstapel.stern, let b = bau.indices.first(where: { kannBauen(w, auf: $0) }) { return .bauen(q, auf: b) } }
        guard !hand[ich].isEmpty else { return nil }
        // Ablegen: Karte, die auf eine Ablage mit gleichem oder nächsthöherem Wert passt (Stapel bleibt sortiert), sonst höchste Karte auf die kürzeste Ablage
        for (i, w) in hand[ich].enumerated() where w != Stufenstapel.stern {
            if let a = (0..<Stufenstapel.ablagen).first(where: { ablage[ich][$0].last == w || ablage[ich][$0].last == w + 1 }) { return .ablegen(handKarte: i, auf: a) }
        }
        let i = hand[ich].indices.max { hand[ich][$0] < hand[ich][$1] } ?? 0
        let a = (0..<Stufenstapel.ablagen).min { ablage[ich][$0].count < ablage[ich][$1].count } ?? 0
        return .ablegen(handKarte: i, auf: a)
    }
}
