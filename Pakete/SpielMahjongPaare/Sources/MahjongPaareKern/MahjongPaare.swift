// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct MahjongStein: Equatable, Sendable, Codable {
    public let x: Int       // halbe Steinbreiten
    public let y: Int
    public let ebene: Int
    public var motiv: Int
    public var entfernt = false
}

/// Mahjong-Paare (Solitaire): Gleiche freie Steine paarweise entfernen. Frei = nichts darüber und links oder rechts frei.
/// Das Brett wird rückwärts gefüllt, daher ist jedes Spiel lösbar.
public struct MahjongPaare: Equatable, Sendable, Codable {
    public private(set) var steine: [MahjongStein]
    public private(set) var zuege = 0
    public static let motive = 28

    /// Brettgröße: Anzahl der Ebenen (1 = 36 Steine, 2 = 52, 3 = 56).
    public enum Brett: Int, CaseIterable, Sendable { case klein = 1, mittel = 2, pyramide = 3 }

    static func layout(_ brett: Brett = .pyramide) -> [(Int, Int, Int)] {
        var l: [(Int, Int, Int)] = []
        for e in 0..<brett.rawValue {
            let start = e * 2, ende = 10 - e * 2
            for y in stride(from: start, through: ende, by: 2) { for x in stride(from: start, through: ende, by: 2) { l.append((x, y, e)) } }
        }
        return l
    }

    public init<G: RandomNumberGenerator>(brett: Brett = .pyramide, mit g: inout G) {
        // Rückwärts bauen: Bleibt die Konstruktion stecken (weniger als zwei freie Steine), neu versuchen – nur so ist jedes Brett lösbar.
        var versuch = MahjongPaare.bauen(brett, &g)
        var k = 1
        while versuch.festgefahren, k < 300 { versuch = MahjongPaare.bauen(brett, &g); k += 1 }
        steine = versuch.steine
    }

    private static func bauen<G: RandomNumberGenerator>(_ brett: Brett, _ g: inout G) -> (steine: [MahjongStein], festgefahren: Bool) {
        var steine = MahjongPaare.layout(brett).map { MahjongStein(x: $0.0, y: $0.1, ebene: $0.2, motiv: -1) }
        var motivStapel = (0..<(steine.count / 2)).map { $0 % MahjongPaare.motive }.shuffled(using: &g)
        var rest = Set(steine.indices)
        var zeit: [Bool] = Array(repeating: false, count: steine.count)    // „entfernt“ während der Konstruktion
        while !rest.isEmpty {
            let frei = rest.filter { MahjongPaare.istFrei($0, steine: steine, entfernt: zeit) }.shuffled(using: &g)
            guard frei.count >= 2 else { // Notfall: Rest zufällig verteilen (nur wenn alle Versuche scheitern)
                let l = Array(rest); for (n, i) in l.enumerated() { steine[i].motiv = (n / 2) % MahjongPaare.motive }
                return (steine, true)
            }
            let m = motivStapel.popLast() ?? 0
            steine[frei[0]].motiv = m; steine[frei[1]].motiv = m
            zeit[frei[0]] = true; zeit[frei[1]] = true
            rest.remove(frei[0]); rest.remove(frei[1])
        }
        return (steine, false)
    }

    static func istFrei(_ i: Int, steine: [MahjongStein], entfernt: [Bool]) -> Bool {
        let s = steine[i]
        var links = false, rechts = false
        for (j, t) in steine.enumerated() where j != i && !entfernt[j] {
            if t.ebene == s.ebene + 1, abs(t.x - s.x) < 2, abs(t.y - s.y) < 2 { return false }
            if t.ebene == s.ebene, abs(t.y - s.y) < 2 {
                if t.x == s.x - 2 { links = true }
                if t.x == s.x + 2 { rechts = true }
            }
        }
        return !(links && rechts)
    }

    public func frei(_ i: Int) -> Bool { !steine[i].entfernt && MahjongPaare.istFrei(i, steine: steine, entfernt: steine.map(\.entfernt)) }
    public var verbleibend: Int { steine.filter { !$0.entfernt }.count }
    public var geloest: Bool { verbleibend == 0 }

    public var moeglichePaare: [(Int, Int)] {
        let f = steine.indices.filter(frei)
        var p: [(Int, Int)] = []
        for a in 0..<f.count { for b in (a + 1)..<max(a + 1, f.count) where steine[f[a]].motiv == steine[f[b]].motiv { p.append((f[a], f[b])) } }
        return p
    }
    public var festgefahren: Bool { !geloest && moeglichePaare.isEmpty }

    @discardableResult
    public mutating func entferne(_ a: Int, _ b: Int) -> Bool {
        guard a != b, steine.indices.contains(a), steine.indices.contains(b), frei(a), frei(b), steine[a].motiv == steine[b].motiv else { return false }
        steine[a].entfernt = true; steine[b].entfernt = true; zuege += 1
        return true
    }

    /// Verteilt die Motive der übrigen Steine neu (Paare bleiben vollständig), bis wieder ein Zug möglich ist.
    /// Gibt zurück, ob danach ein Paar frei ist.
    @discardableResult
    public mutating func mischeRest<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        let rest = steine.indices.filter { !steine[$0].entfernt }
        guard rest.count >= 2 else { return false }
        var motive = rest.map { steine[$0].motiv }
        for _ in 0..<200 {
            motive.shuffle(using: &g)
            for (k, i) in rest.enumerated() { steine[i].motiv = motive[k] }
            if !moeglichePaare.isEmpty { return true }
        }
        return !moeglichePaare.isEmpty
    }
}
