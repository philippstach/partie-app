// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Nonogramm {
    public var istKonsistent: Bool {
        guard (2...20).contains(n), loesung.count == n * n, stand.count == n * n, zeilenHinweise.count == n, spaltenHinweise.count == n else { return false }
        // Die Hinweise müssen zur Lösung passen, sonst ist das Rätsel nicht lösbar.
        func laengen(_ idx: [Int]) -> [Int] {
            var r: [Int] = [], l = 0
            for i in idx { if loesung[i] { l += 1 } else if l > 0 { r.append(l); l = 0 } }
            if l > 0 { r.append(l) }
            return r
        }
        func gleich(_ a: [Int], _ b: [Int]) -> Bool { a.filter { $0 > 0 } == b }
        for z in 0..<n {
            guard gleich(zeilenHinweise[z], laengen((0..<n).map { z * n + $0 })), gleich(spaltenHinweise[z], laengen((0..<n).map { $0 * n + z })) else { return false }
        }
        return true
    }
}
