// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct SPos: Hashable, Sendable, Codable { public var x: Int; public var y: Int; public init(_ x: Int, _ y: Int) { self.x = x; self.y = y } }
public struct SZug: Equatable, Sendable { public var von: SPos; public var ueber: SPos; public var nach: SPos }

/// Steckspiel (Steckhalma / Solitär mit Steckern): Springe mit einem Stecker waagrecht oder senkrecht über einen Nachbarn in ein leeres Loch; der übersprungene Stecker wird entfernt.
/// Ziel: möglichst wenige Stecker übrig lassen, am besten nur einen.
public struct Steckspiel: Equatable, Sendable, Codable {
    public enum Brett: String, CaseIterable, Sendable, Codable {
        case kreuz, europa
        /// '#' = Loch, '.' = kein Loch. Mittelloch ist leer.
        public var muster: [String] {
            switch self {
            case .kreuz: ["..###..", "..###..", "#######", "#######", "#######", "..###..", "..###.."]
            case .europa: ["..###..", ".#####.", "#######", "#######", "#######", ".#####.", "..###.."]
            }
        }
        public var titel: String { switch self { case .kreuz: "Kreuz"; case .europa: "Europa" } }
    }

    public let brett: Brett
    public let loecher: Set<SPos>
    public private(set) var stecker: Set<SPos>
    private var verlauf: [Set<SPos>] = []
    public private(set) var zuege = 0

    public init(brett: Brett) {
        self.brett = brett
        var l = Set<SPos>(), s = Set<SPos>()
        for (y, zeile) in brett.muster.enumerated() { for (x, c) in zeile.enumerated() where c == "#" { l.insert(SPos(x, y)); s.insert(SPos(x, y)) } }
        let mitte = SPos(brett.muster[0].count / 2, brett.muster.count / 2)
        s.remove(mitte)
        loecher = l; stecker = s
    }

    public static func == (a: Steckspiel, b: Steckspiel) -> Bool { a.brett == b.brett && a.stecker == b.stecker }

    public var uebrig: Int { stecker.count }

    public func zuege(von p: SPos? = nil) -> [SZug] {
        var z: [SZug] = []
        for s in stecker where p == nil || p == s {
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let u = SPos(s.x + dx, s.y + dy), n = SPos(s.x + 2 * dx, s.y + 2 * dy)
                if stecker.contains(u), loecher.contains(n), !stecker.contains(n) { z.append(SZug(von: s, ueber: u, nach: n)) }
            }
        }
        return z
    }

    public var festgefahren: Bool { zuege().isEmpty }

    @discardableResult
    public mutating func ziehe(_ z: SZug) -> Bool {
        guard zuege(von: z.von).contains(z) else { return false }
        verlauf.append(stecker)
        stecker.remove(z.von); stecker.remove(z.ueber); stecker.insert(z.nach); zuege += 1
        return true
    }

    /// Tipp: der Zug, nach dem die meisten weiteren Züge möglich bleiben (Stecker nahe der Mitte werden bevorzugt, Randstecker zuletzt).
    public func hinweis() -> SZug? {
        let mitteX = Double(brett.muster[0].count - 1) / 2, mitteY = Double(brett.muster.count - 1) / 2
        func wert(_ z: SZug) -> Double {
            var k = self; k.ziehe(z)
            let beweglich = Double(k.zuege().count)
            let rand = abs(Double(z.nach.x) - mitteX) + abs(Double(z.nach.y) - mitteY)
            return beweglich * 2 - rand * 0.3 + (k.festgefahren && k.uebrig > 1 ? -50 : 0)
        }
        return zuege().max { wert($0) < wert($1) }
    }

    public var kannZurueck: Bool { !verlauf.isEmpty }
    public mutating func zurueck() { if let s = verlauf.popLast() { stecker = s; zuege -= 1 } }

    /// Bewertung nach Spielende: 1 Stecker = „Meister“.
    public var rang: Int { switch uebrig { case 1: 4; case 2: 3; case 3...4: 2; case 5...7: 1; default: 0 } }
    public static let rangNamen = ["Anfänger", "Tüftler", "Kenner", "Könner", "Meister"]
    public var punkte: Int { max(0, (loecher.count - 1 - uebrig) * 10) + (uebrig == 1 ? 100 : 0) }
}
