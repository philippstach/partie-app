// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

/// Weiterspielen nach einem Neustart: Wird die App an beliebiger Stelle beendet und neu geöffnet, geht es exakt dort weiter,
/// ohne Doppelzug und ohne verlorenen Wurf. Der Spielstand wird nach jeder Aktion gespeichert.
@MainActor
@Suite("Neustart")
struct NeustartTests {
    static let spieler = [
        Spieler(name: "A", avatar: "a", strategie: .mensch, sitz: 0, wuerfel: .echt),
        Spieler(name: "B", avatar: "b", strategie: .mensch, sitz: 1, wuerfel: .app),
        Spieler(name: "C", avatar: "c", strategie: .gut, sitz: 2),
        Spieler(name: "D", avatar: "d", strategie: .einfach, sitz: 3),
    ]

    /// Spielt eine Partie zu Ende. `neustartAlle`: nach jeder k-ten Aktion wird der Store neu aus der Datei geladen
    /// (wie nach dem Beenden der App; „Rückgängig“ ist dann leer).
    static func spieleDurch(optionen: Optionen, neustartAlle k: Int?, seed: UInt64 = 31) async -> (Spielzustand, Int) {
        let repo = StoreTests.tempRepo()
        let seedFn: () -> UInt64 = { seed }
        var store = GameStore(repository: repo, seed: seedFn)
        store.neuePartie(spieler: spieler, optionen: optionen)
        var eingaben = SeedQuelle(seed: 5)       // das, was am Tisch gewürfelt wird (außerhalb der App)
        var aktionen = 0, neustarts = 0
        while let z = store.zustand, z.phase != .vorbei, aktionen < 30_000 {
            switch z.phase {
            case .vorWurf:
                if z.erwartetEingabe { store.eintippen(eingaben.naechster()) } else { store.wuerfeln() }
            case .wahl:
                store.ziehe(Computer.entscheide(.gut, z.lage, z.amZug, z.partie.spielzug.erlaubt))
            case .verfallen: store.verfallenWeiter()
            case .computer: await store.computerSchritt()
            case .vorbei: break
            }
            aktionen += 1
            if let k, aktionen % k == 0 {
                store = GameStore(repository: repo, seed: seedFn)       // App neu gestartet
                neustarts += 1
                if store.zustand == nil { Issue.record("Spielstand nach Neustart weg (Aktion \(aktionen))"); break }
            }
        }
        return (store.zustand!, neustarts)
    }

    @Test(arguments: [1, 2, 3, 5, 11])
    func neustartAnJederStelleErgibtDieselbePartie(k: Int) async throws {
        for opt in [Optionen.standard, Spielart.schnell.optionen, Spielart.kinder.optionen] {
            let (glatt, _) = await Self.spieleDurch(optionen: opt, neustartAlle: nil)
            let (mitNeustart, n) = await Self.spieleDurch(optionen: opt, neustartAlle: k)
            #expect(glatt.phase == .vorbei && mitNeustart.phase == .vorbei)
            #expect(n > 5, "es gab wirklich Neustarts")
            #expect(mitNeustart.partie == glatt.partie, "k=\(k): andere Partie nach Neustarts")
            #expect(mitNeustart.quelle == glatt.quelle, "k=\(k): Würfelquelle weicht ab (verlorener oder doppelter Wurf)")
        }
    }

    // MARK: einzelne Lagen

    static func store(_ echt: Bool = false, zweiterIstComputer: Bool = true) -> (GameStore, GameRepository) {
        let repo = StoreTests.tempRepo()
        let store = GameStore(repository: repo, seed: { 12 })
        let sp = [Spieler(name: "A", avatar: "a", strategie: .mensch, sitz: 0, wuerfel: echt ? .echt : .app),
                  Spieler(name: "B", avatar: "b", strategie: zweiterIstComputer ? .gut : .mensch, sitz: 2)]
        store.neuePartie(spieler: sp, optionen: .standard, beginner: 0)
        return (store, repo)
    }

    @Test func nachDemWurfVorDemZugKeinVerlorenerWurf() throws {
        let (store, repo) = Self.store()
        store.wuerfeln()
        let vorher = try #require(store.zustand)
        let neu = GameStore(repository: repo)
        #expect(neu.zustand == vorher)
        #expect(neu.zustand?.partie.spielzug.augen == vorher.partie.spielzug.augen)
        // der Wurf wird nicht noch einmal gewürfelt
        neu.wuerfeln()
        #expect(neu.zustand == vorher)
    }

