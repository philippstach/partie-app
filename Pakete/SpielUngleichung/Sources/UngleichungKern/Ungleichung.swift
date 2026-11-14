// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Ungleichung (Zahlenrätsel im Futoshiki-Stil): Fülle das Quadrat so mit Zahlen, dass in jeder Zeile und Spalte jede Zahl genau einmal steht
/// und alle Kleiner-/Größer-Zeichen zwischen Nachbarfeldern stimmen. Jedes Rätsel hat genau eine Lösung.
public struct Ungleichung: Equatable, Sendable, Codable {
    public struct Zeichen: Equatable, Hashable, Sendable, Codable {
        public var a: Int, b: Int     // Feldindizes; Bedingung: Wert(a) < Wert(b)
    }

    public let n: Int
    public let loesung: [Int]
    public let vorgaben: Set<Int>                 // Felder mit fester Zahl
    public let zeichen: [Zeichen]
    public private(set) var werte: [Int]          // 0 = leer
    private var verlauf: [[Int]] = []             // Stände vor jedem Eintrag, für „Zug zurück“

    public init<G: RandomNumberGenerator>(n: Int, schwer: Bool, mit g: inout G) {
        self.n = n
        // 1. Zufällige lateinische Quadrate per Rückverfolgung
        let sol = Ungleichung.zufallsQuadrat(n, &g)
        loesung = sol
        // 2. Alle Ungleichungen zwischen Nachbarn, dann Hinweise entfernen, solange die Lösung eindeutig bleibt
        var z: [Zeichen] = []
        for y in 0..<n { for x in 0..<n {
            let i = y * n + x
            if x + 1 < n { z.append(sol[i] < sol[i + 1] ? Zeichen(a: i, b: i + 1) : Zeichen(a: i + 1, b: i)) }
            if y + 1 < n { z.append(sol[i] < sol[i + n] ? Zeichen(a: i, b: i + n) : Zeichen(a: i + n, b: i)) }
        } }
        var v = Set<Int>()
        // Eindeutigkeit mit allen Zeichen und keinen Vorgaben sicherstellen
        while Ungleichung.zaehle(n, z, v, sol, max: 2) > 1 { v.insert(Int.random(in: 0..<(n * n), using: &g)) }
        // Hinweise in zufälliger Reihenfolge entfernen
        var kandidaten: [(Bool, Int)] = z.indices.map { (true, $0) } + v.sorted().map { (false, $0) }
        kandidaten.shuffle(using: &g)
        var behalteZ = Array(repeating: true, count: z.count)
        for (istZeichen, idx) in kandidaten {
            if istZeichen {
                behalteZ[idx] = false
                let rest = z.indices.filter { behalteZ[$0] }.map { z[$0] }
                if Ungleichung.zaehle(n, rest, v, sol, max: 2) > 1 { behalteZ[idx] = true }
            } else {
                var v2 = v; v2.remove(idx)
                let rest = z.indices.filter { behalteZ[$0] }.map { z[$0] }
                if Ungleichung.zaehle(n, rest, v2, sol, max: 2) == 1 { v = v2 }
            }
        }
        // Ein leichteres Rätsel bekommt ein paar Zahlen zurück
        var rest = z.indices.filter { behalteZ[$0] }.map { z[$0] }
        _ = rest.count
        var vorg = v
        if !schwer {
            let frei = (0..<(n * n)).filter { !vorg.contains($0) }.shuffled(using: &g)
            for i in frei.prefix(n) { vorg.insert(i) }
        }
        rest = z.indices.filter { behalteZ[$0] }.map { z[$0] }
        zeichen = rest
        vorgaben = vorg
        var w = Array(repeating: 0, count: n * n)
        for i in vorg { w[i] = sol[i] }
        werte = w
    }

    private static func zufallsQuadrat<G: RandomNumberGenerator>(_ n: Int, _ g: inout G) -> [Int] {
        var feld = Array(repeating: 0, count: n * n)
        func fuelle(_ i: Int, _ g: inout G) -> Bool {
            if i == n * n { return true }
            let x = i % n, y = i / n
            for c in (1...n).shuffled(using: &g) {
                if (0..<x).contains(where: { feld[y * n + $0] == c }) || (0..<y).contains(where: { feld[$0 * n + x] == c }) { continue }
                feld[i] = c
                if fuelle(i + 1, &g) { return true }
            }
            feld[i] = 0
            return false
        }
        _ = fuelle(0, &g)
        return feld
    }

