// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Die Spielart eines Sudokus: klassisch 9×9, Kinder-Sudoku 6×6 (Boxen 3×2) oder X-Sudoku (beide Diagonalen enthalten 1–9).
/// Zellen sind 0…(n²−1), Zeile × n + Spalte; Ziffer d ist Bit d−1 einer Maske.
public enum SudokuForm: String, Codable, CaseIterable, Sendable {
    case klassisch, kinder, x

    public var n: Int { self == .kinder ? 6 : 9 }
    public var zellen: Int { n * n }
    /// Höhe einer Box in Zeilen (klassisch 3, Kinder 2)
    public var boxZeilen: Int { self == .kinder ? 2 : 3 }
    /// Breite einer Box in Spalten (immer 3)
    public var boxSpalten: Int { 3 }
    /// Maske aller Ziffern 1…n
    public var alle: UInt16 { UInt16((1 << n) - 1) }
    public var hatDiagonalen: Bool { self == .x }

    public var geometrie: SudokuGeometrie {
        switch self {
        case .klassisch: SudokuGeometrie.klassisch
        case .kinder: SudokuGeometrie.kinder
        case .x: SudokuGeometrie.x
        }
    }

    public static func bit(_ ziffer: Int) -> UInt16 { (1...16).contains(ziffer) ? 1 << UInt16(ziffer - 1) : 0 }

    public func ziffern(_ maske: UInt16) -> [Int] { (1...n).filter { maske & Self.bit($0) != 0 } }
}

/// Zeilen, Spalten, Boxen (und beim X-Sudoku die Diagonalen) als Einheiten, dazu Nachbarn je Zelle.
public struct SudokuGeometrie: Sendable {
    public let form: SudokuForm
    /// 0…n−1 Zeilen, dann n Spalten, dann n Boxen, beim X-Sudoku zuletzt zwei Diagonalen
    public let einheiten: [[Int]]
    /// Nummern der Einheiten je Zelle
    public let einheitenJeZelle: [[Int]]
    /// Zellen, die mit der Zelle eine Einheit teilen (ohne sie selbst)
    public let nachbarn: [[Int]]

    static let klassisch = SudokuGeometrie(.klassisch)
    static let kinder = SudokuGeometrie(.kinder)
    static let x = SudokuGeometrie(.x)

    init(_ form: SudokuForm) {
        self.form = form
        let n = form.n
        var e = [[Int]]()
        e += (0..<n).map { r in (0..<n).map { r * n + $0 } }
        e += (0..<n).map { c in (0..<n).map { $0 * n + c } }
        let bz = form.boxZeilen, bs = form.boxSpalten
        let boxenProZeile = n / bs
        for b in 0..<n {
            let r0 = b / boxenProZeile * bz, c0 = b % boxenProZeile * bs
            e.append((0..<n).map { (r0 + $0 / bs) * n + c0 + $0 % bs })
        }
        if form.hatDiagonalen {
            e.append((0..<n).map { $0 * n + $0 })
            e.append((0..<n).map { $0 * n + (n - 1 - $0) })
        }
        einheiten = e
        var jeZelle = [[Int]](repeating: [], count: n * n)
        for (u, zellen) in e.enumerated() { for z in zellen { jeZelle[z].append(u) } }
        einheitenJeZelle = jeZelle
        nachbarn = (0..<n * n).map { z in
            var s = Set<Int>()
            for u in jeZelle[z] { s.formUnion(e[u]) }
            s.remove(z)
            return s.sorted()
        }
    }

    public func zeile(_ z: Int) -> Int { z / form.n }
    public func spalte(_ z: Int) -> Int { z % form.n }
    /// Box einer Zelle, 0…n−1
    public func box(_ z: Int) -> Int { (z / form.n / form.boxZeilen) * (form.n / form.boxSpalten) + (z % form.n) / form.boxSpalten }
    /// Liegt die Zelle auf einer der Diagonalen (nur X-Sudoku)?
    public func aufDiagonale(_ z: Int) -> Bool {
        guard form.hatDiagonalen else { return false }
        let n = form.n
        return z / n == z % n || z / n + z % n == n - 1
    }
    public func teilen(_ a: Int, _ b: Int) -> Bool { nachbarn[a].contains(b) }
}

/// Reproduzierbarer Zufall (SplitMix64): gleicher Seed, gleiches Rätsel.
public struct SudokuZufall: RandomNumberGenerator, Sendable {
    private var zustand: UInt64
    public init(seed: UInt64) { zustand = seed &+ 0x9E37_79B9_7F4A_7C15 }
    public mutating func next() -> UInt64 {
        zustand &+= 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
