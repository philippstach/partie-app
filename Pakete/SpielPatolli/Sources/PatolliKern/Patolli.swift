// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Patolli (aztekisches Würfelbrettspiel, eigene Regelfassung): Zwei Spieler, je vier Steine, fünf Bohnen als Würfel.
/// Ringbahn mit 24 Feldern. Spieler 0 startet auf Feld 0, Spieler 1 auf Feld 12. Jeder Stein läuft einmal um den Ring (24 Felder) ins Ziel.
public struct Patolli: Equatable, Sendable, Codable {
    public static let ring = 24
    public static let steine = 4
    public static let startFeld = [0, 12]

    /// Fortschritt je Stein: -1 = im Haus, 0…23 = unterwegs (Schritte seit dem Start), 24 = im Ziel.
    public private(set) var stand: [[Int]] = [Array(repeating: -1, count: 4), Array(repeating: -1, count: 4)]
    public private(set) var amZug = 0
    public private(set) var wurf: Int?                    // Schritte des aktuellen Wurfs (nil = noch nicht gewürfelt)
    public private(set) var bohnen: [Bool] = []           // markierte Bohnen des letzten Wurfs
    public private(set) var nochmal = false               // Der Spieler wirft nach seinem Zug erneut
    public private(set) var gewinner: Int?
    public private(set) var geschlagen: Int?              // zuletzt geschlagener Spieler (für Anzeige)

    public init() {}
    public init(stand: [[Int]], amZug: Int = 0) { self.stand = stand; self.amZug = amZug }

    /// Auf Rasterfeld des Rings.
    public func feld(_ spieler: Int, _ fortschritt: Int) -> Int { (Self.startFeld[spieler] + fortschritt) % Self.ring }
    /// Sichere Felder (kein Schlagen, kein Betreten bei Gegner): Startfelder und alle Felder mit Nummer durch 6 teilbar.
    public static func sicher(_ f: Int) -> Bool { f % 6 == 0 }
    /// Sonnenfelder geben einen zusätzlichen Wurf (Feldnummer ≡ 3 mod 6).
    public static func sonne(_ f: Int) -> Bool { f % 6 == 3 }

    /// Fünf Bohnen: Anzahl markierter = Schritte; 0 = Aussetzen, 5 = zehn Schritte und neuer Wurf.
    public static func schritte(markiert n: Int) -> Int { n == 5 ? 10 : n }

    @discardableResult
    public mutating func wuerfle<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        setzeWurf((0..<5).map { _ in Bool.random(using: &g) })
    }
    @discardableResult
    public mutating func setzeWurf(_ markiert: [Bool]) -> Bool {
        guard gewinner == nil, wurf == nil, markiert.count == 5 else { return false }
        bohnen = markiert
        let n = markiert.filter { $0 }.count
        wurf = Self.schritte(markiert: n)
        nochmal = n == 5
        geschlagen = nil
        if zuege.isEmpty { beendeZug() }
        return true
    }

    /// Erlaubte Steine (Index), die mit dem aktuellen Wurf ziehen dürfen.
    public var zuege: [Int] {
        guard let w = wurf, w > 0, gewinner == nil else { return [] }
        var res: [Int] = []
        var gesehen = Set<Int>()
        for i in 0..<Self.steine {
            let s = stand[amZug][i]
            guard s < Self.ring, gesehen.insert(s).inserted else { continue }
            if ziel(i, w) != nil { res.append(i) }
        }
        return res
    }

    /// Zielfortschritt des Steins, falls erlaubt.
    private func ziel(_ i: Int, _ w: Int) -> Int? {
        let s = stand[amZug][i]
        let nach = s < 0 ? w - 1 : s + w          // Haus: erster Schritt landet auf Fortschritt w-1 (Startfeld = 0)
        if nach >= Self.ring { return Self.ring }     // Ziel (überzählige Schritte verfallen)
        if stand[amZug].contains(nach) { return nil }
        let f = feld(amZug, nach)
        for (j, g) in stand[1 - amZug].enumerated() where g >= 0 && g < Self.ring && feld(1 - amZug, g) == f {
            _ = j
            if Self.sicher(f) { return nil }
        }
        return nach
    }

    @discardableResult
    public mutating func ziehe(_ i: Int) -> Bool {
        guard zuege.contains(i), let w = wurf, let nach = ziel(i, w) else { return false }
        stand[amZug][i] = nach
        var sonne = false
        if nach < Self.ring {
            let f = feld(amZug, nach)
            for j in 0..<Self.steine where stand[1 - amZug][j] >= 0 && stand[1 - amZug][j] < Self.ring && feld(1 - amZug, stand[1 - amZug][j]) == f {
                stand[1 - amZug][j] = -1; geschlagen = 1 - amZug
            }
            sonne = Self.sonne(f)
        }
        if stand[amZug].allSatisfy({ $0 == Self.ring }) { gewinner = amZug; return true }
        if sonne { nochmal = true }
        beendeZug()
        return true
    }

    private mutating func beendeZug() {
        wurf = nil
        if gewinner == nil && !nochmal { amZug = 1 - amZug }
        nochmal = false
    }
}

