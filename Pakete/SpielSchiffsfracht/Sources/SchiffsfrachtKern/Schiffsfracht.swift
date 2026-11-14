// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern

/// Schiffsfracht (Würfelspiel „Schiff, Kapitän, Mannschaft“): Mit fünf Würfeln musst du der Reihe nach eine 6 (Schiff), eine 5 (Kapitän)
/// und eine 4 (Mannschaft) werfen und festhalten. Die übrigen zwei Würfel sind die Fracht. Du hast drei Würfe pro Runde.
public struct Schiffsfracht: Equatable, Sendable, Codable {
    public static let runden = 5
    public let spieler: Int
    public private(set) var runde = 0
    public private(set) var amZug = 0
    public private(set) var becher = WuerfelBecher(anzahl: 5)
    public private(set) var fest: [Int] = []           // festgelegte Würfelwerte in der Reihenfolge 6, 5, 4
    public private(set) var wuerfe = 0
    public private(set) var ergebnisse: [Int?]         // Fracht der Runde (0 = nichts, -1 noch offen)
    public private(set) var punkte: [Int]
    public private(set) var rundeGewertet = false
    public private(set) var rundenSieger: [Int] = []
    public var vorbei: Bool { runde >= Schiffsfracht.runden }

    public init(spieler: Int) {
        self.spieler = max(2, min(4, spieler))
        ergebnisse = Array(repeating: nil, count: self.spieler); punkte = Array(repeating: 0, count: self.spieler)
    }

    /// Nächster benötigter Wert (6, 5, 4) oder nil, wenn die Mannschaft komplett ist.
    public var gesucht: Int? { fest.count < 3 ? 6 - fest.count : nil }
    public var mannschaftKomplett: Bool { fest.count == 3 }
    /// Augen der freien Würfel (Fracht), wenn die Mannschaft komplett ist.
    public var fracht: Int { mannschaftKomplett ? freieWuerfel.reduce(0, +) : 0 }
    public var freieWuerfel: [Int] { frei.map { becher.augen[$0] } }
    private var frei: [Int] { becher.augen.indices.filter { !festeIndizes.contains($0) } }
    private var festeIndizes: Set<Int> = []
    /// Wie viele Würfel der nächste Wurf wirft (für echte Würfel: so viele Augen eintippen).
    public var wuerfelAnzahl: Int { 5 - festeIndizes.count }

    /// Wirft alle nicht festgelegten Würfel und legt automatisch Schiff, Kapitän und Mannschaft fest.
    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) {
        guard !vorbei, !rundeGewertet, wuerfe < 3 else { return }
        for i in becher.augen.indices { becher.gehalten[i] = festeIndizes.contains(i) }
        becher.wuerfeln(mit: &g); wuerfe += 1
        while let w = gesucht, let i = becher.augen.indices.first(where: { !festeIndizes.contains($0) && becher.augen[$0] == w }) {
            festeIndizes.insert(i); fest.append(w)
        }
    }

    /// Beendet den Zug (nötig vor Wurf 3 oder nach beliebigem Wurf).
    public mutating func fertig() {
        guard !vorbei, !rundeGewertet, wuerfe > 0 else { return }
        ergebnisse[amZug] = mannschaftKomplett ? fracht : 0
        fest = []; festeIndizes = []; wuerfe = 0; becher.freigeben()
        if amZug == spieler - 1 { werte() } else { amZug += 1 }
    }

    private mutating func werte() {
        let werte = ergebnisse.map { $0 ?? 0 }
        let best = werte.max()!
        rundenSieger = best > 0 ? werte.indices.filter { werte[$0] == best } : []
        for i in rundenSieger { punkte[i] += 1 }
        rundeGewertet = true
    }

    public mutating func naechsteRunde() {
        guard rundeGewertet else { return }
        runde += 1; amZug = 0; ergebnisse = Array(repeating: nil, count: spieler); rundeGewertet = false; rundenSieger = []
    }

    /// Computer: würfelt weiter, solange die Mannschaft fehlt oder die Fracht unter 8 liegt und noch Würfe frei sind.
    public var computerWillWeiter: Bool { computerWillWeiter(stufe: 2) }

    /// Entscheidung des Computers nach Stufe: 1 leicht (feste Schwelle 9), ab 2 mit Blick auf die Gegner und die restlichen Würfe.
    /// Wer als Letzter dran ist, hört auf, sobald er den besten Wert übertroffen hat; sonst zählt die Schwelle (9 bei zwei, 8 bei einem Wurf übrig).
    public func computerWillWeiter(stufe: Int) -> Bool {
        guard wuerfe < 3, !vorbei, !rundeGewertet else { return false }
        guard mannschaftKomplett else { return true }
        if stufe <= 1 { return fracht < 9 }
        let andere = ergebnisse.enumerated().filter { $0.offset != amZug }.compactMap { $0.element }
        let best = andere.max() ?? 0
        let letzter = andere.count == spieler - 1
        if letzter && best > 0 {
            if fracht > best { return false }
            if fracht == best { return best < 7 }
            return best < 12
        }
        return fracht < (wuerfe <= 1 ? 9 : 8)
    }
}
