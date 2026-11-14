// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

struct Cell: Codable, Equatable, Sendable {
    var value: UInt8 = 0
    var isGiven = false
    /// Notizen als Bitmaske (Ziffer d = Bit d−1)
    var notes: UInt16 = 0

    var isEmpty: Bool { value == 0 }

    init(value: UInt8 = 0, isGiven: Bool = false, notes: UInt16 = 0) {
        self.value = value; self.isGiven = isGiven; self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let report = decoder.loadReport
        value = c.lenient(UInt8.self, .value, default: 0, report: report)
        isGiven = c.lenient(Bool.self, .isGiven, default: false, report: report)
        notes = c.lenient(UInt16.self, .notes, default: 0, report: report)
    }
}

/// Das Spielfeld: 81 Zellen mit Wert, Vorgabe-Flag und Notizen.
struct Board: Codable, Equatable, Sendable {
    var cells: [Cell]

    init(puzzle: Puzzle) {
        cells = puzzle.givens.map { Cell(value: $0, isGiven: $0 != 0) }
    }

    var values: [UInt8] { cells.map(\.value) }
    var filledCount: Int { cells.filter { !$0.isEmpty }.count }
    var isFull: Bool { filledCount == 81 }

    /// Wie oft die Ziffer schon im Feld steht
    func count(of digit: Int) -> Int { cells.filter { Int($0.value) == digit }.count }

    /// Zellen mit einer Zahl, die in Zeile, Spalte oder Box ein zweites Mal vorkommt
    func conflicts() -> Set<Int> {
        var result = Set<Int>()
        for unit in Units.all {
            var seen = [Int: Int]()
            for i in unit where cells[i].value != 0 {
                let d = Int(cells[i].value)
                if let first = seen[d] { result.insert(first); result.insert(i) } else { seen[d] = i }
            }
        }
        return result
    }

    /// Ist die Einheit voll und ohne doppelte Zahl?
    func isUnitComplete(_ unit: [Int]) -> Bool {
        var mask: UInt16 = 0
        for i in unit {
            guard cells[i].value != 0 else { return false }
            mask |= Mask.bit(Int(cells[i].value))
        }
        return mask == Mask.all
    }

    /// Alle möglichen Zahlen einer leeren Zelle (nach den Regeln, nicht nach der Lösung)
    func candidates(for index: Int) -> UInt16 {
        guard cells[index].isEmpty else { return 0 }
        var used: UInt16 = 0
        for p in Units.peers[index] where cells[p].value != 0 { used |= Mask.bit(Int(cells[p].value)) }
        return ~used & Mask.all
    }
}
