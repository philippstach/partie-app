// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct MoKarte: Hashable, Sendable, Codable {
    public let farbe: Int
    public let wert: Int    // 7…14
    public init(_ f: Int, _ w: Int) { farbe = f; wert = w }
    public static let alle: [MoKarte] = (0..<4).flatMap { f in (7...14).map { MoKarte(f, $0) } }
    public var symbol: String { ["♣", "♠", "♥", "♦"][farbe] }
    /// Deutscher Rangname, nur für Tests und Protokolle. Die Ansicht bildet den Namen selbst in der Gerätesprache.
    public static func name(_ w: Int) -> String { ["7", "8", "9", "10", "Bube", "Dame", "König", "Ass"][w - 7] }
    public var kurz: String { ["7", "8", "9", "10", "B", "D", "K", "A"][wert - 7] }
}

/// Mogeln (Lügenkarten): Reihum legst du 1–4 Karten verdeckt ab und behauptest, es seien Karten des geforderten Rangs
/// (7, 8, 9, … Ass, dann wieder 7). Der Nächste darf „Gelogen!“ rufen.
public struct Mogeln: Sendable, Codable {
    /// Die Aufdeckung des letzten Zugs ist nur Anzeige und wird nicht gespeichert.
    private enum CodingKeys: String, CodingKey { case haende, haufen, rang, dran, phase, letzter, letzteAnzahl, gewinner, richtigGezweifelt, falschGezweifelt }
    public enum Phase: Equatable, Sendable, Codable { case legen, entscheiden }

    public private(set) var haende: [[MoKarte]]
    public private(set) var haufen: [MoKarte] = []
    public private(set) var rang = 7                 // gefordert in dieser Runde
    public private(set) var dran = 0
    public private(set) var phase: Phase = .legen
    public private(set) var letzter: Int?            // wer zuletzt gelegt hat
    public private(set) var letzteAnzahl = 0
    public private(set) var aufdeckung: (karten: [MoKarte], gelogen: Bool, verlierer: Int)?
    public private(set) var gewinner: Int?
    /// Blatt 22 (EB2): je Person, wie oft sie richtig bzw. falsch gezweifelt hat. Optional: Stände von vor dem Update haben es nicht (nil),
    /// dann zeigt die Ergebnisseite die Zeilen nicht.
    public private(set) var richtigGezweifelt: [Int]?
    public private(set) var falschGezweifelt: [Int]?

    public init<G: RandomNumberGenerator>(spieler: Int, mit g: inout G) {
        var deck = MoKarte.alle.shuffled(using: &g)
        var h = Array(repeating: [MoKarte](), count: spieler)
        var i = 0
        while !deck.isEmpty { h[i % spieler].append(deck.removeLast()); i += 1 }
        haende = h.map { $0.sorted { ($0.wert, $0.farbe) < ($1.wert, $1.farbe) } }
        richtigGezweifelt = Array(repeating: 0, count: spieler); falschGezweifelt = Array(repeating: 0, count: spieler)
    }

    /// Feste Hände (Tests, Wiederaufnahme).
    public init(haende: [[MoKarte]], dran: Int = 0, rang: Int = 7) {
        self.haende = haende; self.dran = dran; self.rang = rang
        richtigGezweifelt = Array(repeating: 0, count: haende.count); falschGezweifelt = Array(repeating: 0, count: haende.count)
    }

    private func weiter(_ i: Int) -> Int { (i + 1) % haende.count }
    private func naechsterRang() -> Int { rang == 14 ? 7 : rang + 1 }

    /// Legt Karten (Indizes in der Hand) verdeckt ab.
    @discardableResult
    public mutating func lege(_ indizes: [Int]) -> Bool {
        guard phase == .legen, gewinner == nil, (1...4).contains(indizes.count), Set(indizes).count == indizes.count,
              indizes.allSatisfy({ haende[dran].indices.contains($0) }) else { return false }
        let karten = indizes.sorted(by: >).map { haende[dran].remove(at: $0) }
        haufen += karten; letzter = dran; letzteAnzahl = karten.count
        aufdeckung = nil
        dran = weiter(dran); phase = .entscheiden
        return true
    }

    public var gelogen: Bool {
        guard letzteAnzahl > 0 else { return false }
        return !haufen.suffix(letzteAnzahl).allSatisfy { $0.wert == rang }
    }

