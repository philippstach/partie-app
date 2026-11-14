// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Bunco (USA): sechs Runden, in Runde r zählt die Augenzahl r. Es wird mit drei Würfeln gewürfelt.
/// Jeder Würfel mit der Rundenzahl gibt 1 Punkt; drei davon sind ein Bunco (21 Punkte und die Runde endet),
/// drei gleiche andere Würfel sind ein Mini-Bunco (5 Punkte). Wer punktet, würfelt weiter, sonst ist der Gegner dran.
/// Wer zuerst 21 Punkte hat, gewinnt die Runde. Nach sechs Runden gewinnt, wer mehr Runden gewonnen hat.
public struct Bunco: Equatable, Sendable, Codable {
    public static let rundenZahl = 6
    public static let rundenZiel = 21
    public private(set) var runde = 1                      // 1...6
    public private(set) var punkte = [0, 0]                // in der aktuellen Runde
    public private(set) var rundenSiege = [0, 0]
    public private(set) var amZug = 0
    public private(set) var letzterWurf: [Int] = []
    public private(set) var letzteWertung: Wertung?
    public private(set) var vorbei = false
    /// Gewinner jeder beendeten Runde, in der Reihenfolge der Runden.
    public private(set) var rundenVerlauf: [Int] = []
    public private(set) var rundeBeendetVon: Int?          // Gewinner der gerade beendeten Runde (bis zur nächsten Runde)

    public enum Wertung: Equatable, Sendable, Codable { case nichts, punkte(Int), miniBunco, bunco }

    public init() {}

    public var ziel: Int { runde }

    public static func bewerte(_ w: [Int], ziel: Int) -> Wertung {
        guard w.count == 3 else { return .nichts }
        if w.allSatisfy({ $0 == ziel }) { return .bunco }
        if Set(w).count == 1 { return .miniBunco }
        let n = w.filter { $0 == ziel }.count
        return n > 0 ? .punkte(n) : .nichts
    }

    /// Würfeln mit festen Augen (Tests, echte Würfel). Liefert false bei ungültigen Augen oder wenn das Spiel vorbei ist.
    @discardableResult
    public mutating func wuerfle(augen: [Int]) -> Bool {
        guard !vorbei, rundeBeendetVon == nil, augen.count == 3, augen.allSatisfy({ (1...6).contains($0) }) else { return false }
        letzterWurf = augen
        let w = Self.bewerte(augen, ziel: ziel)
        letzteWertung = w
        switch w {
        case .nichts: amZug = 1 - amZug; return true
        case .punkte(let n): punkte[amZug] += n
        case .miniBunco: punkte[amZug] += 5
        case .bunco: punkte[amZug] += Self.rundenZiel
        }
        if punkte[amZug] >= Self.rundenZiel { beendeRunde(gewinner: amZug) }
        return true
    }

    @discardableResult
    public mutating func wuerfle<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        wuerfle(augen: (0..<3).map { _ in Int.random(in: 1...6, using: &g) })
    }

    private mutating func beendeRunde(gewinner: Int) {
        rundenSiege[gewinner] += 1; rundeBeendetVon = gewinner; rundenVerlauf.append(gewinner)
        if runde == Self.rundenZahl { vorbei = true }
    }

    /// Nächste Runde starten (der Gewinner der letzten Runde beginnt nicht, es wechselt immer).
    public mutating func naechsteRunde() {
        guard rundeBeendetVon != nil, !vorbei else { return }
        runde += 1; punkte = [0, 0]; rundeBeendetVon = nil; letzterWurf = []; letzteWertung = nil
        amZug = (runde - 1) % 2
    }

    public var sieger: Int? { vorbei ? (rundenSiege[0] == rundenSiege[1] ? nil : (rundenSiege[0] > rundenSiege[1] ? 0 : 1)) : nil }
}
