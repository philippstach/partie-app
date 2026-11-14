// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern

/// Spit/Speed (USA): Zwei Spieler legen gleichzeitig (ohne Reihenfolge) Karten auf zwei Mittelstapel,
/// die um genau einen Wert höher oder niedriger sind (Ass liegt zwischen König und 2, es geht rundum).
/// Wer zuerst Hand und Nachziehstapel leer hat, gewinnt. Sitzen beide fest, deckt man neue Mittelkarten auf.
public struct SpitSpeed: Sendable, Codable, Equatable {
    public static let handGroesse = 5
    public private(set) var haende: [[SkatKarte]] = [[], []]
    public private(set) var zieh: [[SkatKarte]] = [[], []]          // Nachziehstapel
    public private(set) var reserve: [[SkatKarte]] = [[], []]       // verdeckter Stapel zum Neuaufdecken
    public private(set) var mitte: [[SkatKarte]] = [[], []]         // zwei Mittelstapel (oberste = last)
    public private(set) var gewinner: Int?

    public init<G: RandomNumberGenerator>(mit g: inout G) {
        let blatt = SkatKarte.blatt.shuffled(using: &g)
        for p in 0..<2 {
            let teil = Array(blatt[(p * 26)..<(p * 26 + 26)])
            haende[p] = Array(teil[0..<5]); zieh[p] = Array(teil[5..<20]); reserve[p] = Array(teil[20..<26])
        }
        mitte[0] = [reserve[0].removeLast()]; mitte[1] = [reserve[1].removeLast()]
    }
    /// Für Tests.
    public init(haende: [[SkatKarte]], zieh: [[SkatKarte]] = [[], []], reserve: [[SkatKarte]] = [[], []], mitte: [[SkatKarte]]) {
        self.haende = haende; self.zieh = zieh; self.reserve = reserve; self.mitte = mitte
    }

    /// Nachbarn im Wert (Ass = 14 zwischen König 13 und 2; es geht rundum).
    public static func nachbar(_ a: SkatKarte, _ b: SkatKarte) -> Bool {
        let d = abs(a.wert - b.wert)
        return d == 1 || d == 12
    }

    public func kannLegen(_ p: Int, hand i: Int, auf m: Int) -> Bool {
        gewinner == nil && haende[p].indices.contains(i) && mitte[m].last.map { Self.nachbar($0, haende[p][i]) } == true
    }

    @discardableResult
    public mutating func lege(_ p: Int, hand i: Int, auf m: Int) -> Bool {
        guard kannLegen(p, hand: i, auf: m) else { return false }
        mitte[m].append(haende[p].remove(at: i))
        if !zieh[p].isEmpty { haende[p].append(zieh[p].removeLast()) }
        if haende[p].isEmpty { gewinner = p }
        return true
    }

    public func hatZug(_ p: Int) -> Bool {
        haende[p].indices.contains { i in (0..<2).contains { kannLegen(p, hand: i, auf: $0) } }
    }
    public var festgefahren: Bool { gewinner == nil && !hatZug(0) && !hatZug(1) }

    /// Neue Mittelkarten aufdecken (beide Spieler sitzen fest). Gibt false zurück, wenn kein Stapel mehr übrig ist.
    @discardableResult
    public mutating func neuAufdecken<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        guard festgefahren else { return false }
        if reserve[0].isEmpty || reserve[1].isEmpty {
            // Reserve leer: Mittelstapel (bis auf die oberste Karte) neu mischen und als Reserve verwenden
            var rest: [SkatKarte] = []
            for m in 0..<2 { let o = mitte[m].removeLast(); rest += mitte[m]; mitte[m] = [o] }
            rest.shuffle(using: &g)
            reserve[0] = Array(rest.prefix(rest.count / 2)); reserve[1] = Array(rest.dropFirst(rest.count / 2))
            guard !reserve[0].isEmpty, !reserve[1].isEmpty else { return endeNachKarten() }
        }
        mitte[0].append(reserve[0].removeLast()); mitte[1].append(reserve[1].removeLast())
        return true
    }
    private mutating func endeNachKarten() -> Bool {
        let a = haende[0].count + zieh[0].count, b = haende[1].count + zieh[1].count
        gewinner = a <= b ? 0 : 1; return false
    }

    public func restkarten(_ p: Int) -> Int { haende[p].count + zieh[p].count }
}

public enum SpitSpeedComputer {
    /// Ein möglicher Zug (Handindex, Mittelstapel).
    /// `stufe` 1 leicht (irgendein Zug), 2 mittel (Karte mit den meisten Anschlusskarten), 3 schwer (längste Zugfolge über beide Stapel vorausberechnet).
    public static func zug(_ s: SpitSpeed, spieler p: Int, stufe: Int = 2) -> (hand: Int, mitte: Int)? {
        var z: [(Int, Int)] = []
        for i in s.haende[p].indices { for m in 0..<2 where s.kannLegen(p, hand: i, auf: m) { z.append((i, m)) } }
        guard !z.isEmpty else { return nil }
        if stufe <= 1 { return z.randomElement() }
        func folge(_ i: Int, _ m: Int) -> Int {
            let k = s.haende[p][i]
            return s.haende[p].indices.filter { $0 != i && SpitSpeed.nachbar(s.haende[p][$0], k) }.count
        }
        if stufe == 2 { return z.max { folge($0.0, $0.1) < folge($1.0, $1.1) } }
        // Schwer: Wie viele Karten der Hand lassen sich nacheinander loswerden, wenn man mit diesem Zug beginnt?
        func kette(_ hand: [SkatKarte], _ oben: [SkatKarte?], _ tiefe: Int) -> Int {
            guard tiefe > 0 else { return 0 }
            var best = 0
            for (i, k) in hand.enumerated() { for m in 0..<2 {
                guard let o = oben[m], SpitSpeed.nachbar(o, k) else { continue }
                var h = hand; h.remove(at: i); var ob = oben; ob[m] = k
                best = max(best, 1 + kette(h, ob, tiefe - 1))
            } }
            return best
        }
        let oben: [SkatKarte?] = [s.mitte[0].last, s.mitte[1].last]
        return z.max { a, b in
            func wert(_ x: (Int, Int)) -> Int {
                var h = s.haende[p]; let k = h.remove(at: x.0); var ob = oben; ob[x.1] = k
                // Gegner sperren: wie viele Karten der offenen Gegnerhand passen danach noch auf einen Stapel?
                let gegner = s.haende[1 - p].filter { g in ob.contains { $0 != nil && SpitSpeed.nachbar($0!, g) } }.count
                return kette(h, ob, 5) * 10 + folge(x.0, x.1) - gegner * 6
            }
            return wert(a) < wert(b)
        }
    }
}
