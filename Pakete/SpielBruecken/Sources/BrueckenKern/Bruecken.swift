// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct Insel: Equatable, Sendable, Codable { public let x: Int; public let y: Int; public var n: Int }

/// Brücken (Hashi): Verbinde alle Inseln durch waagrechte und senkrechte Brücken (0–2 je Paar), sodass jede Insel genau so viele
/// Brücken hat wie ihre Zahl, nichts sich kreuzt und alles zusammenhängt.
public struct Bruecken: Equatable, Sendable, Codable {
    public let groesse: Int
    public private(set) var inseln: [Insel]
    public private(set) var bruecken: [Paar: Int] = [:]
    public let loesung: [Paar: Int]

    public struct Paar: Hashable, Sendable, Codable {
        public let a: Int, b: Int
        public init(_ i: Int, _ j: Int) { a = min(i, j); b = max(i, j) }
    }

    public init(inseln: [Insel], groesse: Int, loesung: [Paar: Int]) { self.inseln = inseln; self.groesse = groesse; self.loesung = loesung }

    /// Bevorzugt Rätsel mit genau einer Lösung: Bis zu 40 Versuche, danach das letzte (mehrdeutige Rätsel sind spielbar,
    /// denn „gelöst“ prüft die Regeln, nicht die gespeicherte Lösung; der Tipp folgt allerdings der gespeicherten).
    public static func zufaellig<G: RandomNumberGenerator>(groesse: Int = 7, inseln ziel: Int = 10, mit g: inout G) -> Bruecken {
        var letztes = einzeln(groesse: groesse, inseln: ziel, mit: &g)
        var versuche = 0
        while letztes.anzahlLoesungen(grenze: 2) != 1, versuche < 40 { letztes = einzeln(groesse: groesse, inseln: ziel, mit: &g); versuche += 1 }
        return letztes
    }

    static func einzeln<G: RandomNumberGenerator>(groesse: Int = 7, inseln ziel: Int = 10, mit g: inout G) -> Bruecken {
        while true {
            var pos: [(Int, Int)] = [(Int.random(in: 0..<groesse, using: &g), Int.random(in: 0..<groesse, using: &g))]
            var paare: [Paar: Int] = [:]
            var versuche = 0
            func belegt(_ x: Int, _ y: Int) -> Bool { pos.contains { $0.0 == x && $0.1 == y } }
            func aufBruecke(_ x: Int, _ y: Int) -> Bool {
                for (p, _) in paare {
                    let a = pos[p.a], b = pos[p.b]
                    if a.1 == b.1, a.1 == y, x > min(a.0, b.0), x < max(a.0, b.0) { return true }
                    if a.0 == b.0, a.0 == x, y > min(a.1, b.1), y < max(a.1, b.1) { return true }
                }
                return false
            }
            while pos.count < ziel && versuche < 400 {
                versuche += 1
                let i = Int.random(in: 0..<pos.count, using: &g)
                let dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
                let (dx, dy) = dirs.randomElement(using: &g)!
                let len = Int.random(in: 2...4, using: &g)
                let nx = pos[i].0 + dx * len, ny = pos[i].1 + dy * len
                guard (0..<groesse).contains(nx), (0..<groesse).contains(ny) else { continue }
                var frei = !belegt(nx, ny) && !aufBruecke(nx, ny)
                for s in 1..<len { let cx = pos[i].0 + dx * s, cy = pos[i].1 + dy * s; if belegt(cx, cy) || aufBruecke(cx, cy) { frei = false; break } }
                // Pfad darf keine bestehende Brücke kreuzen (aufBruecke deckt das ab)
                guard frei else { continue }
                pos.append((nx, ny))
                paare[Paar(i, pos.count - 1)] = Int.random(in: 1...2, using: &g)
            }
            guard pos.count >= max(5, ziel - 3) else { continue }
            var inselListe = pos.map { Insel(x: $0.0, y: $0.1, n: 0) }
            for (p, c) in paare { inselListe[p.a].n += c; inselListe[p.b].n += c }
            return Bruecken(inseln: inselListe, groesse: groesse, loesung: paare)
        }
    }

    /// Nächste Insel in einer Richtung (ohne dazwischenliegende Insel).
    public func nachbar(von i: Int, dx: Int, dy: Int) -> Int? {
        let s = inseln[i]
        var best: (Int, Int)?
        for (j, t) in inseln.enumerated() where j != i {
            let ddx = t.x - s.x, ddy = t.y - s.y
            guard (dx != 0 && ddy == 0 && ddx * dx > 0) || (dy != 0 && ddx == 0 && ddy * dy > 0) else { continue }
            let d = abs(ddx) + abs(ddy)
            if best == nil || d < best!.1 { best = (j, d) }
        }
        return best?.0
    }

