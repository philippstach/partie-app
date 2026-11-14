// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Kartenduell (Krieg): Beide drehen die oberste Karte um, die höhere nimmt beide. Bei Gleichstand gibt es einen „Streit“:
/// Jeder legt drei Karten verdeckt und eine offen, die höhere Karte nimmt alles. Wer alle Karten hat, gewinnt.
public struct Kartenduell: Equatable, Sendable, Codable {
    public static let maxRunden = 400
    public private(set) var stapel: [[Int]]          // [Spieler] Karten (Werte 2…14), die erste ist die oberste
    public private(set) var mitte: [Int] = []
    public private(set) var offen: [Int?] = [nil, nil]
    public private(set) var runden = 0
    public private(set) var streit = 0               // wie oft in Folge Gleichstand
    public private(set) var letzterGewinner: Int?
    public private(set) var sieger: Int?

    public init<G: RandomNumberGenerator>(mit g: inout G) {
        var d = (2...14).flatMap { Array(repeating: $0, count: 4) }
        d.shuffle(using: &g)
        stapel = [Array(d[0..<26]), Array(d[26..<52])]
    }

    /// Feste Stapel (Tests, Wiederaufnahme): erste Karte = oberste.
    public init(stapel: [[Int]]) { precondition(stapel.count == 2); self.stapel = stapel }

    public var kartenGesamt: Int { stapel[0].count + stapel[1].count + mitte.count }

    /// Eine Runde (oder ein Streit-Schritt). Gibt `true` zurück, wenn jemand die Karten bekommen hat.
    @discardableResult
    public mutating func aufdecken<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        guard sieger == nil else { return false }
        for s in 0..<2 where stapel[s].isEmpty { sieger = 1 - s; return false }
        runden += 1
        if streit > 0 {
            // drei verdeckt (so viele wie möglich, mindestens eine bleibt zum Aufdecken)
            for s in 0..<2 { let n = min(3, stapel[s].count - 1); if n > 0 { mitte += stapel[s].prefix(n); stapel[s].removeFirst(n) } }
        }
        let a = stapel[0].removeFirst(), b = stapel[1].removeFirst()
        offen = [a, b]; mitte += [a, b]
        if a == b {
            streit += 1
            if stapel[0].isEmpty || stapel[1].isEmpty { endeBeiGleichstand() }
            return false
        }
        let w = a > b ? 0 : 1
        stapel[w] += mitte.shuffled(using: &g); mitte = []; streit = 0; letzterGewinner = w
        if stapel[1 - w].isEmpty { sieger = w }
        else if runden >= Kartenduell.maxRunden { sieger = stapel[0].count >= stapel[1].count ? 0 : 1 }
        return true
    }

    private mutating func endeBeiGleichstand() {
        sieger = stapel[0].isEmpty && !stapel[1].isEmpty ? 1 : (stapel[1].isEmpty && !stapel[0].isEmpty ? 0 : 0)
    }
}