public enum PatolliComputer {
    /// Bewertet jeden Zug: Ziel > Schlagen > Sonnenfeld > Haus verlassen > weitester Stein.
    /// `stufe` 1 leicht (zufällig), 2 mittel, 3 schwer (meidet Felder kurz vor gegnerischen Steinen).
    public static func wahl(_ p: Patolli, stufe: Int = 2) -> Int? {
        guard let w = p.wurf else { return nil }
        if stufe <= 1 { return p.zuege.randomElement() }
        var best: (Int, Double)?
        for i in p.zuege {
            let s = p.stand[p.amZug][i]
            let nach = s < 0 ? w - 1 : s + w
            var v = Double(max(s, 0)) * 0.1
            if nach >= Patolli.ring { v += 100 }
            else {
                let f = p.feld(p.amZug, nach)
                if p.stand[1 - p.amZug].contains(where: { $0 >= 0 && $0 < Patolli.ring && p.feld(1 - p.amZug, $0) == f }) { v += 50 }
                if Patolli.sonne(f) { v += 20 }
                if Patolli.sicher(f) { v += 5 }
            }
            if s < 0 { v += 8 }
            if stufe >= 3 {
                // Gefahr nach Wahrscheinlichkeit der Bohnenwürfe: d Schritte treffen mit C(5,d)/32, zehn Schritte mit 1/32.
                func gefahr(_ f: Int) -> Double {
                    guard !Patolli.sicher(f) else { return 0 }
                    var g = 0.0
                    for gs in p.stand[1 - p.amZug] where gs >= 0 && gs < Patolli.ring {
                        let d = (f - p.feld(1 - p.amZug, gs) + Patolli.ring) % Patolli.ring
                        g += wahrscheinlichkeit(d)
                    }
                    if p.stand[1 - p.amZug].contains(-1), f == Patolli.startFeld[1 - p.amZug] { g += wahrscheinlichkeit(1) }
                    return g
                }
                let vorher = gefahr(p.feld(p.amZug, max(s, 0)))
                if s >= 0 { v += vorher * 6 }                                  // bedrohten Stein lieber retten
                if nach < Patolli.ring { v -= gefahr(p.feld(p.amZug, nach)) * 6 }
            }
            if best == nil || v > best!.1 { best = (i, v) }
        }
        return best?.0
    }

    /// Wahrscheinlichkeit, mit fünf Bohnen genau `d` Schritte zu werfen (1…5 je C(5,d)/32; zehn Schritte bei allen fünf).
    static func wahrscheinlichkeit(_ d: Int) -> Double {
        let c = [0.0, 5, 10, 10, 5, 0, 0, 0, 0, 0, 1]
        return d >= 1 && d <= 10 ? c[d] / 32 : 0
    }
}
