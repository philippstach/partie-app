// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern

/// Esel: Jeder hat vier Karten. Gleichzeitig reicht jeder eine Karte an den linken Nachbarn weiter und nimmt die des rechten Nachbarn.
/// Wer vier gleiche Karten hat, legt die Hand auf den Tisch; alle anderen müssen so schnell wie möglich folgen. Der Letzte ist der Esel.
public struct Esel: Equatable, Sendable, Codable {
    public private(set) var haende: [[SkatKarte]]
    public private(set) var runde = 0
    public private(set) var griffe: [Int] = []        // Reihenfolge, in der die Hände auf dem Tisch landeten
    public let spieler: Int

    public init<G: RandomNumberGenerator>(spieler: Int, mit g: inout G) {
        self.spieler = max(3, min(5, spieler))
        // Pro Spieler ein Rang, je vier Farben
        let raenge = Array([14, 13, 12, 11, 10].prefix(self.spieler))
        var karten = raenge.flatMap { r in SkatKarte.Farbe.allCases.map { SkatKarte($0, r) } }
        karten.shuffle(using: &g)
        haende = (0..<self.spieler).map { Array(karten[($0 * 4)..<($0 * 4 + 4)]) }
        // Niemand soll sofort vier Gleiche haben
        while (0..<self.spieler).contains(where: { Esel.hatVierling(haende[$0]) }) {
            karten.shuffle(using: &g); haende = (0..<self.spieler).map { Array(karten[($0 * 4)..<($0 * 4 + 4)]) }
        }
    }

    /// Feste Hände (Tests, Wiederaufnahme).
    public init(haende: [[SkatKarte]]) { self.haende = haende; spieler = haende.count }

    public static func hatVierling(_ h: [SkatKarte]) -> Bool { h.count == 4 && Set(h.map(\.wert)).count == 1 }
    public func hatVierling(_ s: Int) -> Bool { Esel.hatVierling(haende[s]) }

    public var jemandHatVierling: Bool { (0..<spieler).contains { hatVierling($0) } }
    public var vorbei: Bool { griffe.count >= spieler - 1 }
    /// Der Esel: der Einzige, der nicht gegriffen hat.
    public var esel: Int? { vorbei ? (0..<spieler).first { !griffe.contains($0) } : nil }

    /// Alle reichen gleichzeitig weiter: `auswahl[i]` = Index der Karte, die Spieler i abgibt.
    public mutating func reiche(_ auswahl: [Int]) {
        guard !jemandHatVierling, auswahl.count == spieler else { return }
        var abgegeben: [SkatKarte] = []
        for i in 0..<spieler { abgegeben.append(haende[i].remove(at: auswahl[i])) }
        for i in 0..<spieler { haende[(i + 1) % spieler].append(abgegeben[i]) }   // Spieler i gibt an i+1 weiter
        runde += 1
    }

    /// Hand auf den Tisch. Nur erlaubt, wenn jemand (irgendwer) vier Gleiche hat, der Spieler nicht schon gegriffen hat – und der erste Griff nur mit Vierling.
    @discardableResult
    public mutating func greife(_ s: Int) -> Bool {
        guard !vorbei, !griffe.contains(s) else { return false }
        if griffe.isEmpty && !hatVierling(s) { return false }
        guard jemandHatVierling else { return false }
        griffe.append(s)
        return true
    }

    // MARK: Computer

    /// Welche Karte der Computer weitergibt: eine aus dem am seltensten gehaltenen Rang (er sammelt den häufigsten Rang).
    public func computerAbgabe<G: RandomNumberGenerator>(_ s: Int, mit g: inout G) -> Int {
        let h = haende[s]
        let zaehl = Dictionary(grouping: h, by: \.wert).mapValues(\.count)
        let kandidaten = h.indices.filter { zaehl[h[$0].wert] == zaehl.values.min() }
        return kandidaten.randomElement(using: &g)!
    }
}
