// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct LPos: Hashable, Sendable, Codable { public var x: Int; public var y: Int; public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
    func plus(_ r: Richtung) -> LPos { LPos(x + r.dx, y + r.dy) } }

public enum Richtung: CaseIterable, Sendable {
    case hoch, runter, links, rechts
    public var dx: Int { self == .links ? -1 : (self == .rechts ? 1 : 0) }
    public var dy: Int { self == .hoch ? -1 : (self == .runter ? 1 : 0) }
    public var umgekehrt: Richtung { switch self { case .hoch: .runter; case .runter: .hoch; case .links: .rechts; case .rechts: .links } }
}

/// Lagerplatz: Schiebe alle Kisten auf die markierten Plätze. Kisten kann man nur schieben, nicht ziehen, und immer nur eine auf einmal.
/// Die Stufen entstehen durch Rückwärtsspielen aus einer gelösten Stellung und sind deshalb immer lösbar.
public struct Lagerplatz: Equatable, Sendable, Codable {
    public let breite: Int, hoehe: Int
    public let waende: Set<LPos>
    public let ziele: Set<LPos>
    public private(set) var kisten: Set<LPos>
    public private(set) var spieler: LPos
    public private(set) var schritte = 0
    public private(set) var schiebungen = 0
    private struct Schritt: Codable, Equatable, Sendable { var spieler: LPos; var kisten: Set<LPos>; var schob: Bool }
    private var verlauf: [Schritt] = []
    public let stufe: Int

    public static func == (a: Lagerplatz, b: Lagerplatz) -> Bool { a.kisten == b.kisten && a.spieler == b.spieler && a.waende == b.waende && a.ziele == b.ziele }

    public var geloest: Bool { kisten.isSubset(of: ziele) }
    /// Kisten, die in einer Ecke feststecken (zwei angrenzende Wände) und nicht auf einem Zielfeld stehen: Die Stufe ist so nicht mehr lösbar.
    public var festeKisten: [LPos] {
        kisten.filter { k in
            guard !ziele.contains(k) else { return false }
            let waagrecht = waende.contains(k.plus(.links)) || waende.contains(k.plus(.rechts))
            let senkrecht = waende.contains(k.plus(.hoch)) || waende.contains(k.plus(.runter))
            return waagrecht && senkrecht
        }
    }
    public var kistenAufZiel: Int { kisten.intersection(ziele).count }

    public func frei(_ p: LPos) -> Bool { (0..<breite).contains(p.x) && (0..<hoehe).contains(p.y) && !waende.contains(p) }

    @discardableResult
    public mutating func bewege(_ r: Richtung) -> Bool {
        let ziel = spieler.plus(r)
        guard frei(ziel) else { return false }
        var schob = false
        if kisten.contains(ziel) {
            let dahinter = ziel.plus(r)
            guard frei(dahinter), !kisten.contains(dahinter) else { return false }
            verlauf.append(Schritt(spieler: spieler, kisten: kisten, schob: true))
            kisten.remove(ziel); kisten.insert(dahinter); schob = true; schiebungen += 1
        } else { verlauf.append(Schritt(spieler: spieler, kisten: kisten, schob: false)) }
        spieler = ziel; schritte += 1
        _ = schob
        return true
    }

    public var kannZurueck: Bool { !verlauf.isEmpty }

    public mutating func zurueck() {
        guard let l = verlauf.popLast() else { return }
        // Beschädigter Verlauf (alter oder kaputter Spielstand): Schritt verwerfen statt ein unmögliches Lager herzustellen.
        guard l.kisten.count == kisten.count, frei(l.spieler), l.kisten.allSatisfy(frei) else { return }
        spieler = l.spieler; kisten = l.kisten; schritte -= 1; if l.schob { schiebungen -= 1 }
    }

    /// Feste Stufe (Tests, Wiederaufnahme).
    public init(breite: Int, hoehe: Int, waende: Set<LPos> = [], ziele: Set<LPos>, kisten: Set<LPos>, spieler: LPos, stufe: Int = 1) {
        self.breite = breite; self.hoehe = hoehe; self.waende = waende; self.ziele = ziele; self.kisten = kisten; self.spieler = spieler; self.stufe = stufe
    }

    /// Anzahl Kisten je Stufe.
    public static func kistenZahl(stufe: Int) -> Int { min(6, 2 + (stufe - 1) / 2) }

