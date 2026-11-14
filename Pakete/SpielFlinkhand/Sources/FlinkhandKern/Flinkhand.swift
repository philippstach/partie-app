// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Flinkhand (Schnipp-Schnapp): Reihum legt jeder die oberste Karte auf die Mitte. Liegen zwei gleiche Motive aufeinander,
/// ruft wer zuerst „Schnapp!“ ruft und bekommt den ganzen Stapel. Wer zu Unrecht ruft, gibt eine Karte in die Mitte.
public struct Flinkhand: Equatable, Sendable, Codable {
    public static let motive = 12
    public private(set) var haende: [[Int]]
    public private(set) var mitte: [Int] = []
    public private(set) var amZug = 0
    public private(set) var sieger: Int?
    public let spieler: Int
    public private(set) var meldung = ""
    private var zuletzt = 0

    public init<G: RandomNumberGenerator>(spieler: Int, mit g: inout G) {
        self.spieler = max(2, min(4, spieler))
        var d = (0..<Flinkhand.motive).flatMap { Array(repeating: $0, count: 4) }
        d.shuffle(using: &g)
        haende = Array(repeating: [], count: self.spieler)
        for (i, k) in d.enumerated() { haende[i % self.spieler].append(k) }
    }

    public var kartenGesamt: Int { haende.reduce(0) { $0 + $1.count } + mitte.count }
    public var passt: Bool { mitte.count >= 2 && mitte[mitte.count - 1] == mitte[mitte.count - 2] }
    public var aktive: [Int] { haende.indices.filter { !haende[$0].isEmpty } }

    /// Nur für Tests: feste Verteilung der Karten.
    public init(haende: [[Int]], mitte: [Int] = [], amZug: Int = 0) {
        self.haende = haende; self.mitte = mitte; self.amZug = amZug; spieler = haende.count
    }

    /// Der Spieler am Zug legt seine oberste Karte.
    public mutating func lege() {
        guard sieger == nil, !haende[amZug].isEmpty else { return }
        zuletzt = amZug
        mitte.append(haende[amZug].removeFirst())
        weiter()
    }

    private mutating func weiter() {
        var n = (amZug + 1) % spieler; var z = 0
        while haende[n].isEmpty && z < spieler { n = (n + 1) % spieler; z += 1 }
        amZug = n
        pruefeSieger()
    }

    private mutating func pruefeSieger() {
        let a = aktive
        if a.count == 1 && mitte.isEmpty { sieger = a[0] }
        else if a.isEmpty { sieger = zuletzt }     // alle Karten liegen in der Mitte: wer zuletzt gelegt hat, hielt sie alle
    }

    /// „Schnapp!“ von Spieler `s`. `true`, wenn berechtigt.
    @discardableResult
    public mutating func schnapp(_ s: Int) -> Bool {
        guard sieger == nil else { return false }
        if passt {
            haende[s] += mitte; mitte = []; amZug = s
            if haende[s].isEmpty { weiter() }
            meldung = ""
            pruefeSieger()
            return true
        }
        if !haende[s].isEmpty { mitte.insert(haende[s].removeFirst(), at: 0) }   // Strafe: unter den Stapel
        pruefeSieger()
        return false
    }
}