    /// Der Nächste ruft „Gelogen!“: aufdecken; der Verlierer nimmt den Haufen.
    public mutating func anzweifeln() {
        guard phase == .entscheiden, let l = letzter else { return }
        let karten = Array(haufen.suffix(letzteAnzahl))
        let log = gelogen
        let verlierer = log ? l : dran
        // Blatt 22 (EB2): `dran` ist, wer zweifelt. Nur zählen, wenn der Stand die Zähler kennt (sonst nil, alter Stand).
        if log { if richtigGezweifelt?.indices.contains(dran) == true { richtigGezweifelt![dran] += 1 } }
        else { if falschGezweifelt?.indices.contains(dran) == true { falschGezweifelt![dran] += 1 } }
        haende[verlierer] += haufen
        haende[verlierer].sort { ($0.wert, $0.farbe) < ($1.wert, $1.farbe) }
        haufen = []
        aufdeckung = (karten, log, verlierer)
        rang = naechsterRang(); letzteAnzahl = 0
        if !log, haende[l].isEmpty { gewinner = l }      // ehrlich ausgespielt und nicht überführt: gewonnen
        // Wer den Haufen nimmt, ist als Nächster dran – außer er hat (nach dem Aufdecken) etwas gutzumachen
        dran = verlierer; phase = .legen; letzter = nil
    }

    /// Der Nächste glaubt: Ist die Hand des Vorgängers leer, hat er gewonnen.
    public mutating func glauben() {
        guard phase == .entscheiden, let l = letzter else { return }
        if haende[l].isEmpty { gewinner = l; return }
        rang = naechsterRang(); phase = .legen; aufdeckung = nil
    }
}

public enum MogelnComputer {
    /// Wahrscheinlichkeit (0…1), dass die letzte Behauptung stimmt, aus Sicht von `spieler`: Von den vier Karten des Rangs sind die eigenen
    /// bekannt, die übrigen verteilen sich zufällig auf die unbekannten Karten. 0, wenn es rechnerisch unmöglich ist.
    public static func wahrheitsChance(_ m: Mogeln, spieler: Int) -> Double {
        let n = m.letzteAnzahl
        guard n > 0 else { return 1 }
        let eigene = m.haende[spieler].filter { $0.wert == m.rang }.count
        let frei = 4 - eigene
        if n > frei { return 0 }
        let unbekannt = 32 - m.haende[spieler].count
        var p = 1.0
        for i in 0..<n { p *= Double(frei - i) / Double(max(1, unbekannt - i)) }
        return p
    }

    /// Legt ehrlich, was er hat; sonst eine Karte als Lüge.
    public static func lege(_ m: Mogeln) -> [Int] {
        let h = m.haende[m.dran]
        let echte = h.indices.filter { h[$0].wert == m.rang }
        if !echte.isEmpty { return Array(echte.prefix(4)) }
        // Lüge: schwächste (unwichtigste) Karte – hier die erste
        return h.isEmpty ? [] : [0]
    }

    /// `stufe` 1 leicht (zweifelt nach Gefühl, kennt die Kartenzahl nicht), 2 mittel, 3 schwer (zweifelt gezielter).
    public static func zweifelt<G: RandomNumberGenerator>(_ m: Mogeln, spieler: Int, stufe: Int = 2, mit g: inout G) -> Bool {
        if stufe <= 1 { return Double.random(in: 0..<1, using: &g) < 0.3 }
        let eigene = m.haende[spieler].filter { $0.wert == m.rang }.count
        let behauptet = m.letzteAnzahl
        if eigene + behauptet > 4 { return true }            // mehr als vier gleiche Karten gibt es nicht
        if let l = m.letzter, m.haende[l].isEmpty { return Double.random(in: 0..<1, using: &g) < 0.9 }
        // Wer kurz vor dem Ende steht, wird eher angezweifelt; so enden Partien auch gegen Computer in überschaubarer Zeit
        let nah = m.letzter.map { m.haende[$0].count <= 2 } ?? false
        let bonus = stufe >= 3 ? 0.12 : 0
        return Double.random(in: 0..<1, using: &g) < (nah ? 0.6 : (behauptet >= 3 ? 0.5 : 0.3)) + Double(eigene) * (0.1 + bonus) + (stufe >= 3 && behauptet >= 3 ? 0.15 : 0)
    }
}
