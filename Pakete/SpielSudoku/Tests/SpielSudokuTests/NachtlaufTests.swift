// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSudoku

@Suite("Nachtlauf-Korrekturen")
struct NachtlaufTests {
    @Test func maskeAusserhalbVonEinsBisNeunIstLeer() {
        #expect(Mask.bit(0) == 0)
        #expect(Mask.bit(10) == 0)
        #expect(Mask.bit(1) == 1 && Mask.bit(9) == 0x100)
    }

    @Test func tagesraetselSchluesselUnabhaengigVomGeraetekalender() {
        var buddhistisch = Calendar(identifier: .buddhist)
        buddhistisch.timeZone = TimeZone(identifier: "UTC")!
        var greg = Calendar(identifier: .gregorian)
        greg.timeZone = TimeZone(identifier: "UTC")!
        let datum = Date(timeIntervalSince1970: 1_793_000_000)
        // Standard ist gregorianisch, auch wenn der Gerätekalender ein anderer wäre
        #expect(DailyPuzzle.key(for: datum, calendar: greg).hasPrefix("2026"))
        #expect(DailyPuzzle.key(for: datum, calendar: buddhistisch).hasPrefix("2569"))
        #expect(DailyPuzzle.gregorian.identifier == .gregorian)
        #expect(DailyPuzzle.seed(for: "2026-11-04") == 20_261_104)
    }

    @Test func dailyStreakMitRuhetag() {
        // Heute gelöst, vorgestern gelöst, gestern ausgelassen: Ruhetag, Serie 2
        let s = DailyStreak.compute(solved: ["2026-11-04", "2026-11-02"], today: "2026-11-04")
        #expect(s.length == 2)
        // Zwei Tage ausgelassen: gerissen
        #expect(DailyStreak.compute(solved: ["2026-10-31"], today: "2026-11-04").length == 0)
    }
}
