// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Wortauswahl nach Spezifikation: Listenreihenfolge, ohne die zuletzt gespielten, sonst die ältere Hälfte.
enum WordPicker {
    static let recentLimit = 200

    static func pick(from words: [Word], category: Category?, difficulty: Difficulty?, recent: [String],
                     rng: inout some RandomNumberGenerator) -> Word? {
        let candidates = words.filter {
            (category == nil || $0.category == category) && (difficulty == nil || $0.difficulty == difficulty)
        }
        guard !candidates.isEmpty else { return nil }

        var fresh = candidates.filter { !recent.contains($0.solution) }
        if fresh.isEmpty {
            // Alle schon gespielt: die länger zurückliegende Hälfte ist wieder erlaubt (mindestens 1)
            let byAge = candidates.sorted { recent.firstIndex(of: $0.solution)! < recent.firstIndex(of: $1.solution)! }
            let allowed = Set(byAge.prefix(max(1, byAge.count / 2)).map(\.solution))
            fresh = candidates.filter { allowed.contains($0.solution) }
        }
        return fresh[rng.index(fresh.count)]
    }

    /// Hängt die Lösung an (ein Duplikat vorher entfernen) und behält höchstens `recentLimit`.
    static func remember(_ solution: String, in recent: [String]) -> [String] {
        Array((recent.filter { $0 != solution } + [solution]).suffix(recentLimit))
    }
}
