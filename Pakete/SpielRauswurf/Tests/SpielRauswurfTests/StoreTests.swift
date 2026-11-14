// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf
import enum SpieleKern.Avatare

@MainActor
@Suite("GameStore")
struct StoreTests {
    static func spieler(_ strategien: [Strategie]) -> [Spieler] {
        strategien.enumerated().map { i, s in
            Spieler(name: "S\(i)", avatar: Avatare.standard(i), strategie: s, sitz: strategien.count == 2 ? i * 2 : i)
        }
    }

    static func tempRepo() -> GameRepository {
        GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "ludo-\(UUID().uuidString).json"))
    }

    static func store(_ strategien: [Strategie], seed: UInt64 = 7, optionen: Optionen = .standard) -> (GameStore, GameRepository) {
        let repo = tempRepo()
        let store = GameStore(repository: repo, seed: { seed })
        store.neuePartie(spieler: spieler(strategien), optionen: optionen)
        return (store, repo)
    }

    /// Eine Entscheidung eines Menschen mit der Strategie „gut“. `false`, wenn die Partie vorbei ist oder ein Computer dran ist.
    @discardableResult
    static func menschSchritt(_ s: GameStore) -> Bool {
        guard let z = s.zustand else { return false }
        switch z.phase {
        case .vorWurf: s.wuerfeln()
        case .wahl: s.ziehe(Computer.entscheide(.gut, z.lage, z.amZug, z.partie.spielzug.erlaubt))
        case .verfallen: s.verfallenWeiter()
        case .computer, .vorbei: return false
        }
        return true
    }

    static func computerFertig(_ s: GameStore) async {
        while s.zustand?.phase == .computer { await s.computerSchritt() }
    }

    // MARK: Speichern und Laden

    @Test func speichernUndLadenZwischenWurfUndWahl() throws {
        let (store, repo) = Self.store([.mensch, .mensch])
        // bis zum Halt „Wurf gemacht, Zug noch nicht gewählt“ spielen
        var n = 0
        while store.zustand?.phase != .wahl && n < 200 { Self.menschSchritt(store); n += 1 }
        let vorher = try #require(store.zustand)
        #expect(vorher.phase == .wahl)
        #expect(vorher.partie.spielzug.augen != nil)

        let geladen = GameStore(repository: repo)
        #expect(geladen.zustand == vorher)

        // beide machen gleich weiter: gleicher Zug, gleiche nächste Würfel
        for s in [store, geladen] {
            let z = try #require(s.zustand)
            s.ziehe(z.partie.spielzug.erlaubt[0])
            for _ in 0 ..< 20 { Self.menschSchritt(s) }
        }
        #expect(geladen.zustand == store.zustand)
        #expect(GameStore(repository: repo).zustand == store.zustand)
    }

    @Test func speichernUndLadenVorWurfMitFehlversuchen() throws {
        // alle Figuren im Haus: Fehlversuche zählen, Stand bleibt über den Neustart erhalten
        let (store, repo) = Self.store([.mensch, .mensch], seed: 3)
        var n = 0
        while n < 50 {
            guard let z = store.zustand else { break }
            let sp = z.partie.spielzug
            if sp.stand == .verfallen && sp.fehlversuche > 0 {
                let geladen = GameStore(repository: repo)
                #expect(geladen.zustand == z)
                #expect(geladen.zustand?.partie.spielzug.fehlversuche == sp.fehlversuche)
                return
            }
            Self.menschSchritt(store); n += 1
        }
        Issue.record("kein Fehlversuch gefunden")
    }

    @Test func alteDateiOhneNeuesFeldLaedtMitStandard() throws {
        let (store, repo) = Self.store([.mensch, .einfach], optionen: {
            var o = Optionen(); o.schlagpflicht = true; return o
        }())
        let daten = try Data(contentsOf: repo.url)
        var json = try #require(JSONSerialization.jsonObject(with: daten) as? [String: Any])
        var zustand = json["zustand"] as! [String: Any]
        var partie = zustand["partie"] as! [String: Any]
        zustand.removeValue(forKey: "statistikErfasst")
        partie.removeValue(forKey: "verlauf")
        partie.removeValue(forKey: "platzierung")
        var opt = partie["optionen"] as! [String: Any]
        opt.removeValue(forKey: "dreiVersuche")
        opt.removeValue(forKey: "spielende")
        partie["optionen"] = opt
        zustand["partie"] = partie
        json["zustand"] = zustand
        json.removeValue(forKey: "formatVersion")
        try JSONSerialization.data(withJSONObject: json).write(to: repo.url)

        let geladen = GameStore(repository: repo)
        let z = try #require(geladen.zustand)
        #expect(z.statistikErfasst == false)
        #expect(z.partie.verlauf.isEmpty)
        #expect(z.optionen.dreiVersuche == true)
        #expect(z.optionen.spielende == .erster)
        #expect(z.optionen.schlagpflicht == true)          // vorhandene Schlüssel bleiben
        #expect(z.spieler == store.zustand?.spieler)
        // und eine kaputte Datei gibt nichts statt Absturz
        try Data("kaputt".utf8).write(to: repo.url)
        #expect(GameStore(repository: repo).zustand == nil)
    }

    @Test func optionenFehlendeSchluesselStandard() throws {
        let o = try JSONDecoder().decode(Optionen.self, from: Data("{}".utf8))
        #expect(o == .standard)
        let p = try JSONDecoder().decode(Optionen.self, from: Data(#"{"spielende":"alle","unbekannt":1}"#.utf8))
        #expect(p.spielende == .alle && p.rausPflicht)
    }

    // MARK: Rückgängig

    @Test func rueckgaengigGibtDieselbeAugenzahl() throws {
        let (store, _) = Self.store([.mensch, .mensch])
        #expect(!store.kannZuruecknehmen)
        let start = try #require(store.zustand)
        store.wuerfeln()
        let augen = try #require(store.zustand?.partie.spielzug.augen)
        #expect(store.kannZuruecknehmen)
        store.zuruecknehmen()
        #expect(store.zustand == start)
        store.wuerfeln()
        #expect(store.zustand?.partie.spielzug.augen == augen)
    }

    @Test func rueckgaengigAndererZugFuehrtZuAndererLage() throws {
        let (store, _) = Self.store([.mensch, .mensch])
        var n = 0
        while n < 500 {
            n += 1
            guard let z = store.zustand else { break }
            if z.phase == .wahl && z.partie.spielzug.erlaubt.count >= 2 { break }
            Self.menschSchritt(store)
        }
        let vorZug = try #require(store.zustand)
        let erlaubt = vorZug.partie.spielzug.erlaubt
        try #require(erlaubt.count >= 2)
        store.ziehe(erlaubt[0])
        let lageA = try #require(store.zustand?.lage)
        store.zuruecknehmen()
        #expect(store.zustand == vorZug)
        store.ziehe(erlaubt[1])
        #expect(store.zustand?.lage != lageA)
    }

    @Test func rueckgaengigNimmtComputerZuegeUndVerlaufMit() async throws {
        let (store, _) = Self.store([.mensch, .einfach, .gut], seed: 11)
        var snapshot: Spielzustand?
        var runden = 0
        while runden < 8, store.zustand?.phase != .vorbei {
            // der Mensch spielt, bis ein Computer dran ist
            while store.zustand?.phase != .computer && store.zustand?.phase != .vorbei {
                // nur Würfeln und Zug wählen sind Entscheidungen (ein quittierter verfallener Wurf nicht)
                if let ph = store.zustand?.phase, ph == .vorWurf || ph == .wahl { snapshot = store.zustand }
                Self.menschSchritt(store)
            }
            await Self.computerFertig(store)
            runden += 1
            guard store.zustand?.phase != .vorbei else { break }
            #expect(store.kannZuruecknehmen)
            let nachComputer = try #require(store.zustand)
            store.zuruecknehmen()
            #expect(store.zustand == snapshot)
            #expect((store.zustand?.partie.verlauf.count ?? 0) <= nachComputer.partie.verlauf.count)
            // Verlauf endet genau vor der zurückgenommenen Entscheidung: kein Computer-Eintrag danach
            if let letzter = store.zustand?.partie.verlauf.last { #expect(letzter.spieler == 0 || letzter.spieler == 1 || letzter.spieler == 2) }
            // weiter wie vorher
            Self.menschSchritt(store)
            await Self.computerFertig(store)
        }
        #expect(runden > 0)
    }

    @Test func rueckgaengigGesperrtBeiComputerUndStapelHoechstens50() async throws {
        let (store, _) = Self.store([.mensch, .mensch, .mensch, .mensch], seed: 5)
        for _ in 0 ..< 200 { Self.menschSchritt(store) }
        var n = 0
        while store.kannZuruecknehmen { store.zuruecknehmen(); n += 1 }
        #expect(n == GameStore.maxRueckgaengig)

        let (c, _) = Self.store([.mensch, .einfach], seed: 2)
        while c.zustand?.phase != .computer { Self.menschSchritt(c) }
        #expect(!c.kannZuruecknehmen)
        let vorher = c.zustand
        c.zuruecknehmen()
        #expect(c.zustand == vorher)
    }

    @Test func rueckgaengigNachNeustartLeer() throws {
        let (store, repo) = Self.store([.mensch, .mensch])
        store.wuerfeln()
        #expect(store.kannZuruecknehmen)
        #expect(!GameStore(repository: repo).kannZuruecknehmen)
    }

    // MARK: Statistik

    /// Spielt eine ganze Partie mit Menschen-Entscheidungen. Mit `stoeren` wird vor jeder Entscheidung etwas
    /// Falsches getan und wieder zurückgenommen.
    static func partieSpielen(seed: UInt64, stoeren: Bool) -> GameStore {
        let (store, _) = Self.store([.mensch, .mensch, .mensch], seed: seed)
        var n = 0
        while store.zustand?.phase != .vorbei && n < 20_000 {
            n += 1
            if stoeren, let z = store.zustand {
                switch z.phase {
                case .vorWurf:
                    store.wuerfeln(); store.zuruecknehmen()
                case .wahl:
                    if let falsch = z.partie.spielzug.erlaubt.last {
                        var l = z.lage
                        l.fuehreAus(z.amZug, falsch)
                        if l.fertig(z.amZug) { break }          // der Siegzug lässt sich nicht mehr zurücknehmen
                        store.ziehe(falsch); store.zuruecknehmen()
                    }
                default: break
                }
                #expect(store.zustand == z)
            }
            Self.menschSchritt(store)
        }
        return store
    }

    @Test func statistikMitRueckgaengigZaehltNichtDoppelt() throws {
        let a = Self.partieSpielen(seed: 99, stoeren: false)
        let b = Self.partieSpielen(seed: 99, stoeren: true)
        let za = try #require(a.zustand), zb = try #require(b.zustand)
        #expect(za.phase == .vorbei)
        #expect(za.partie.verlauf == zb.partie.verlauf)
        #expect(PartieZaehlung.zaehle(za.partie) == PartieZaehlung.zaehle(zb.partie))
        let z = PartieZaehlung.zaehle(za.partie)
        #expect(z.reduce(0) { $0 + $1.geschlagen } == z.reduce(0) { $0 + $1.rausgeworfen })
        #expect(z.reduce(0) { $0 + $1.geschlagen } > 0)
        #expect(z.reduce(0) { $0 + $1.sechsen } > 0)
    }

    @Test func statistikWirdEinmalErfasst() throws {
        let store = Self.partieSpielen(seed: 42, stoeren: false)
        let url = FileManager.default.temporaryDirectory.appending(path: "ludo-stat-\(UUID().uuidString).json")
        let stats = StatsStore(url: url)
        let z = try #require(store.zustand)
        store.statistikErfassen(in: stats)
        store.statistikErfassen(in: stats)
        #expect(stats.eintraege.count == 3)
        #expect(stats.eintraege.allSatisfy { $0.partien == 1 })
        #expect(stats.eintraege.reduce(0) { $0 + $1.siege } == 1)
        let sieger = try #require(z.partie.platzierung.first)
        let eintrag = try #require(stats.eintraege.first { $0.id == PartieZaehlung.schluessel(z.spieler[sieger]) })
        #expect(eintrag.siege == 1)
        #expect(eintrag.zuegeBisSieg == z.partie.verlauf.filter { $0.spieler == sieger }.count)
        // geladen kommt dasselbe heraus
        #expect(StatsStore(url: url).eintraege.count == 3)
    }

    @Test func abgebrochenePartieZaehltNicht() throws {
        let (store, _) = Self.store([.mensch, .mensch])
        let stats = StatsStore(url: FileManager.default.temporaryDirectory.appending(path: "ludo-stat-\(UUID().uuidString).json"))
        for _ in 0 ..< 10 { Self.menschSchritt(store) }
        store.statistikErfassen(in: stats)
        #expect(stats.eintraege.isEmpty)
    }

    @Test func computerZaehlenAlsStaerke() throws {
        let s = [Spieler(name: "Anna", avatar: "a", strategie: .mensch, sitz: 0),
                 Spieler(name: "Ben", avatar: "b", strategie: .gut, sitz: 1),
                 Spieler(name: "Clara", avatar: "c", strategie: .einfach, sitz: 2)]
        #expect(s.map(PartieZaehlung.schluessel) == ["Anna", PartieZaehlung.computerGut, PartieZaehlung.computerEinfach])
    }
}
