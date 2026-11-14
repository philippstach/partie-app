// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Spanisches 40er-Blatt (Ränge 1–7, 10–12; Farben 0 Münzen, 1 Becher, 2 Schwerter, 3 Stäbe).
public struct ChinKarte: Equatable, Hashable, Sendable, Codable {
    public let farbe: Int
    public let rang: Int
    public init(farbe: Int, rang: Int) { self.farbe = farbe; self.rang = rang }
    /// Folgeposition in Reihen: 1…7 → 0…6, 10, 11, 12 → 7, 8, 9 (7 und 10 sind Nachbarn).
    public var folge: Int { rang <= 7 ? rang - 1 : rang - 3 }
    /// Strafpunkte: Bilder 10, sonst Rang.
    public var punkte: Int { rang >= 10 ? 10 : rang }
}

public enum Chinchon {
    /// Alle möglichen Kombinationen (als Indexmengen) einer Hand: Drillinge/Vierlinge und Reihen ab 3 Karten.
    static func kombinationen(_ h: [ChinKarte]) -> [[Int]] {
        var res: [[Int]] = []
        let n = h.count
        // Sätze
        for r in Set(h.map(\.rang)) {
            let idx = (0..<n).filter { h[$0].rang == r }
            if idx.count >= 3 {
                res.append(idx)
                if idx.count == 4 { for skip in 0..<4 { res.append(idx.enumerated().filter { $0.offset != skip }.map(\.element)) } }
            }
        }
        // Reihen
        for f in 0..<4 {
            let karten = (0..<n).filter { h[$0].farbe == f }.sorted { h[$0].folge < h[$1].folge }
            for a in 0..<karten.count {
                var lauf = [karten[a]]
                for b in (a + 1)..<max(karten.count, a + 1) {
                    if h[karten[b]].folge == h[lauf.last!].folge + 1 { lauf.append(karten[b]); if lauf.count >= 3 { res.append(lauf) } } else { break }
                }
            }
        }
        return res
    }

    /// Kleinste Summe der nicht gemeldeten Karten und welche das sind.
    public static func rest(_ h: [ChinKarte]) -> (punkte: Int, offen: [Int]) {
        let komb = kombinationen(h)
        var best = (punkte: h.reduce(0) { $0 + $1.punkte }, offen: Array(h.indices))
        func such(_ start: Int, _ benutzt: Set<Int>) {
            let offen = h.indices.filter { !benutzt.contains($0) }
            let p = offen.reduce(0) { $0 + h[$1].punkte }
            if p < best.punkte { best = (p, offen) }
            for i in start..<komb.count where benutzt.isDisjoint(with: komb[i]) { such(i + 1, benutzt.union(komb[i])) }
        }
        such(0, [])
        return best
    }

    /// Schließen: 8 Karten, eine ablegen; Rest der übrigen 7 höchstens 5 Punkte. Ergebnis: Indizes der erlaubten Ablagekarten.
    public static func schliessKarten(_ h: [ChinKarte]) -> [Int] {
        guard h.count == 8 else { return [] }
        return h.indices.filter { i in var k = h; k.remove(at: i); return rest(k).punkte <= 5 }
    }

    /// Alle 7 Karten bilden eine einzige Reihe gleicher Farbe.
    public static func istChinchon(_ h: [ChinKarte]) -> Bool {
        h.count == 7 && Set(h.map(\.farbe)).count == 1 && Set(h.map(\.folge)).count == 7 && (h.map(\.folge).max()! - h.map(\.folge).min()! == 6)
    }
}

/// Eine Hand Chinchón für zwei Spieler.
public struct ChinchonHand: Sendable, Codable {
    public private(set) var stapel: [ChinKarte]
    public private(set) var ablage: [ChinKarte]
    public private(set) var haende: [[ChinKarte]]
    public private(set) var amZug: Int
    public private(set) var hatGezogen = false
    public private(set) var vorbei = false
    public private(set) var schliesser: Int?
    public private(set) var strafe = [0, 0]
    public private(set) var chinchon = false
    /// Karten, die jeder Spieler aus der Ablage genommen hat (der Gegner sieht sie).
    public private(set) var ablageGenommen: [[ChinKarte]] = [[], []]

