// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct SKarte: Hashable, Sendable, Codable {
    public let farbe: Int   // 0 Kreuz, 1 Pik, 2 Herz, 3 Karo
    public let wert: Int    // 7…10, 11 Bube, 12 Dame, 13 König, 14 Ass
    public init(_ f: Int, _ w: Int) { farbe = f; wert = w }
    public static let alle: [SKarte] = (0..<4).flatMap { f in (7...14).map { SKarte(f, $0) } }
    public var augen: Int { wert == 14 ? 11 : (wert >= 11 ? 10 : wert) }
    public var symbol: String { ["♣", "♠", "♥", "♦"][farbe] }
    public var name: String { ["7", "8", "9", "10", "B", "D", "K", "A"][wert - 7] }
}

/// Summe einer Hand; Asse zählen 11, bei Überkauf 1.
public func siebzehnSumme(_ hand: [SKarte]) -> Int {
    var s = hand.reduce(0) { $0 + $1.augen }
    var asse = hand.filter { $0.wert == 14 }.count
    while s > 21, asse > 0 { s -= 10; asse -= 1 }
    return s
}

public func istBlackjack(_ hand: [SKarte]) -> Bool { hand.count == 2 && siebzehnSumme(hand) == 21 }

public enum SiebzehnAusgang: Equatable, Sendable, Codable { case gewinn, blackjack, verlust, unentschieden }

/// Siebzehn und Vier gegen die Bank: Jeder Spieler setzt `einsatz`, Bank zieht bis mindestens 17.
public struct Siebzehn: Equatable, Sendable, Codable {
    public static let einsatz = 10                    // Standard-Einsatz je Hand
    /// 1.0 (M5): wählbare Einsätze je Hand.
    public static let einsatzStufen = [10, 25, 50, 100]
    public private(set) var chips: [Int]
    public private(set) var spieler: [[SKarte]] = []
    public private(set) var bank: [SKarte] = []
    public private(set) var stapel: [SKarte] = []
    public private(set) var dran = 0
    public private(set) var bankDran = false
    public private(set) var vorbei = false
    public private(set) var ausgaenge: [SiebzehnAusgang] = []
    /// 1.0 (M5): Einsatz je Hand (wählbar, wirkt ab der nächsten Austeilung) und wer in dieser Hand verdoppelt hat.
    public private(set) var einsatzJeHand: Int = Siebzehn.einsatz
    public private(set) var verdoppelt: [Bool] = []
    /// Blatt 22 (EB2): wie viele Hände abgerechnet wurden und der größte Gewinn einer Hand (in Chips). Optional: Stände von vor dem Update
    /// haben beides nicht (nil), dann zeigt die Ergebnisseite die Zeilen nicht.
    public private(set) var haendeGespielt: Int?
    public private(set) var groessterGewinn: Int?

    private enum CodingKeys: String, CodingKey {
        case chips, spieler, bank, stapel, dran, bankDran, vorbei, ausgaenge, einsatzJeHand, verdoppelt, haendeGespielt, groessterGewinn
    }

