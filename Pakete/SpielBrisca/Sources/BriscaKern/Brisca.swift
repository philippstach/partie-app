// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Spanisches 40er-Blatt ohne 8 und 9 (Ränge 1–7, 10–12). Farben: 0 Münzen, 1 Becher, 2 Schwerter, 3 Stäbe.
public struct BriscaKarte: Equatable, Hashable, Sendable, Codable {
    public let farbe: Int
    public let rang: Int
    public init(farbe: Int, rang: Int) { self.farbe = farbe; self.rang = rang }

    /// Augen: As 11, Drei 10, König 4, Reiter 3, Bube 2, sonst 0 (zusammen 120).
    public var augen: Int {
        switch rang { case 1: return 11; case 3: return 10; case 12: return 4; case 11: return 3; case 10: return 2; default: return 0 }
    }
    /// Reihenfolge beim Stechen innerhalb einer Farbe.
    public var staerke: Int {
        switch rang { case 1: return 10; case 3: return 9; case 12: return 8; case 11: return 7; case 10: return 6; case 7: return 5; case 6: return 4; case 5: return 3; case 4: return 2; default: return 1 }
    }
}

/// Brisca für zwei Spieler. Ein Atout (Trumpf) wird unten aufgedeckt. Wer 61+ Augen sammelt, gewinnt.
public struct Brisca: Equatable, Sendable, Codable {
    /// Speichern/Fortsetzen: der zuletzt gezeigte Stich ist nur Anzeige und wird nicht gespeichert.
    private enum CodingKeys: String, CodingKey { case stapel, atout, atoutKarte, haende, ausgespielt, augen, amZug, vorbei, gespielt }
    public private(set) var stapel: [BriscaKarte]          // letzte Karte (unten) ist das Atout
    public let atout: Int
    public let atoutKarte: BriscaKarte
    public private(set) var haende: [[BriscaKarte]] = [[], []]
    public private(set) var ausgespielt: [BriscaKarte?] = [nil, nil]
    public private(set) var augen = [0, 0]
    public private(set) var amZug = 0
    public private(set) var vorbei = false
    public private(set) var letzterStich: (gewinner: Int, karten: [BriscaKarte])?
    /// Alle bereits gewonnenen (offen gespielten) Karten, für Kartenzählen.
    public private(set) var gespielt: [BriscaKarte] = []

    public static func == (a: Brisca, b: Brisca) -> Bool {
        a.stapel == b.stapel && a.haende == b.haende && a.ausgespielt == b.ausgespielt && a.augen == b.augen && a.amZug == b.amZug && a.vorbei == b.vorbei
    }

    public init<G: RandomNumberGenerator>(mit g: inout G) {
        var k = (0..<4).flatMap { f in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12].map { BriscaKarte(farbe: f, rang: $0) } }
        k.shuffle(using: &g)
        self.init(karten: k)
    }
    /// Für Tests: feste Kartenfolge (Karte 0–2 Spieler 0, 3–5 Spieler 1, danach Stapel; letzte = Atout).
    public init(karten k: [BriscaKarte], amZug: Int = 0) {
        haende[0] = Array(k[0..<3]); haende[1] = Array(k[3..<6])
        stapel = Array(k[6...])
        atoutKarte = k.last!; atout = k.last!.farbe
        self.amZug = amZug
    }

    /// Kopie für Proben-Partien: eigene Hand bleibt, die Gegnerhand und der Stapel werden durch Annahmen ersetzt.
    public func mitGedachtenHaenden(spieler s: Int, gegner: [BriscaKarte], stapel neu: [BriscaKarte]) -> Brisca {
        var k = self
        k.haende[1 - s] = gegner
        // Der Stapel behält seine Länge; die Atout-Karte bleibt ganz unten.
        let n = stapel.count
        var st = Array(neu.prefix(max(0, n - 1)))
        while st.count < n - 1 { st.append(atoutKarte) }
        if n > 0 { st.append(atoutKarte) }
        k.stapel = st
        return k
    }

    public func sticht(_ gelegt: BriscaKarte, _ ausgangs: BriscaKarte) -> Bool {
        if gelegt.farbe == ausgangs.farbe { return gelegt.staerke > ausgangs.staerke }
        return gelegt.farbe == atout
    }

    @discardableResult
    public mutating func spiele(_ s: Int, karte i: Int) -> Bool {
        guard !vorbei, s == amZug, haende[s].indices.contains(i), ausgespielt[s] == nil else { return false }
        ausgespielt[s] = haende[s].remove(at: i)
        if let a = ausgespielt[1 - s] {
            // Zweiter Spieler hat gelegt: Auswerten. Führer = 1 - s.
            let gew = sticht(ausgespielt[s]!, a) ? s : 1 - s
            let paar = [a, ausgespielt[s]!]
            augen[gew] += paar.reduce(0) { $0 + $1.augen }
            letzterStich = (gew, paar)
            gespielt += paar
            ausgespielt = [nil, nil]
            // Nachziehen: Gewinner zuerst
            for p in [gew, 1 - gew] where !stapel.isEmpty { haende[p].append(stapel.removeFirst()) }
            amZug = gew
            if haende[0].isEmpty && haende[1].isEmpty { vorbei = true }
        } else { amZug = 1 - s }
        return true
    }

    public var sieger: Int? { vorbei ? (augen[0] == augen[1] ? nil : (augen[0] > augen[1] ? 0 : 1)) : nil }
}

