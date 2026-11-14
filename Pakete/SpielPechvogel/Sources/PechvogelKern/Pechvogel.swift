// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Pechvogel: Das Paarespiel mit dem schwarzen Schaf unter den Karten. 13 Tierpaare plus ein einzelner Pechvogel.
/// Reihum zieht man verdeckt eine Karte aus der Hand des Nachbarn; Paare werden sofort abgelegt. Wer am Ende den Pechvogel hat, verliert.
public struct Pechvogel: Equatable, Sendable, Codable {
    public static let pechvogel = -1
    public static let paare = 13

    public private(set) var haende: [[Int]]
    public private(set) var amZug = 0
    public private(set) var verlierer: Int?
    public private(set) var letzteAblage: [Int] = []       // zuletzt abgelegte Paare (Motive), für die Anzeige
    public private(set) var gezogen: Int?                  // zuletzt gezogenes Motiv
    public let spieler: Int

    public init<G: RandomNumberGenerator>(spieler: Int, mit g: inout G) {
        self.spieler = max(2, min(4, spieler))
        var d = (0..<Pechvogel.paare).flatMap { [$0, $0] } + [Pechvogel.pechvogel]
        d.shuffle(using: &g)
        haende = Array(repeating: [], count: self.spieler)
        for (i, k) in d.enumerated() { haende[i % self.spieler].append(k) }
        for i in 0..<self.spieler { legePaareAb(i, mit: &g) }
        pruefeEnde()
    }

    /// Feste Hände (Tests, Wiederaufnahme); es wird nichts abgelegt.
    public init(haende: [[Int]], amZug: Int = 0) { self.haende = haende; self.amZug = amZug; spieler = haende.count }

    public var aktive: [Int] { haende.indices.filter { !haende[$0].isEmpty } }

    /// Der Spieler, von dem `amZug` zieht: nächster rechts mit Karten.
    public var nachbar: Int? {
        for s in 1..<spieler { let n = (amZug + s) % spieler; if !haende[n].isEmpty { return n } }
        return nil
    }

    private mutating func legePaareAb<G: RandomNumberGenerator>(_ s: Int, mit g: inout G) {
        var gesehen: [Int: Int] = [:]; var rest: [Int] = []
        for k in haende[s] {
            if k == Pechvogel.pechvogel { rest.append(k); continue }
            if let j = gesehen[k] { _ = j; gesehen[k] = nil; letzteAblage.append(k); rest.removeAll { $0 == k } } else { gesehen[k] = 1; rest.append(k) }
        }
        rest.shuffle(using: &g)
        haende[s] = rest
    }

    private mutating func pruefeEnde() {
        let a = aktive
        if a.count == 1, haende[a[0]] == [Pechvogel.pechvogel] { verlierer = a[0] }
    }

    private mutating func weiter() {
        var n = (amZug + 1) % spieler
        var z = 0
        while haende[n].isEmpty && z < spieler { n = (n + 1) % spieler; z += 1 }
        amZug = n
    }

    /// Der Spieler am Zug zieht die Karte `i` vom Nachbarn.
    @discardableResult
    public mutating func ziehe<G: RandomNumberGenerator>(_ i: Int, mit g: inout G) -> Bool {
        guard verlierer == nil, let n = nachbar, haende[n].indices.contains(i) else { return false }
        letzteAblage = []
        let k = haende[n].remove(at: i)
        gezogen = k
        haende[amZug].append(k)
        legePaareAb(amZug, mit: &g)
        pruefeEnde()
        if verlierer == nil { weiter() }
        return true
    }

    /// Computer: zieht zufällig (leichter Schwierigkeitsgrad), bevorzugt aber manchmal die Mitte, wo oft nichts Verdächtiges liegt.
    public func computerWahl<G: RandomNumberGenerator>(mit g: inout G) -> Int? {
        guard let n = nachbar else { return nil }
        return Int.random(in: 0..<haende[n].count, using: &g)
    }

    public var kartenGesamt: Int { haende.reduce(0) { $0 + $1.count } }
}
