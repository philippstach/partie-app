// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zeilen, Spalten, Boxen und Nachbarn des 9×9-Gitters. Zellen sind 0…80 (Zeile × 9 + Spalte).
enum Units {
    static let rows: [[Int]] = (0..<9).map { r in (0..<9).map { r * 9 + $0 } }
    static let cols: [[Int]] = (0..<9).map { c in (0..<9).map { $0 * 9 + c } }
    static let boxes: [[Int]] = (0..<9).map { b in
        let r0 = b / 3 * 3, c0 = b % 3 * 3
        return (0..<9).map { (r0 + $0 / 3) * 9 + c0 + $0 % 3 }
    }

    /// Alle 27 Einheiten: 0–8 Zeilen, 9–17 Spalten, 18–26 Boxen.
    static let all: [[Int]] = rows + cols + boxes

    static func row(_ i: Int) -> Int { i / 9 }
    static func col(_ i: Int) -> Int { i % 9 }
    static func box(_ i: Int) -> Int { (i / 27) * 3 + (i % 9) / 3 }

    /// Die 20 Zellen, die mit der Zelle eine Zeile, Spalte oder Box teilen.
    static let peers: [[Int]] = (0..<81).map { i in
        var set = Set(rows[row(i)] + cols[col(i)] + boxes[box(i)])
        set.remove(i)
        return set.sorted()
    }

    /// Zeile, Spalte und Box einer Zelle (Einheiten-Nummern 0…26).
    static func units(of i: Int) -> [Int] { [row(i), 9 + col(i), 18 + box(i)] }
}

/// Bitmasken für Ziffern: Ziffer d (1–9) ist Bit d−1.
enum Mask {
    static let all: UInt16 = 0x1FF
    static func bit(_ digit: Int) -> UInt16 { (1...9).contains(digit) ? 1 << UInt16(digit - 1) : 0 }
    static func digits(_ mask: UInt16) -> [Int] { (1...9).filter { mask & bit($0) != 0 } }
}