public enum BriscaComputer {
    /// `stufe` 1 leicht (zufällig), 2 mittel (Regeln), 3 schwer (Stichproben: gedachte Gegnerhände, Proben-Partien).
    public static func wahl(_ b: Brisca, spieler s: Int, stufe: Int = 2) -> Int {
        if stufe <= 1 { return b.haende[s].indices.randomElement()! }
        if stufe >= 3, b.haende[s].count > 1 { return stichprobe(b, spieler: s) }
        return regel(b, spieler: s)
    }

    /// Alle unbekannten Karten (nicht in eigener Hand, nicht ausgespielt oder gewonnen, Atout-Karte unten bekannt).
    static func unbekannt(_ b: Brisca, spieler s: Int) -> [BriscaKarte] {
        var alle = (0..<4).flatMap { f in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12].map { BriscaKarte(farbe: f, rang: $0) } }
        var bekannt = Set(b.haende[s]); bekannt.insert(b.atoutKarte)
        for k in b.ausgespielt { if let k { bekannt.insert(k) } }
        for k in b.gespielt { bekannt.insert(k) }
        alle.removeAll { bekannt.contains($0) }
        return alle
    }

    static func stichprobe(_ b: Brisca, spieler s: Int, proben: Int = 24) -> Int {
        let hand = b.haende[s]
        let fremd = unbekannt(b, spieler: s)
        var summe = [Double](repeating: 0, count: hand.count)
        for _ in 0..<proben {
            var mischung = fremd.shuffled()
            let n = b.haende[1 - s].count
            guard mischung.count >= n else { continue }
            let gegnerHand = Array(mischung.prefix(n)); mischung.removeFirst(n)
            for i in hand.indices {
                var k = b.mitGedachtenHaenden(spieler: s, gegner: gegnerHand, stapel: mischung)
                k.spiele(s, karte: i)
                var z = 0
                while !k.vorbei && z < 60 { z += 1; k.spiele(k.amZug, karte: regel(k, spieler: k.amZug)) }
                summe[i] += Double(k.augen[s] - k.augen[1 - s])
            }
        }
        return summe.indices.max { summe[$0] < summe[$1] } ?? 0
    }

    static func regel(_ b: Brisca, spieler s: Int) -> Int {
        let h = b.haende[s]
        func wert(_ k: BriscaKarte) -> Int { k.augen * 10 + k.staerke + (k.farbe == b.atout ? 100 : 0) }
        if let a = b.ausgespielt[1 - s] {
            // Folgen: billigste Karte, die sticht und sich lohnt; sonst weniger wertvolle abwerfen
            let stechend = h.indices.filter { b.sticht(h[$0], a) }.sorted { wert(h[$0]) < wert(h[$1]) }
            if a.augen >= 3, let i = stechend.first { return i }
            if a.augen > 0, let i = stechend.first, h[i].farbe != b.atout || a.augen >= 4 { return i }
            return h.indices.min { wert(h[$0]) < wert(h[$1]) }!
        }
        // Ausspielen: möglichst wertlose Nicht-Atout-Karte
        return h.indices.min { wert(h[$0]) < wert(h[$1]) }!
    }
}
