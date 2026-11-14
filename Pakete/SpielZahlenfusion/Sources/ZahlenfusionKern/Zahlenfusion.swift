// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public enum FusionRichtung: Sendable { case links, rechts, oben, unten }

/// Zahlenfusion (2048-Art): Kacheln schieben, gleiche verschmelzen.
public struct Zahlenfusion: Equatable, Sendable, Codable {
    /// Kantenlänge des Feldes: 4 klassisch, 3 bis 6 als Varianten.
    public let n: Int
    public private(set) var feld: [Int]
    public private(set) var punkte = 0

    public init(n: Int = 4) { self.n = n; feld = [Int](repeating: 0, count: n * n) }

    private enum CodingKeys: String, CodingKey { case n, feld, punkte }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        feld = try c.decode([Int].self, forKey: .feld)
        n = try c.decodeIfPresent(Int.self, forKey: .n) ?? 4
        punkte = try c.decodeIfPresent(Int.self, forKey: .punkte) ?? 0
    }

    public var hoechste: Int { feld.max() ?? 0 }
    public var erreicht2048: Bool { hoechste >= 2048 }
    public var vorbei: Bool { !feld.contains(0) && Zahlenfusion.richtungen.allSatisfy { !kannBewegen($0) } }
    static let richtungen: [FusionRichtung] = [.links, .rechts, .oben, .unten]

    public mutating func neueKachel<G: RandomNumberGenerator>(mit g: inout G) {
        guard let i = feld.indices.filter({ feld[$0] == 0 }).randomElement(using: &g) else { return }
        feld[i] = Int.random(in: 0..<10, using: &g) == 0 ? 4 : 2
    }

    /// Linien (Index-Listen) in Schieberichtung, jeweils vom Ziel zum Rand.
    private func linien(_ r: FusionRichtung) -> [[Int]] {
        return (0..<n).map { k in
            (0..<n).map { j in
                switch r {
                case .links: return k * n + j
                case .rechts: return k * n + (n - 1 - j)
                case .oben: return j * n + k
                case .unten: return (n - 1 - j) * n + k
                }
            }
        }
    }

    private func schiebe(_ werte: [Int]) -> (zeile: [Int], punkte: Int) {
        var rest = werte.filter { $0 != 0 }, erg: [Int] = [], p = 0
        while !rest.isEmpty {
            let a = rest.removeFirst()
            if let b = rest.first, a == b { rest.removeFirst(); erg.append(a * 2); p += a * 2 } else { erg.append(a) }
        }
        return (erg + Array(repeating: 0, count: werte.count - erg.count), p)
    }

    public func kannBewegen(_ r: FusionRichtung) -> Bool {
        for l in linien(r) {
            if schiebe(l.map { feld[$0] }).zeile != l.map({ feld[$0] }) { return true }
        }
        return false
    }

    /// Bewegt das Feld; gibt zurück, ob sich etwas geändert hat (dann kommt eine neue Kachel dazu).
    @discardableResult
    public mutating func bewege<G: RandomNumberGenerator>(_ r: FusionRichtung, mit g: inout G) -> Bool {
        guard kannBewegen(r) else { return false }
        for l in linien(r) {
            let res = schiebe(l.map { feld[$0] })
            for (j, i) in l.enumerated() { feld[i] = res.zeile[j] }
            punkte += res.punkte
        }
        neueKachel(mit: &g)
        return true
    }

    /// Vorschau eines Zuges ohne neue Kachel: das Feld danach und die Punkte; `nil`, wenn der Zug nichts bewegt.
    public func vorschau(_ r: FusionRichtung) -> (feld: [Int], punkte: Int)? {
        guard kannBewegen(r) else { return nil }
        var f = feld, p = 0
        for l in linien(r) {
            let res = schiebe(l.map { feld[$0] })
            for (j, i) in l.enumerated() { f[i] = res.zeile[j] }
            p += res.punkte
        }
        return (f, p)
    }

    /// Tipp: die Richtung mit den meisten Verschmelzungspunkten; bei Gleichstand die mit mehr freien Feldern, dann mit der größten
    /// Kachel in einer Ecke. `nil`, wenn kein Zug möglich ist.
    public var tippRichtung: FusionRichtung? {
        var beste: (r: FusionRichtung, wert: Int)?
        for r in Zahlenfusion.richtungen {
            guard let v = vorschau(r) else { continue }
            let leer = v.feld.filter { $0 == 0 }.count
            let hoechste = v.feld.max() ?? 0
            let ecke = [0, n - 1, n * (n - 1), n * n - 1].contains { v.feld[$0] == hoechste } ? 1 : 0
            let wert = v.punkte * 10_000 + leer * 100 + ecke * 10
            if beste == nil || wert > beste!.wert { beste = (r, wert) }
        }
        return beste?.r
    }

    public mutating func setze(_ f: [Int]) { feld = f }
}
