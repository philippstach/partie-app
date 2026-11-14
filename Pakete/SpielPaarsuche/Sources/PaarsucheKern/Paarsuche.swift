// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Paarsuche (Memory): Verdeckte Karten, je zwei mit gleichem Motiv. Wer ein Paar aufdeckt, bekommt es und darf nochmal.
public struct Paarsuche: Equatable, Sendable, Codable {
    public struct Karte: Equatable, Sendable, Codable {
        public var motiv: Int
        public var gefunden = false
        public var finder: Int?
    }

    public private(set) var karten: [Karte]
    public private(set) var offen: [Int] = []
    public private(set) var amZug = 0
    public private(set) var punkte: [Int]
    public private(set) var zuege = 0              // Anzahl Paarversuche (zwei Karten = ein Zug)
    /// Was der Computer gesehen hat: Kartenplatz → Motiv (wird vergessen, siehe `vergiss`).
    public private(set) var gedaechtnis: [Int: Int] = [:]
    public let spieler: Int

    public init<G: RandomNumberGenerator>(paare: Int, spieler: Int, mit g: inout G) {
        var m = Array(0..<paare) + Array(0..<paare)
        m.shuffle(using: &g)
        karten = m.map { Karte(motiv: $0) }
        self.spieler = max(1, spieler)
        punkte = Array(repeating: 0, count: max(1, spieler))
    }

    public var vorbei: Bool { karten.allSatisfy(\.gefunden) }
    public var paareGefunden: Int { karten.filter(\.gefunden).count / 2 }

    /// Deckt eine Karte auf. `false`, wenn nicht erlaubt (schon offen, gefunden oder zwei liegen bereits offen).
    @discardableResult
    public mutating func decke(_ i: Int) -> Bool {
        guard karten.indices.contains(i), !karten[i].gefunden, !offen.contains(i), offen.count < 2 else { return false }
        offen.append(i)
        gedaechtnis[i] = karten[i].motiv
        return true
    }

    public var zweiOffen: Bool { offen.count == 2 }

    /// Wertet die zwei offenen Karten aus. `true` bei einem Paar (der Spieler bleibt am Zug), sonst geht es weiter.
    @discardableResult
    public mutating func aufloesen() -> Bool {
        guard offen.count == 2 else { return false }
        zuege += 1
        let a = offen[0], b = offen[1]
        offen = []
        if karten[a].motiv == karten[b].motiv {
            karten[a].gefunden = true; karten[b].gefunden = true
            karten[a].finder = amZug; karten[b].finder = amZug
            punkte[amZug] += 1
            gedaechtnis[a] = nil; gedaechtnis[b] = nil
            return true
        }
        amZug = (amZug + 1) % spieler
        return false
    }

    /// Siegerliste: Spieler nach Paaren absteigend (Gleichstand: gleiche Plätze regelt der Aufrufer).
    public var rangfolge: [Int] { (0..<spieler).sorted { punkte[$0] > punkte[$1] } }

    // MARK: Computer

    /// Jeder gemerkte Platz wird mit der Wahrscheinlichkeit `1 - staerke` vergessen (einmal pro Zug des Computers).
    public mutating func vergiss<G: RandomNumberGenerator>(staerke: Double, mit g: inout G) {
        for k in Array(gedaechtnis.keys) where Double.random(in: 0..<1, using: &g) > staerke { gedaechtnis[k] = nil }
    }

    /// Wählt die nächste Karte für den Computer (`staerke` 0…1: wie zuverlässig er sich Gesehenes merkt).
    public func computerWahl<G: RandomNumberGenerator>(staerke: Double, mit g: inout G) -> Int? {
        let frei = karten.indices.filter { !karten[$0].gefunden && !offen.contains($0) }
        guard !frei.isEmpty else { return nil }
        if let erste = offen.first {
            let motiv = karten[erste].motiv
            if let partner = frei.first(where: { gedaechtnis[$0] == motiv }), Double.random(in: 0..<1, using: &g) < staerke { return partner }
            let unbekannt = frei.filter { gedaechtnis[$0] == nil }
            return (unbekannt.isEmpty ? frei : unbekannt).randomElement(using: &g)
        }
        // Erste Karte: bekanntes Paar nehmen, sonst eine unbekannte
        var nachMotiv: [Int: [Int]] = [:]
        for (platz, m) in gedaechtnis where frei.contains(platz) { nachMotiv[m, default: []].append(platz) }
        if let paar = nachMotiv.values.first(where: { $0.count >= 2 }), Double.random(in: 0..<1, using: &g) < staerke { return paar[0] }
        let unbekannt = frei.filter { gedaechtnis[$0] == nil }
        return (unbekannt.isEmpty ? frei : unbekannt).randomElement(using: &g)
    }
}
