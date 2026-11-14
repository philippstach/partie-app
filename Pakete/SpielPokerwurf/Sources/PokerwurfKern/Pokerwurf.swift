// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern

/// Wertung einer Fünfer-Würfelhand wie beim Würfelpoker.
public struct PokerHand: Comparable, Equatable, Sendable, Codable {
    public enum Art: Int, Comparable, Sendable, Codable {
        case nichts, paar, zweiPaare, drilling, kleineStrasse, grosseStrasse, fullHouse, vierling, fuenfling
        public static func < (a: Art, b: Art) -> Bool { a.rawValue < b.rawValue }
        public var name: String { ["Nichts", "Ein Paar", "Zwei Paare", "Drilling", "Kleine Straße", "Große Straße", "Full House", "Vierling", "Fünfling"][rawValue] }
    }
    public let art: Art
    public let ordnung: [Int]        // Zum Vergleichen innerhalb gleicher Art (wichtigste Werte zuerst)

    public init(_ augen: [Int]) {
        let zaehl = (1...6).map { v in augen.filter { $0 == v }.count }
        let gruppen = (1...6).filter { zaehl[$0 - 1] > 0 }.sorted { zaehl[$0 - 1] != zaehl[$1 - 1] ? zaehl[$0 - 1] > zaehl[$1 - 1] : $0 > $1 }
        let muster = gruppen.map { zaehl[$0 - 1] }
        let set = Set(augen)
        if muster == [5] { art = .fuenfling }
        else if muster == [4, 1] { art = .vierling }
        else if muster == [3, 2] { art = .fullHouse }
        else if set == [1, 2, 3, 4, 5] || set == [2, 3, 4, 5, 6] { art = set.contains(6) ? .grosseStrasse : .kleineStrasse }
        else if muster == [3, 1, 1] { art = .drilling }
        else if muster == [2, 2, 1] { art = .zweiPaare }
        else if muster == [2, 1, 1, 1] { art = .paar }
        else { art = .nichts }
        ordnung = (art == .nichts) ? augen.sorted(by: >) : gruppen
    }

    public static func < (a: PokerHand, b: PokerHand) -> Bool {
        a.art != b.art ? a.art < b.art : a.ordnung.lexicographicallyPrecedes(b.ordnung)
    }
}

/// Pokerwurf: Reihum würfelt jeder bis zu dreimal mit fünf Würfeln (Würfel dazwischen festhalten). Die beste Hand der Runde gewinnt einen Punkt.
public struct Pokerwurf: Equatable, Sendable, Codable {
    public static let runden = 5
    public let spieler: Int
    public private(set) var runde = 0
    public private(set) var amZug = 0
    public private(set) var becher = WuerfelBecher(anzahl: 5)
    public private(set) var wuerfe = 0
    public private(set) var haende: [PokerHand?]
    public private(set) var punkte: [Int]
    public private(set) var rundenSieger: [Int] = []       // Sieger der letzten gewerteten Runde
    public private(set) var rundeGewertet = false
    /// Blatt 22 (EB2, Schritt 2): je Person die beste Hand der ganzen Partie. Optional: ein Stand von vor dem Update lädt mit `nil`, dann keine Zeile „Bester Wurf“.
    public private(set) var besteHaende: [PokerHand?]?
    public var vorbei: Bool { runde >= Pokerwurf.runden }
    /// T-097: Wer die Partie beginnt (0-basiert). Jede weitere Runde beginnt die nächste Person. Optional: ein alter Stand lädt mit `nil` (= Person 1, wie bisher).
    public private(set) var beginner: Int?
    private var rundenStart: Int { ((beginner ?? 0) + runde) % spieler }

    public init(spieler: Int, beginner: Int) {
        self.init(spieler: spieler)
        self.beginner = min(max(beginner, 0), self.spieler - 1)
        amZug = rundenStart
    }

    public init(spieler: Int) { self.spieler = max(2, min(4, spieler)); haende = Array(repeating: nil, count: self.spieler); punkte = Array(repeating: 0, count: self.spieler); besteHaende = Array(repeating: nil, count: self.spieler) }

    /// Alle drei Würfe verbraucht: der Zug lässt sich nur noch mit `fertig()` beenden.
    public var mussBehalten: Bool { !vorbei && !rundeGewertet && wuerfe >= 3 }
    /// Der Zug darf beendet werden (mindestens ein Wurf).
    public var zugBeendbar: Bool { !vorbei && !rundeGewertet && wuerfe > 0 }

    public var aktuelleHand: PokerHand { PokerHand(becher.augen) }

