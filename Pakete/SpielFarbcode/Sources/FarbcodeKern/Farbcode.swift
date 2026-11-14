// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Farbcode: Ein verdeckter Code aus Farbstiften muss in wenigen Versuchen erraten werden.
/// Rückmeldung je Versuch: `genau` = richtige Farbe an der richtigen Stelle, `farbe` = richtige Farbe an falscher Stelle.
public struct Farbcode: Equatable, Sendable, Codable {
    /// Ein Versuch mit seiner Rückmeldung.
    public struct Versuch: Equatable, Sendable, Codable {
        public var tipp: [Int]
        public var antwort: Rueckmeldung
        public init(tipp: [Int], antwort: Rueckmeldung) { self.tipp = tipp; self.antwort = antwort }
    }
    public struct Rueckmeldung: Equatable, Sendable, Codable { public var genau: Int; public var farbe: Int }

    public enum Modus: String, CaseIterable, Sendable, Codable { case leicht, normal, schwer
        public var laenge: Int { switch self { case .leicht: 4; case .normal: 4; case .schwer: 5 } }
        public var farben: Int { switch self { case .leicht: 5; case .normal: 6; case .schwer: 7 } }
        public var versuche: Int { switch self { case .leicht: 10; case .normal: 10; case .schwer: 10 } }
        public var doppelt: Bool { self != .leicht }
    }

    public let modus: Modus
    public let code: [Int]
    public private(set) var versuche: [Versuch] = []
    public private(set) var geloest = false

    public static func == (a: Farbcode, b: Farbcode) -> Bool { a.code == b.code && a.versuche.count == b.versuche.count }

    public init<G: RandomNumberGenerator>(modus: Modus, mit g: inout G) {
        self.modus = modus
        if modus.doppelt { code = (0..<modus.laenge).map { _ in Int.random(in: 0..<modus.farben, using: &g) } }
        else { code = Array((0..<modus.farben).shuffled(using: &g).prefix(modus.laenge)) }
    }

    public init(code: [Int], modus: Modus) { self.code = code; self.modus = modus }

    public var vorbei: Bool { geloest || versuche.count >= modus.versuche }

    public static func bewerte(tipp: [Int], code: [Int]) -> Rueckmeldung {
        let genau = zip(tipp, code).filter { $0 == $1 }.count
        var zaehlTipp: [Int: Int] = [:], zaehlCode: [Int: Int] = [:]
        for (t, c) in zip(tipp, code) where t != c { zaehlTipp[t, default: 0] += 1; zaehlCode[c, default: 0] += 1 }
        let farbe = zaehlTipp.reduce(0) { $0 + min($1.value, zaehlCode[$1.key] ?? 0) }
        return Rueckmeldung(genau: genau, farbe: farbe)
    }

    /// Gibt `true` zurück, wenn der Tipp gültig war.
    @discardableResult
    public mutating func rate(_ tipp: [Int]) -> Bool {
        guard !vorbei, tipp.count == modus.laenge, tipp.allSatisfy({ (0..<modus.farben).contains($0) }) else { return false }
        if !modus.doppelt && Set(tipp).count != tipp.count { return false }
        let r = Farbcode.bewerte(tipp: tipp, code: code)
        versuche.append(Versuch(tipp: tipp, antwort: r))
        if r.genau == modus.laenge { geloest = true }
        return true
    }

    /// Alle Codes, die zu allen bisherigen Rückmeldungen passen.
    public func moeglicheCodes() -> [[Int]] {
        var alle: [[Int]] = [[]]
        for _ in 0..<modus.laenge { alle = alle.flatMap { p in (0..<modus.farben).map { p + [$0] } } }
        if !modus.doppelt { alle = alle.filter { Set($0).count == $0.count } }
        return alle.filter { c in versuche.allSatisfy { Farbcode.bewerte(tipp: $0.tipp, code: c) == $0.antwort } }
    }

    /// Tipp: ein Code, der zu allen bisherigen Rückmeldungen passt.
    public func hinweis<G: RandomNumberGenerator>(mit g: inout G) -> [Int]? { moeglicheCodes().randomElement(using: &g) }
}
