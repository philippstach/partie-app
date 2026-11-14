// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

@MainActor
@Suite("Verlauf")
struct VerlaufTests {
    static let spieler = [Spieler(name: "Anna", avatar: "a", strategie: .mensch, sitz: 0),
                          Spieler(name: "Ben", avatar: "b", strategie: .gut, sitz: 2)]

    static func beendet(seed: UInt64, optionen: Optionen = Spielart.schnell.optionen) async -> Spielzustand {
        let store = GameStore(repository: StoreTests.tempRepo(), seed: { seed })
        store.neuePartie(spieler: spieler, optionen: optionen)
        await SerieTests.spieleBisEnde(store)
        return store.zustand!
    }

    static func statURL() -> URL { FileManager.default.temporaryDirectory.appending(path: "ludo-vl-\(UUID().uuidString).json") }

    @Test func eintragEnthaeltAlles() async throws {
        let z = await Self.beendet(seed: 1)
        let e = try #require(VerlaufPartie(aus: z, datum: Date(timeIntervalSince1970: 1_700_000_000)))
        #expect(e.spielart == "schnell")
        #expect(e.spieler.count == 2 && e.platzierung == z.partie.platzierung)
        #expect(e.spielzuege == z.partie.verlauf.count)
        #expect(e.rauswuerfe == PartieZaehlung.zaehle(z.partie).map(\.geschlagen))
        #expect(e.augen.count == 2 && e.augen.allSatisfy { $0.count == 6 })
        #expect(e.sieger?.name == z.spieler[z.partie.platzierung[0]].name)
        var eigene = Spielart.kinder.optionen; eigene.figuren = 3
        let z2 = await Self.beendet(seed: 2, optionen: eigene)
        #expect(VerlaufPartie(aus: z2)?.spielart == "eigene")
        // nicht beendete Partien haben keinen Eintrag
        let laufend = Spielzustand(spieler: Self.spieler, optionen: .standard, seed: 3)
        #expect(VerlaufPartie(aus: laufend) == nil)
    }

    @Test func erfasstSpeichertUndBegrenztAuf50() async throws {
        let url = Self.statURL()
        let stats = StatsStore(url: url)
        let z = await Self.beendet(seed: 4)
        for i in 0 ..< 55 { stats.erfasse(z, datum: Date(timeIntervalSince1970: 1_700_000_000 + Double(i) * 100)) }
        #expect(stats.verlauf.count == 50, "höchstens die letzten 50")
        #expect(stats.verlauf.first!.datum > stats.verlauf.last!.datum, "neueste zuerst")
        #expect(stats.verlauf.first!.datum == Date(timeIntervalSince1970: 1_700_000_000 + 54 * 100))
        // wieder laden
        let neu = StatsStore(url: url)
        #expect(neu.verlauf.count == 50 && neu.verlauf.first == stats.verlauf.first)
        // zurücksetzen löscht auch den Verlauf
        neu.zuruecksetzen()
        #expect(neu.verlauf.isEmpty && neu.eintraege.isEmpty)
        #expect(StatsStore(url: url).verlauf.isEmpty)
    }

    @Test func siegquoteDerLetzten10() async throws {
        let z = await Self.beendet(seed: 5)
        let sieger = PartieZaehlung.schluessel(z.spieler[z.partie.platzierung[0]])
        let verlierer = PartieZaehlung.schluessel(z.spieler[1 - z.partie.platzierung[0]])
        var v: [VerlaufPartie] = []
        for i in 0 ..< 14 {
            var e = try #require(VerlaufPartie(aus: z, datum: Date(timeIntervalSince1970: 1_700_000_000 + Double(i))))
            e.id = UUID()
            v.append(e)
        }
        let l = VerlaufAuswertung.letzte10(fuer: sieger, in: v)
        #expect(l.count == 10 && l.allSatisfy { $0 }, "immer gewonnen, nur die letzten 10")
        #expect(VerlaufAuswertung.letzte10(fuer: verlierer, in: v).allSatisfy { !$0 })
        #expect(VerlaufAuswertung.letzte10(fuer: "Unbekannt", in: v).isEmpty)
        // Computer zählen unter ihrer Stufe
        #expect(VerlaufAuswertung.letzte10(fuer: PartieZaehlung.computerGut, in: v).count == 10)
    }

    @Test func dauerOhneLangePausen() async throws {
        let store = GameStore(repository: StoreTests.tempRepo(), seed: { 6 })
        store.neuePartie(spieler: Self.spieler, optionen: .standard)
        for _ in 0 ..< 20 { StoreTests.menschSchritt(store) }
        let d = store.dauerSekunden
        #expect(d >= 0 && d < 5, "20 Aktionen in Millisekunden: kaum Spielzeit")
        // alte Datei ohne Dauer lädt mit 0
        let repo = StoreTests.tempRepo()
        let s2 = GameStore(repository: repo, seed: { 6 })
        s2.neuePartie(spieler: Self.spieler, optionen: .standard)
        let daten = try Data(contentsOf: repo.url)
        var json = try #require(JSONSerialization.jsonObject(with: daten) as? [String: Any])
        json.removeValue(forKey: "dauerSekunden")
        try JSONSerialization.data(withJSONObject: json).write(to: repo.url)
        #expect(GameStore(repository: repo).dauerSekunden == 0)
        // mit Dauer: bleibt über den Neustart erhalten
        try repo.speichern(Spielstand(zustand: try #require(s2.zustand), dauerSekunden: 42.5))
        #expect(GameStore(repository: repo).dauerSekunden == 42.5)
    }

    @Test func neuesteZuerstAuchBeiUnsortiertErfassten() async throws {
        let url = Self.statURL()
        let stats = StatsStore(url: url)
        let z = await Self.beendet(seed: 8)
        let basis = Date(timeIntervalSince1970: 1_700_000_000)
        for tage in [5, 1, 9, 3, 7] { stats.erfasse(z, datum: basis.addingTimeInterval(Double(tage) * 86_400)) }
        let tage = stats.verlauf.map { Int($0.datum.timeIntervalSince(basis) / 86_400) }
        #expect(tage == [9, 7, 5, 3, 1], "neueste Partie zuerst")
        #expect(StatsStore(url: url).verlauf.map { Int($0.datum.timeIntervalSince(basis) / 86_400) } == [9, 7, 5, 3, 1], "auch nach dem Laden")
    }
}