    public func grad(_ i: Int) -> Int { bruecken.reduce(0) { $0 + ($1.key.a == i || $1.key.b == i ? $1.value : 0) } }

    private func kreuzt(_ p: Paar) -> Bool {
        let a = inseln[p.a], b = inseln[p.b]
        let waag = a.y == b.y
        for (q, c) in bruecken where c > 0 && q != p {
            let qa = inseln[q.a], qb = inseln[q.b], qWaag = qa.y == qb.y
            if waag == qWaag { continue }
            if waag {
                if qa.x > min(a.x, b.x), qa.x < max(a.x, b.x), a.y > min(qa.y, qb.y), a.y < max(qa.y, qb.y) { return true }
            } else {
                if a.x > min(qa.x, qb.x), a.x < max(qa.x, qb.x), qa.y > min(a.y, b.y), qa.y < max(a.y, b.y) { return true }
            }
        }
        return false
    }

    /// Schaltet die Brücke zwischen zwei benachbarten Inseln um: 0 → 1 → 2 → 0. Gibt false zurück, wenn sie nicht erlaubt ist.
    @discardableResult
    public mutating func umschalten(_ i: Int, _ j: Int) -> Bool {
        let p = Paar(i, j)
        guard i != j, inseln.indices.contains(i), inseln.indices.contains(j) else { return false }
        let a = inseln[i], b = inseln[j]
        guard (a.x == b.x || a.y == b.y), nachbar(von: i, dx: (b.x - a.x).signum(), dy: (b.y - a.y).signum()) == j else { return false }
        let neu = ((bruecken[p] ?? 0) + 1) % 3
        if neu > 0 {
            var test = self; test.bruecken[p] = neu
            if test.kreuzt(p) { if neu == 1 { return false } }
            if neu == 1, kreuzt(p, mit: self) { return false }
        }
        bruecken[p] = neu == 0 ? nil : neu
        return true
    }

    private func kreuzt(_ p: Paar, mit s: Bruecken) -> Bool { var t = s; t.bruecken[p] = 1; return t.kreuzt(p) }

    public var zahlenErfuellt: Bool { inseln.indices.allSatisfy { grad($0) == inseln[$0].n } }

    public var verbunden: Bool {
        guard !inseln.isEmpty else { return true }
        var besucht: Set<Int> = [0], offen = [0]
        while let k = offen.popLast() {
            for (p, c) in bruecken where c > 0 {
                let n = p.a == k ? p.b : (p.b == k ? p.a : nil)
                if let n, !besucht.contains(n) { besucht.insert(n); offen.append(n) }
            }
        }
        return besucht.count == inseln.count
    }

    public var geloest: Bool { zahlenErfuellt && verbunden }

    /// Tipp: entfernt eine Brücke, die nicht zur Lösung gehört, oder setzt eine fehlende; gibt das Paar zurück.
    @discardableResult
    public mutating func tipp() -> Paar? {
        for (p, c) in bruecken.sorted(by: { ($0.key.a, $0.key.b) < ($1.key.a, $1.key.b) }) where loesung[p] != c {
            bruecken[p] = loesung[p]; return p
        }
        for (p, c) in loesung.sorted(by: { ($0.key.a, $0.key.b) < ($1.key.a, $1.key.b) }) where bruecken[p] != c { bruecken[p] = c; return p }
        return nil
    }

    /// Für Tests und Tipps: übernimmt die gespeicherte Lösung.
    public mutating func loesen() { bruecken = loesung }

    /// Zählt die Lösungen (höchstens `grenze`) per Rückverfolgung über alle Nachbarpaare; eine Insel gilt als fertig, sobald alle ihre Paare entschieden sind.
    public func anzahlLoesungen(grenze: Int) -> Int {
        var paare: [Paar] = []
        for i in inseln.indices {
            for (dx, dy) in [(1, 0), (0, 1)] { if let j = nachbar(von: i, dx: dx, dy: dy) { paare.append(Paar(i, j)) } }
        }
        paare.sort { ($0.a, $0.b) < ($1.a, $1.b) }
        var leer = self
        while let p = leer.bruecken.keys.first { while leer.bruecken[p] != nil { _ = leer.umschalten(p.a, p.b) } }
        var anzahl = 0
        func rec(_ k: Int, _ z: Bruecken) {
            if anzahl >= grenze { return }
            if k == paare.count { if z.geloest { anzahl += 1 }; return }
            let p = paare[k]
            var t = z
            for wert in 0...2 {
                if wert > 0 { guard t.umschalten(p.a, p.b) else { break } }
                if t.grad(p.a) > t.inseln[p.a].n || t.grad(p.b) > t.inseln[p.b].n { continue }
                if (k + 1 == paare.count || paare[k + 1].a > p.a) && t.grad(p.a) != t.inseln[p.a].n { continue }
                rec(k + 1, t)
            }
        }
        rec(0, leer)
        return anzahl
    }
}
