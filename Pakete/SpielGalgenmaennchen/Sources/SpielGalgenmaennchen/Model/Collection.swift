// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Fortschritt einer Kategorie: erratene / alle Wörter der Kategorie in der aktuellen Liste
struct CategoryProgress: Equatable, Sendable {
    let found: Int
    let total: Int

    var isComplete: Bool { total > 0 && found >= total }
    var fraction: Double { total > 0 ? Double(found) / Double(total) : 0 }
}

/// Die Wortsammlung: jede erratene Lösung (Einzelspiel und Wort des Tages), ohne Doppelte, in der Reihenfolge der Siege.
enum WordCollection {
    static func add(_ solution: String, to collected: inout [String]) {
        if !collected.contains(solution) { collected.append(solution) }
    }

    /// Wörter, die es in der Liste nicht mehr gibt, bleiben gespeichert, zählen aber nicht.
    static func progress(of collected: [String], in list: WordList) -> [Category: CategoryProgress] {
        let got = Set(collected)
        var result: [Category: CategoryProgress] = [:]
        for category in Category.allCases {
            let words = list.words.filter { $0.category == category }
            result[category] = CategoryProgress(found: words.filter { got.contains($0.solution) }.count, total: words.count)
        }
        return result
    }
}
