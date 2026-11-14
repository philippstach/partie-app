// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

@Suite("Letzte Runde")
struct LetzteRundeTests {
    @Test func speichernUndLadenMitWuerfelartUndRegeln() throws {
        let suite = "ludo-test-\(UUID().uuidString)"
        let d = try #require(UserDefaults(suiteName: suite))
        defer { d.removePersistentDomain(forName: suite) }
        #expect(LetzteRunde.laden(d) == nil)
        var o = Optionen(); o.figuren = 3; o.rauswerfen = false
        let spieler = [Spieler(name: "Clara", avatar: "c", strategie: .einfach, sitz: 2),
                       Spieler(name: "Anna", avatar: "a", strategie: .mensch, sitz: 0, wuerfel: .echt)]
        LetzteRunde.speichern(spieler: spieler, optionen: o, d)
        let r = try #require(LetzteRunde.laden(d))
        #expect(r.spieler.map(\.name) == ["Anna", "Clara"], "nach Sitz sortiert")
        #expect(r.spieler[0].wuerfel == .echt && r.spieler[0].sitz == 0 && r.spieler[1].strategie == .einfach)
        #expect(r.optionen == o)
        #expect(r.namen == "Anna, Clara")
    }

    @Test func kaputteOderZuKleineDatenGebenNil() throws {
        let suite = "ludo-test-\(UUID().uuidString)"
        let d = try #require(UserDefaults(suiteName: suite))
        defer { d.removePersistentDomain(forName: suite) }
        d.set(Data("kaputt".utf8), forKey: "letzteRundeLudo")
        #expect(LetzteRunde.laden(d) == nil)
        LetzteRunde.speichern(spieler: [Spieler(name: "A", avatar: "a", strategie: .mensch, sitz: 0)], optionen: .standard, d)
        #expect(LetzteRunde.laden(d) == nil, "mindestens zwei Spieler")
    }
}
