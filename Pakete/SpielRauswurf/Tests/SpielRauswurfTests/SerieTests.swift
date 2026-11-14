// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

@MainActor
@Suite("Serie")
struct SerieTests {
    static func spieleBisEnde(_ store: GameStore) async {
        var eingaben = SeedQuelle(seed: 9)
        var n = 0
        while let z = store.zustand, z.phase != .vorbei, n < 30_000 {
            switch z.phase {
            case .vorWurf: if z.erwartetEingabe { store.eintippen(eingaben.naechster()) } else { store.wuerfeln() }
            case .wahl: store.ziehe(Computer.entscheide(.gut, z.lage, z.amZug, z.partie.spielzug.erlaubt))
            case .verfallen: store.verfallenWeiter()
            case .computer: await store.computerSchritt()
            case .vorbei: break
            }
            n += 1
        }
    }

    static let spieler = [Spieler(name: "A", avatar: "a", strategie: .mensch, sitz: 0),
                          Spieler(name: "B", avatar: "b", strategie: .gut, sitz: 2)]

    @Test func bestOfThreeBisEntschieden() async throws {
        let repo = StoreTests.tempRepo()
        let store = GameStore(repository: repo, seed: { 77 })
        store.neuePartie(spieler: Self.spieler, optionen: Spielart.schnell.optionen, serie: Serie(ziel: 2, spieler: 2))
        var beginner = try #require(store.zustand?.amZug)
        var gewinner: Int?
        var partien = 0
        while partien < 3 {
            await Self.spieleBisEnde(store)
            partien += 1
            let z = try #require(store.zustand)
            let serie = try #require(z.serie)
            #expect(serie.verbucht)
            #expect(serie.partie == partien)
            #expect(serie.siege.reduce(0, +) == partien, "jede beendete Partie zählt einmal")
            #expect(GameStore(repository: repo).zustand?.serie == serie, "Serienstand wird mit dem Spielstand gespeichert")
            if serie.entschieden { gewinner = serie.gewinner; #expect(z.serieEntschieden); break }
            #expect(!z.serieEntschieden)
            store.revanche()                                // nächste Partie der Serie
            let n = try #require(store.zustand)
            #expect(n.serie?.partie == partien + 1 && n.serie?.siege == serie.siege && n.serie?.verbucht == false)
            #expect(n.amZug == (beginner + 1) % 2, "der Beginner wechselt reihum")
            beginner = n.amZug
        }
        let g = try #require(gewinner)
        let finale = try #require(store.zustand?.serie)
        #expect(finale.siege[g] == 2 && finale.siege[1 - g] <= 1)
        #expect(partien >= 2 && partien <= 3)
        // nach entschiedener Serie beginnt „Revanche“ eine neue Serie
        store.revanche()
        #expect(store.zustand?.serie?.siege == [0, 0] && store.zustand?.serie?.partie == 1)
    }

    @Test func einzelpartieHatKeineSerie() async throws {
        let store = GameStore(repository: StoreTests.tempRepo(), seed: { 5 })
        store.neuePartie(spieler: Self.spieler, optionen: Spielart.schnell.optionen)
        await Self.spieleBisEnde(store)
        #expect(store.zustand?.serie == nil && store.zustand?.serieEntschieden == false)
        store.revanche()
        #expect(store.zustand?.serie == nil)
    }

    @Test func abbrechenBeendetDieSerie() async throws {
        let store = GameStore(repository: StoreTests.tempRepo(), seed: { 5 })
        store.neuePartie(spieler: Self.spieler, optionen: .standard, serie: Serie(ziel: 3, spieler: 2))
        #expect(Serie(ziel: 3, spieler: 2).hoechstens == 5)
        store.beenden()
        #expect(store.zustand == nil)
    }

    @Test func alteDateiOhneSerieLaedt() throws {
        let repo = StoreTests.tempRepo()
        let store = GameStore(repository: repo, seed: { 5 })
        store.neuePartie(spieler: Self.spieler, optionen: .standard)
        let daten = try Data(contentsOf: repo.url)
        var json = try #require(JSONSerialization.jsonObject(with: daten) as? [String: Any])
        var z = json["zustand"] as! [String: Any]
        z.removeValue(forKey: "serie")
        json["zustand"] = z
        try JSONSerialization.data(withJSONObject: json).write(to: repo.url)
        #expect(GameStore(repository: repo).zustand?.serie == nil)
    }
}
