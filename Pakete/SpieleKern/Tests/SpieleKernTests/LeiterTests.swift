// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import Foundation
@testable import SpieleKern

@Suite struct LeiterTests {
    func frisch() -> UserDefaults { let n = "leiter-\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return d }

    @Test func stufeNullIstOffenRestGesperrt() {
        let d = frisch()
        #expect(Leiter.offen("x", stufe: 0, d)); #expect(!Leiter.offen("x", stufe: 1, d)); #expect(!Leiter.offen("x", stufe: 2, d))
        #expect(Leiter.fehlend("x", stufe: 1, d) == Leiter.siegeNoetig)
    }
    @Test func dreiSiegeOeffnenDieNaechsteStufe() {
        let d = frisch()
        for _ in 0..<3 { Leiter.sieg("x", stufe: 0, d) }
        #expect(Leiter.offen("x", stufe: 1, d)); #expect(!Leiter.offen("x", stufe: 2, d))
        #expect(Leiter.hoechste("x", anzahl: 3, d) == 1)
    }
    @Test func tippUndTagesraetselZaehlenNicht() {
        let d = frisch()
        Leiter.sieg("x", stufe: 0, mitTipp: true, d); Leiter.sieg("x", stufe: 0, tages: true, d)
        #expect(Leiter.siege("x", stufe: 0, d) == 0)
    }
    @Test func kinderModusUndSchalterOeffnenAlles() {
        let d = frisch(); d.set(true, forKey: Leiter.kinderKey)
        #expect(Leiter.offen("x", stufe: 2, d))
        let e = frisch(); e.set(true, forKey: Leiter.alleOffenKey)
        #expect(Leiter.offen("x", stufe: 3, e))
    }
    @Test func gesperrteWahlFaelltZurueck() {
        let d = frisch()
        #expect(Leiter.begrenzt("x", stufe: 2, anzahl: 3, d) == 0)
        for _ in 0..<3 { Leiter.sieg("x", stufe: 0, d) }
        #expect(Leiter.begrenzt("x", stufe: 2, anzahl: 3, d) == 1)
        #expect(Leiter.begrenzt("x", stufe: 1, anzahl: 3, d) == 1)
    }
    @Test func zuruecksetzenLeertDieZaehler() {
        let d = frisch(); for _ in 0..<3 { Leiter.sieg("x", stufe: 0, d) }
        Leiter.zuruecksetzen("x", anzahl: 3, d)
        #expect(!Leiter.offen("x", stufe: 1, d))
    }
}