    /// 1.0 (M5): alte gespeicherte Stände (Einsatz fest 10, kein Verdoppeln) bleiben lesbar.
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        chips = try c.decode([Int].self, forKey: .chips)
        spieler = try c.decode([[SKarte]].self, forKey: .spieler)
        bank = try c.decode([SKarte].self, forKey: .bank)
        stapel = try c.decode([SKarte].self, forKey: .stapel)
        dran = try c.decode(Int.self, forKey: .dran)
        bankDran = try c.decode(Bool.self, forKey: .bankDran)
        vorbei = try c.decode(Bool.self, forKey: .vorbei)
        ausgaenge = try c.decode([SiebzehnAusgang].self, forKey: .ausgaenge)
        einsatzJeHand = try c.decodeIfPresent(Int.self, forKey: .einsatzJeHand) ?? Siebzehn.einsatz
        verdoppelt = try c.decodeIfPresent([Bool].self, forKey: .verdoppelt) ?? Array(repeating: false, count: spieler.count)
        haendeGespielt = try c.decodeIfPresent(Int.self, forKey: .haendeGespielt)
        groessterGewinn = try c.decodeIfPresent(Int.self, forKey: .groessterGewinn)
    }

    public init(spieler n: Int, chips: Int = 100, einsatz: Int = Siebzehn.einsatz) {
        self.chips = Array(repeating: chips, count: n); spieler = Array(repeating: [], count: n)
        einsatzJeHand = einsatz; verdoppelt = Array(repeating: false, count: n)
        haendeGespielt = 0; groessterGewinn = 0
    }

    /// Mit gleich ausgeteilter erster Hand.
    public init<G: RandomNumberGenerator>(spieler n: Int, chips: Int = 100, einsatz: Int = Siebzehn.einsatz, mit g: inout G) { self.init(spieler: n, chips: chips, einsatz: einsatz); austeilen(mit: &g) }

    /// Allein gespielt: verloren, wenn die Chips nicht mehr für einen Einsatz reichen (pleite). Sonst zählt der Chip-Stand als Punkte.
    public static func alleinVerloren(chips: Int, einsatz: Int = Siebzehn.einsatz) -> Bool { chips < einsatz }

    public var aktive: [Int] { chips.indices.filter { chips[$0] >= einsatzJeHand } }

    /// 1.0 (M5): Einsatz für die nächste Hand setzen (nur zwischen den Händen oder vor dem ersten Zug).
    public mutating func setzeEinsatz(_ e: Int) {
        guard Siebzehn.einsatzStufen.contains(e), vorbei || spieler.allSatisfy({ $0.count <= 2 }) else { return }
        einsatzJeHand = e
    }

    /// 1.0 (M5): Einsätze, mit denen es weitergehen kann (allein: der Chip-Stand reicht; zu mehreren: mindestens zwei Spieler können mithalten).
    public var moeglicheEinsaetze: [Int] {
        let noetig = min(2, chips.count)
        return Siebzehn.einsatzStufen.filter { e in chips.filter { $0 >= e }.count >= noetig }
    }

    /// 1.0 (M5): Einsatz, der für Spieler `i` in dieser Hand gilt (doppelt nach Verdoppeln).
    public func einsatzFuer(_ i: Int) -> Int { einsatzJeHand * (i < verdoppelt.count && verdoppelt[i] ? 2 : 1) }

    /// 1.0 (M5): Verdoppeln ist nur mit genau den ersten zwei Karten erlaubt, wenn der Chip-Stand für den doppelten Einsatz reicht.
    public var kannVerdoppeln: Bool {
        !bankDran && !vorbei && dran < spieler.count && spieler[dran].count == 2 && !istBlackjack(spieler[dran]) && chips[dran] >= 2 * einsatzJeHand
    }

    /// 1.0 (M5): Verdoppeln: doppelter Einsatz, genau eine Karte, dann ist der Spieler fertig.
    public mutating func verdoppeln() {
        guard kannVerdoppeln else { return }
        verdoppelt[dran] = true
        spieler[dran].append(stapel.removeLast())
        dran += 1; ueberspringeFertige()
    }

    /// RT-002: Grundstrategie fürs Verdoppeln, gerechnet für das 32-Karten-Blatt (7 bis Ass; kleinste Zweikartenhand ohne Ass ist 14).
    /// Eine Karte kann dort nur eine Hand mit genau einem Ass nicht überkaufen: Ass + 7 (18) gegen eine Bankkarte bis 7,
    /// Ass + 8 (19) gegen bis 8, Ass + 9 (20) gegen bis 9. Alles andere: nicht verdoppeln.
    public static func computerVerdoppelt(hand: [SKarte], bankOffen: Int) -> Bool {
        guard hand.count == 2, hand.filter({ $0.wert == 14 }).count == 1 else { return false }
        let summe = siebzehnSumme(hand)
        guard (18...20).contains(summe) else { return false }
        return bankOffen <= summe - 11
    }

    /// K-011/M-013: Zug eines Computer-Spielers nach der Grundstrategie (dieselbe wie der Tipp): bis 11 immer Karte,
    /// ab 17 halten, dazwischen Karte, wenn die offene Bankkarte 7 oder mehr zeigt.
    public static func computerNimmtKarte(hand: [SKarte], bankOffen: Int) -> Bool {
        let summe = siebzehnSumme(hand)
        if summe <= 11 { return true }
        if summe >= 17 { return false }
        return bankOffen >= 7
    }

    public mutating func austeilen<G: RandomNumberGenerator>(mit g: inout G) {
        stapel = SKarte.alle.shuffled(using: &g)
        spieler = chips.indices.map { chips[$0] >= einsatzJeHand ? [stapel.removeLast(), stapel.removeLast()] : [] }
        bank = [stapel.removeLast(), stapel.removeLast()]
        bankDran = false; vorbei = false; ausgaenge = []; verdoppelt = Array(repeating: false, count: chips.count)
        dran = aktive.first ?? 0
        if istBlackjack(bank) && !aktive.isEmpty { bankZieht(); return }   // T-085: Siebzehn und Vier der Bank: sofort aufdecken und abrechnen
        ueberspringeFertige()
    }

    private mutating func ueberspringeFertige() {
        while dran < spieler.count, spieler[dran].isEmpty || istBlackjack(spieler[dran]) || siebzehnSumme(spieler[dran]) >= 21 { dran += 1 }
        if dran >= spieler.count { bankZieht() }
    }

    public mutating func karte() {
        guard !bankDran, !vorbei, dran < spieler.count else { return }
        spieler[dran].append(stapel.removeLast())
        if siebzehnSumme(spieler[dran]) >= 21 { dran += 1; ueberspringeFertige() }
    }

    public mutating func halten() {
        guard !bankDran, !vorbei else { return }
        dran += 1; ueberspringeFertige()
    }

    private mutating func bankZieht() {
        bankDran = true
        let alleGeplatzt = aktive.allSatisfy { siebzehnSumme(spieler[$0]) > 21 }
        if !alleGeplatzt { while siebzehnSumme(bank) < 17 { bank.append(stapel.removeLast()) } }
        abrechnen()
    }

    private mutating func abrechnen() {
        let b = siebzehnSumme(bank), bBJ = istBlackjack(bank)
        var groesster = 0   // Blatt 22 (EB2): größter Gewinn dieser Hand
        ausgaenge = spieler.indices.map { i in
            guard !spieler[i].isEmpty else { return .unentschieden }
            let s = siebzehnSumme(spieler[i])
            let a: SiebzehnAusgang
            if s > 21 { a = .verlust }
            else if istBlackjack(spieler[i]) { a = bBJ ? .unentschieden : .blackjack }
            else if bBJ { a = .verlust }
            else if b > 21 || s > b { a = .gewinn }
            else if s == b { a = .unentschieden }
            else { a = .verlust }
            let e = einsatzFuer(i)   // 1.0 (M5): wählbarer Einsatz, doppelt nach Verdoppeln
            switch a {
            case .gewinn: chips[i] += e; groesster = max(groesster, e)
            case .blackjack: chips[i] += e * 3 / 2; groesster = max(groesster, e * 3 / 2)
            case .verlust: chips[i] -= e
            case .unentschieden: break
            }
            return a
        }
        if let h = haendeGespielt { haendeGespielt = h + 1 }
        if let g = groessterGewinn { groessterGewinn = max(g, groesster) }
        vorbei = true
    }
}