    /// RT-011: Würfeln ist möglich, solange Würfe übrig sind und (ab dem zweiten Wurf) mindestens ein Würfel nicht gehalten wird;
    /// sonst würde ein Wurf verbraucht, ohne dass sich ein Würfel ändert.
    public var kannWuerfeln: Bool { !vorbei && wuerfe < 3 && !rundeGewertet && (wuerfe == 0 || becher.gehalten.contains(false)) }

    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) {
        guard kannWuerfeln else { return }
        becher.wuerfeln(mit: &g); wuerfe += 1
    }

    /// TF24: Schalter „Gehaltene Würfel bleiben liegen“ aus → nach dem Wurf alle Würfel wieder frei.
    public mutating func alleFreigeben() { becher.freigeben() }
    public mutating func halte(_ i: Int) { guard wuerfe > 0, wuerfe < 3 else { return }; becher.halten(i) }

    /// Beendet den Zug des Spielers (mindestens ein Wurf nötig).
    public mutating func fertig() {
        guard !vorbei, wuerfe > 0, !rundeGewertet else { return }
        haende[amZug] = PokerHand(becher.augen)
        if var b = besteHaende, b.indices.contains(amZug), let h = haende[amZug] {
            if let alt = b[amZug], alt >= h {} else { b[amZug] = h }
            besteHaende = b
        }
        becher.freigeben(); wuerfe = 0
        if haende.compactMap({ $0 }).count == spieler { werte() } else { amZug = (amZug + 1) % spieler }   // T-097: Reihenfolge rotiert je Runde
    }

    private mutating func werte() {
        let beste = haende.compactMap { $0 }.max()!
        rundenSieger = haende.indices.filter { haende[$0] == beste }
        for i in rundenSieger { punkte[i] += 1 }
        rundeGewertet = true
    }

    public mutating func naechsteRunde() {
        guard rundeGewertet else { return }
        runde += 1; amZug = rundenStart; haende = Array(repeating: nil, count: spieler); rundeGewertet = false; rundenSieger = []
    }

    /// Wie `computerHalten`, aber mit Fehlerquote: Mit Wahrscheinlichkeit `fehler` hält er zufällig.
    public static func computerHalten<G: RandomNumberGenerator>(_ augen: [Int], fehler: Double, mit g: inout G) -> [Bool] {
        if fehler > 0, Double.random(in: 0..<1, using: &g) < fehler { return augen.map { _ in Bool.random(using: &g) } }
        return computerHalten(augen)
    }

    /// Vier aufeinanderfolgende Augen (1-2-3-4, 2-3-4-5 oder 3-4-5-6), auf die eine Straße noch fehlt, sonst nil.
    static func vierLauf(_ augen: [Int]) -> [Int]? {
        let menge = Set(augen)
        return [[2, 3, 4, 5], [1, 2, 3, 4], [3, 4, 5, 6]].first { Set($0).isSubset(of: menge) }
    }

    /// Der Computer hört auf, wenn er als Letzter schon die beste Hand der Runde hält (weiter würfeln kann nur verlieren).
    public func computerFertig(stufe: Int) -> Bool {
        guard stufe >= 2, wuerfe > 0, !rundeGewertet, haende.compactMap({ $0 }).count == spieler - 1 else { return false }
        let andere = haende.compactMap { $0 }
        guard let beste = andere.max() else { return false }
        return aktuelleHand > beste && aktuelleHand.art >= .drilling
    }

    /// Welche Würfel der Computer festhält (`true` = halten).
    public static func computerHalten(_ augen: [Int]) -> [Bool] {
        let h = PokerHand(augen)
        switch h.art {
        case .fuenfling, .grosseStrasse, .kleineStrasse, .fullHouse: return Array(repeating: true, count: 5)
        case .vierling, .drilling, .zweiPaare, .paar:
            if let lauf = vierLauf(augen), h.art == .paar ? lauf == [2, 3, 4, 5] : h.art == .nichts {
                var gesehen = Set<Int>()
                return augen.map { lauf.contains($0) && gesehen.insert($0).inserted }
            }
            let zaehl = (1...6).map { v in augen.filter { $0 == v }.count }
            return augen.map { zaehl[$0 - 1] >= 2 }
        case .nichts:
            if let lauf = vierLauf(augen) {
                var gesehen = Set<Int>()
                return augen.map { lauf.contains($0) && gesehen.insert($0).inserted }
            }
            let hoch = augen.max()!
            return augen.map { $0 == hoch && hoch >= 5 }
        }
    }
}