    public init<G: RandomNumberGenerator>(stufe: Int, mit g: inout G) {
        self.stufe = stufe
        let n = Lagerplatz.kistenZahl(stufe: stufe)
        let b = min(10, 6 + stufe / 3), h = min(10, 6 + stufe / 3)
        breite = b; hoehe = h
        while true {
            // Raum mit Außenwand und ein paar Innenwänden
            var w = Set<LPos>()
            for x in 0..<b { w.insert(LPos(x, 0)); w.insert(LPos(x, h - 1)) }
            for y in 0..<h { w.insert(LPos(0, y)); w.insert(LPos(b - 1, y)) }
            for _ in 0..<(2 + stufe / 2) { w.insert(LPos(Int.random(in: 2..<(b - 2), using: &g), Int.random(in: 2..<(h - 2), using: &g))) }
            let innen = (1..<(b - 1)).flatMap { x in (1..<(h - 1)).map { LPos(x, $0) } }.filter { !w.contains($0) }
            guard innen.count > n + 6 else { continue }
            var plaetze = innen.shuffled(using: &g)
            let z = Set(plaetze.prefix(n)); plaetze.removeFirst(n)
            var sp = plaetze.removeFirst()
            var k = z
            // Rückwärts spielen: Spieler läuft herum und zieht Kisten hinter sich her
            let schritteMax = 60 + stufe * 25
            for _ in 0..<schritteMax {
                let r = Richtung.allCases.randomElement(using: &g)!
                let ziel = sp.plus(r)
                guard (0..<b).contains(ziel.x), (0..<h).contains(ziel.y), !w.contains(ziel), !k.contains(ziel) else { continue }
                let hinter = sp.plus(r.umgekehrt)
                if k.contains(hinter) && Bool.random(using: &g) { k.remove(hinter); k.insert(sp) }   // Kiste wird nachgezogen
                sp = ziel
            }
            if k.isSubset(of: z) { continue }     // zu leicht
            // Mindestens eine Kiste muss wirklich verschoben sein; Spieler nicht in einer Kiste
            guard !k.contains(sp) else { continue }
            waende = w; ziele = z; kisten = k; spieler = sp
            return
        }
    }

    /// Nur für Tests: Lösbarkeitsprüfung per Breitensuche über (Spieler, Kisten) mit Zustandsgrenze.
    public func loesbar(maxZustaende: Int = 400_000) -> Bool {
        struct Z: Hashable { var s: LPos; var k: Set<LPos> }
        var gesehen: Set<Z> = [Z(s: spieler, k: kisten)]
        var queue = [Z(s: spieler, k: kisten)]; var i = 0
        while i < queue.count && gesehen.count < maxZustaende {
            let z = queue[i]; i += 1
            if z.k.isSubset(of: ziele) { return true }
            for r in Richtung.allCases {
                let ziel = z.s.plus(r)
                guard frei(ziel) else { continue }
                var k = z.k
                if k.contains(ziel) {
                    let d = ziel.plus(r)
                    guard frei(d), !k.contains(d) else { continue }
                    k.remove(ziel); k.insert(d)
                }
                let nz = Z(s: ziel, k: k)
                if gesehen.insert(nz).inserted { queue.append(nz) }
            }
        }
        return false
    }

    /// Tipp: erster Schritt auf einem kürzesten Weg (in Schritten) zur Lösung von der aktuellen Stellung aus.
    /// Sucht höchstens `maxZustaende` Stellungen; bei großen Stufen kann es ohne Ergebnis enden (nil).
    public func hinweis(maxZustaende: Int = 250_000) -> Richtung? {
        if geloest { return nil }
        struct Z: Hashable { var s: LPos; var k: Set<LPos> }
        let start = Z(s: spieler, k: kisten)
        var gesehen: Set<Z> = [start]
        var queue: [(Z, Richtung)] = []
        var i = 0
        func erweitere(_ z: Z, _ erster: Richtung?) -> Richtung? {
            for r in Richtung.allCases {
                let ziel = z.s.plus(r)
                guard frei(ziel) else { continue }
                var k = z.k
                if k.contains(ziel) {
                    let d = ziel.plus(r)
                    guard frei(d), !k.contains(d) else { continue }
                    k.remove(ziel); k.insert(d)
                }
                let nz = Z(s: ziel, k: k)
                guard gesehen.insert(nz).inserted else { continue }
                let e = erster ?? r
                if nz.k.isSubset(of: ziele) { return e }
                queue.append((nz, e))
            }
            return nil
        }
        if let e = erweitere(start, nil) { return e }
        while i < queue.count && gesehen.count < maxZustaende {
            let (z, e) = queue[i]; i += 1
            if let f = erweitere(z, e) { return f }
        }
        return nil
    }
}