    /// Zählt Lösungen (höchstens `max`) für gegebene Zeichen und Vorgaben (Werte aus `sol`).
    /// `knotenGrenze`: Bricht die Suche bei zu vielen Schritten ab und meldet dann vorsichtig „mehr als eine Lösung“ (`grenze`) –
    /// beim Erzeugen bleibt dann der Hinweis stehen. So bleibt die Eindeutigkeit garantiert und die Erzeugung dauert nie Minuten (6×6).
    static func zaehle(_ n: Int, _ zeichen: [Zeichen], _ vorgaben: Set<Int>, _ sol: [Int], max grenze: Int, knotenGrenze: Int = 15_000) -> Int {
        var knoten = 0
        var feld = Array(repeating: 0, count: n * n)
        for i in vorgaben { feld[i] = sol[i] }
        var nach: [[Zeichen]] = Array(repeating: [], count: n * n)
        for z in zeichen { nach[z.a].append(z); nach[z.b].append(z) }
        var gefunden = 0
        func gueltig(_ i: Int, _ c: Int) -> Bool {
            let x = i % n, y = i / n
            for k in 0..<n {
                if k != x, feld[y * n + k] == c { return false }
                if k != y, feld[k * n + x] == c { return false }
            }
            for z in nach[i] {
                let a = z.a == i ? c : feld[z.a], b = z.b == i ? c : feld[z.b]
                if a != 0 && b != 0 && !(a < b) { return false }
            }
            return true
        }
        func suche(_ i: Int) {
            if gefunden >= grenze { return }
            knoten += 1
            if knoten > knotenGrenze { gefunden = grenze; return }
            if i == n * n { gefunden += 1; return }
            if feld[i] != 0 { if gueltig(i, feld[i]) { suche(i + 1) }; return }
            for c in 1...n where gueltig(i, c) {
                feld[i] = c; suche(i + 1); feld[i] = 0
                if gefunden >= grenze { return }
            }
        }
        // Vorgaben müssen untereinander passen
        for i in vorgaben { let c = feld[i]; feld[i] = 0; let ok = gueltig(i, c); feld[i] = c; if !ok { return 0 } }
        suche(0)
        return gefunden
    }

    public mutating func setze(_ i: Int, _ wert: Int) {
        guard werte.indices.contains(i), !vorgaben.contains(i), (0...n).contains(wert), werte[i] != wert else { return }
        verlauf.append(werte); werte[i] = wert
    }

    public var kannZurueck: Bool { !verlauf.isEmpty }
    /// Nimmt den letzten Eintrag (auch einen Tipp) zurück.
    @discardableResult
    public mutating func zurueck() -> Bool {
        guard let alt = verlauf.popLast(), alt.count == werte.count else { return false }
        werte = alt; return true
    }

    public var geloest: Bool { werte == loesung }

    /// Felder, deren Wert gegen die Regeln verstößt (doppelt in Zeile/Spalte oder falsches Zeichen).
    public var fehler: Set<Int> {
        var f = Set<Int>()
        for i in 0..<(n * n) where werte[i] != 0 {
            let x = i % n, y = i / n
            for k in 0..<n {
                if k != x, werte[y * n + k] == werte[i] { f.insert(i) }
                if k != y, werte[k * n + x] == werte[i] { f.insert(i) }
            }
        }
        for z in zeichen where werte[z.a] != 0 && werte[z.b] != 0 && !(werte[z.a] < werte[z.b]) { f.insert(z.a); f.insert(z.b) }
        return f
    }

    /// Tipp: setzt ein leeres oder falsches Feld auf den richtigen Wert; gibt den Index zurück.
    @discardableResult
    public mutating func tipp<G: RandomNumberGenerator>(mit g: inout G) -> Int? {
        let offen = (0..<(n * n)).filter { werte[$0] != loesung[$0] }
        guard let i = offen.randomElement(using: &g) else { return nil }
        verlauf.append(werte); werte[i] = loesung[i]; return i
    }
}