    @Test func nachDemZugKeinDoppelzug() throws {
        let (store, repo) = Self.store(zweiterIstComputer: false)
        var n = 0
        while store.zustand?.phase != .wahl && n < 100 { StoreTests.menschSchritt(store); n += 1 }
        let z = try #require(store.zustand)
        let zug = z.partie.spielzug.erlaubt[0]
        store.ziehe(zug)
        let danach = try #require(store.zustand)
        let neu = GameStore(repository: repo)
        #expect(neu.zustand == danach)
        // der Zug lässt sich nicht noch einmal ausführen
        neu.ziehe(zug)
        #expect(neu.zustand == danach)
    }

    @Test func mitteImComputerzug() async throws {
        let (store, repo) = Self.store()
        var n = 0
        while store.zustand?.phase != .computer && n < 200 { StoreTests.menschSchritt(store); n += 1 }
        #expect(store.zustand?.phase == .computer)
        await store.computerSchritt()                      // Computer hat gewürfelt
        let mitten = try #require(store.zustand)
        let neu = GameStore(repository: repo)
        #expect(neu.zustand == mitten)
        await neu.computerSchritt()
        await store.computerSchritt()
        #expect(neu.zustand == store.zustand, "beide Computer machen denselben nächsten Schritt")
    }

    @Test func offeneEchtEingabeBleibtOffen() throws {
        let (store, repo) = Self.store(true)
        #expect(store.zustand?.erwartetEingabe == true)
        let neu = GameStore(repository: repo)
        #expect(neu.zustand?.erwartetEingabe == true)
        #expect(neu.zustand?.partie.spielzug.augen == nil, "nichts vorgewählt")
    }

    @Test func aendernFensterNachNeustart() throws {
        let (store, repo) = Self.store(true)
        store.eintippen(4)
        let vorher = try #require(store.zustand)
        #expect(store.kannZuruecknehmen)
        let neu = GameStore(repository: repo)
        #expect(neu.zustand == vorher, "eingetippter Wurf bleibt, nichts geht verloren")
        #expect(!neu.kannZuruecknehmen, "Rückgängig ist nach einem Neustart leer (SPEZ 10)")
        neu.eintippen(2)                                   // schon gewürfelt: kein zweiter Wurf
        #expect(neu.zustand == vorher)
    }

    @Test func endeBildschirmUndStatistikNurEinmal() async throws {
        let (partieZustand, _) = await Self.spieleDurch(optionen: Spielart.schnell.optionen, neustartAlle: nil)
        #expect(partieZustand.phase == .vorbei)
        let repo = StoreTests.tempRepo()
        try repo.speichern(Spielstand(zustand: partieZustand))
        let statURL = FileManager.default.temporaryDirectory.appending(path: "ludo-neustart-stat-\(UUID().uuidString).json")
        // App wird am Ende-Bildschirm beendet und neu geöffnet, Statistik wird gezählt
        var store = GameStore(repository: repo)
        #expect(store.zustand?.phase == .vorbei)
        var stats = StatsStore(url: statURL)
        store.statistikErfassen(in: stats)
        let partien = stats.eintraege.reduce(0) { $0 + $1.partien }
        #expect(partien == 4)
        // noch einmal beenden und öffnen: nicht doppelt zählen
        store = GameStore(repository: repo)
        stats = StatsStore(url: statURL)
        store.statistikErfassen(in: stats)
        #expect(stats.eintraege.reduce(0) { $0 + $1.partien } == partien)
        #expect(store.zustand?.statistikErfasst == true)
    }

    @Test func nachPartieEndeKeinRueckgaengig() async throws {
        let repo = StoreTests.tempRepo()
        let store = GameStore(repository: repo, seed: { 31 })
        store.neuePartie(spieler: Self.spieler, optionen: Spielart.schnell.optionen)
        var eingaben = SeedQuelle(seed: 5)
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
        #expect(store.zustand?.phase == .vorbei)
        #expect(!store.kannZuruecknehmen, "SPEZ 10: nach dem Ende gibt es kein Rückgängig")
    }

    @Test func nachNeustartInWahlMitEinemZugIstEinZugZiehbar() throws {
        // Die Oberfläche zieht nach dem Laden von selbst, wenn genau ein Zug erlaubt ist – dafür muss der Zustand so aussehen
        let (store, repo) = Self.store(zweiterIstComputer: false)
        var n = 0
        while n < 500 {
            n += 1
            guard let z = store.zustand else { break }
            if z.phase == .wahl && z.partie.spielzug.erlaubt.count == 1 {
                let neu = GameStore(repository: repo)
                #expect(neu.zustand?.phase == .wahl)
                #expect(neu.zustand?.partie.spielzug.erlaubt.count == 1)
                #expect(neu.zustand?.aktuellerSpieler.wuerfeltEcht == false)
                return
            }
            StoreTests.menschSchritt(store)
        }
        Issue.record("keine Lage mit genau einem Zug gefunden")
    }
}
