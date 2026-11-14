// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf
import enum SpieleKern.Avatare

@MainActor
@Suite("Code-Durchsicht")
struct CodeDurchsichtTests {
    // MARK: Namen

    @Test func namenLeereUndGleicheWerdenEindeutig() {
        let n = Spielernamen.bereinigt(["Anna", " anna ", "", "Anna", "  "]) { "Spieler \($0)" }
        #expect(n == ["Anna", "anna 2", "Spieler 3", "Anna 3", "Spieler 5"])
        #expect(Set(n.map { $0.lowercased() }).count == n.count)
    }

    @Test func namenUnveraendertWennEindeutig() {
        #expect(Spielernamen.bereinigt(["Anna", "Ben"]) { "Spieler \($0)" } == ["Anna", "Ben"])
    }

    // MARK: Computer „lieb“ über den Store

    /// Computer (Sitz 0) hat die Wahl: Figur 5 → 7 wirft den Menschen (Sitz 2, Figur auf Feld 7) raus, Figur 30 → 32 nicht.
    static func lageMitWahl(computer: Strategie) -> Spielzustand {
        let spieler = [Spieler(name: "Comp", avatar: Avatare.standard(0), strategie: computer, sitz: 0),
                       Spieler(name: "Mensch", avatar: Avatare.standard(1), strategie: .mensch, sitz: 2)]
        let lage = Lage(sitze: [0, 2], figuren: [[5, 30, -1, -1], [27, -1, -1, -1]])
        var partie = Partie(lage: lage, optionen: .standard, amZug: 0, spielzug: Spielzug(spieler: 0))
        partie.eintippen(2)
        return Spielzustand(spieler: spieler, partie: partie, quelle: SeedQuelle(seed: 1))
    }

    @Test func storeComputerLiebSchontMenschen() async throws {
        let store = GameStore(repository: StoreTests.tempRepo(), seed: { 1 })
        store.demoSetzen(Self.lageMitWahl(computer: .lieb), screen: .game)
        #expect(store.zustand?.partie.spielzug.erlaubt.count == 2)
        await store.computerSchritt()
        let danach = try #require(store.zustand)
        #expect(danach.lage.figuren[1][0] == 27, "der Mensch bleibt stehen")
        #expect(danach.lage.figuren[0].contains(32))
    }

    @Test func storeComputerGutWirftRaus() async throws {
        let store = GameStore(repository: StoreTests.tempRepo(), seed: { 1 })
        store.demoSetzen(Self.lageMitWahl(computer: .gut), screen: .game)
        await store.computerSchritt()
        let danach = try #require(store.zustand)
        #expect(danach.lage.figuren[1][0] == Brettmass.haus)
    }
}