    public init<G: RandomNumberGenerator>(beginner: Int, mit g: inout G) {
        var k = (0..<4).flatMap { f in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12].map { ChinKarte(farbe: f, rang: $0) } }
        k.shuffle(using: &g)
        self.init(karten: k, beginner: beginner)
    }
    public init(karten k: [ChinKarte], beginner: Int) {
        haende = [Array(k[0..<7]), Array(k[7..<14])]
        ablage = [k[14]]; stapel = Array(k[15...]); amZug = beginner
    }

    @discardableResult
    public mutating func ziehe(vonAblage: Bool) -> Bool {
        guard !vorbei, !hatGezogen else { return false }
        if vonAblage { let k = ablage.removeLast(); haende[amZug].append(k); ablageGenommen[amZug].append(k) }
        else {
            if stapel.isEmpty { let oben = ablage.removeLast(); stapel = ablage.reversed(); ablage = [oben] }
            guard !stapel.isEmpty else { return false }          // nichts mehr zu ziehen (nur theoretisch)
            haende[amZug].append(stapel.removeFirst())
        }
        hatGezogen = true; return true
    }

    @discardableResult
    public mutating func lege(ab i: Int, schliessen: Bool = false) -> Bool {
        guard !vorbei, hatGezogen, haende[amZug].indices.contains(i) else { return false }
        if schliessen {
            guard Chinchon.schliessKarten(haende[amZug]).contains(i) else { return false }
        }
        let k = haende[amZug].remove(at: i); ablage.append(k); hatGezogen = false
        if schliessen {
            let s = amZug, o = 1 - s
            schliesser = s; vorbei = true
            chinchon = Chinchon.istChinchon(haende[s])
            let eigen = Chinchon.rest(haende[s]).punkte
            strafe[s] = eigen == 0 ? -10 : eigen
            strafe[o] = Chinchon.rest(haende[o]).punkte
        } else { amZug = 1 - amZug }
        return true
    }
}

public enum ChinchonComputer {
    /// `stufe` 1 leicht, 2 mittel, 3 schwer (merkt sich die Aufnahmen des Gegners und gibt ihm nichts Passendes).
    public static func ziehenVonAblage(_ h: ChinchonHand, stufe: Int = 2) -> Bool {
        if stufe <= 1 { return Int.random(in: 0..<10) < 3 }
        let s = h.amZug, mein = h.haende[s]
        guard let oben = h.ablage.last else { return false }
        let vorher = Chinchon.rest(mein).punkte
        let nachher = (mein + [oben]).indices.map { i -> Int in var k = mein + [oben]; k.remove(at: i); return Chinchon.rest(k).punkte }.min()!
        return nachher < vorher
    }
    /// (Ablagekarte, schließen?)
    public static func ablegen(_ h: ChinchonHand, stufe: Int = 2) -> (Int, Bool) {
        let s = h.amZug, k = h.haende[s]
        let erlaubt = Chinchon.schliessKarten(k)
        if stufe <= 1 {
            if let i = erlaubt.first, Bool.random() { return (i, true) }
            return (k.indices.randomElement()!, false)
        }
        if stufe >= 3 {
            let gegnerKarten = h.ablageGenommen[1 - s]
            func gefahr(_ c: ChinKarte) -> Int {
                gegnerKarten.reduce(0) { a, g in a + (g.rang == c.rang ? 3 : 0) + (g.farbe == c.farbe && abs(g.folge - c.folge) <= 2 && g != c ? 2 : 0) }
            }
            if let i = erlaubt.min(by: { Chinchon.rest(without(k, $0)).punkte < Chinchon.rest(without(k, $1)).punkte }) { return (i, true) }
            let i = k.indices.min {
                let a = Chinchon.rest(without(k, $0)).punkte, b = Chinchon.rest(without(k, $1)).punkte
                if a != b { return a < b }
                let ga = gefahr(k[$0]), gb = gefahr(k[$1])
                return ga != gb ? ga < gb : k[$0].punkte > k[$1].punkte
            }!
            return (i, false)
        }
        if let i = erlaubt.min(by: { Chinchon.rest(without(k, $0)).punkte < Chinchon.rest(without(k, $1)).punkte }) { return (i, true) }
        let i = k.indices.min {
            let a = Chinchon.rest(without(k, $0)).punkte, b = Chinchon.rest(without(k, $1)).punkte
            return a != b ? a < b : k[$0].punkte > k[$1].punkte
        }!
        return (i, false)
    }
    private static func without(_ k: [ChinKarte], _ i: Int) -> [ChinKarte] { var r = k; r.remove(at: i); return r }
}

/// Partie: wer 100 Strafpunkte erreicht, scheidet aus. Ein Chinchón (Reihe aus 7) beendet die Partie sofort zugunsten des Schließers.
public struct ChinchonPartie: Sendable, Codable {
    public static let grenze = 100
    public private(set) var strafe = [0, 0]
    public private(set) var hand: ChinchonHand
    public private(set) var gewinner: Int?
    private var naechster = 1

    public init<G: RandomNumberGenerator>(mit g: inout G) { hand = ChinchonHand(beginner: 0, mit: &g) }
    public mutating func zug(_ f: (inout ChinchonHand) -> Void) { f(&hand) }

    public mutating func handAbschliessen<G: RandomNumberGenerator>(mit g: inout G) {
        guard hand.vorbei, gewinner == nil else { return }
        if hand.chinchon, let s = hand.schliesser { gewinner = s; return }
        for s in 0..<2 { strafe[s] = max(0, strafe[s] + hand.strafe[s]) }
        if let v = (0..<2).first(where: { strafe[$0] >= Self.grenze }) { gewinner = 1 - v; return }
        hand = ChinchonHand(beginner: naechster, mit: &g); naechster = 1 - naechster
    }
}
