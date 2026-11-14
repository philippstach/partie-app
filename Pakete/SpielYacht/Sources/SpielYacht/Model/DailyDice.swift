// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Tageswürfel: Für jeden Tag gibt es eine feste Folge von Würfen. Der n-te gezogene Würfel eines Tages ist für alle gleich.
/// Rein und ohne Zufall von außen, damit „Rückgängig“ denselben Wurf wieder liefert.
nonisolated enum DailyDice {
    /// Augenzahl 1…6 des `index`-ten Würfels am Tag `key` („2026-11-04“)
    static func value(key: String, index: Int) -> Int {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in key.utf8 { h = (h ^ UInt64(b)) &* 0x100_0000_01b3 }   // FNV-1a über den Tag
        var z = h &+ UInt64(index) &* 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Int(z % 6) + 1
    }

    /// „2026-11-04“ im gregorianischen Kalender in Ortszeit (unabhängig vom Gerätekalender)
    static func todayKey(_ date: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }
}
