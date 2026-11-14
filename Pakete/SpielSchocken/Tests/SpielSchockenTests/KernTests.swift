// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSchocken

@Suite("Kern")
struct KernTests {
    @Test func optionenFehlendeSchluesselBekommenStandard() throws {
        let o = try JSONDecoder().decode(Optionen.self, from: Data(#"{"jule":true}"#.utf8))
        #expect(o == Optionen(jule: true))
        #expect(try JSONDecoder().decode(Optionen.self, from: Data("{}".utf8)) == .standard)
    }

    @Test func seedQuelleIstWiederholbar() {
        var a = SeedQuelle(seed: 42), b = SeedQuelle(seed: 42)
        let folge = (0..<200).map { _ in a.naechster() }
        #expect(folge == (0..<200).map { _ in b.naechster() })
        #expect(folge.allSatisfy { (1...6).contains($0) })
        #expect(Set(folge).count == 6)
    }

    /// Der Vorleger hört nach 1 Wurf auf, dann hat der nächste Spieler nur 1 Wurf und darf nicht weiter.
    @Test func vorlegerBegrenztDieAnderen() {
        var q = ListenQuelle([5, 4, 2,   6, 6, 1,   3, 3, 2])
        var z = Spielzustand(namen: ["A", "B", "C"], strategien: [.mensch, .mensch, .mensch], optionen: .standard, beginner: 0)
        z.wuerfeln(&q)
        #expect(z.phase == .nachWurf)
        z.stehen()
        #expect(z.runde.maxWuerfe == 1)
        #expect(z.aktuellerSpieler == 1)
        z.wuerfeln(&q)
        // B hat nur einen Wurf: Der Zug endet, der Wurf bleibt stehen (zugEnde), erst „Weiter“ geht zu C
        #expect(!z.zugLaeuft)
        #expect(z.phase == .zugEnde)
        #expect(z.aktuellerSpieler == 1)
        #expect(!z.weiter(herauslegen: [], umdrehen: 1, &q))
        z.wuerfeln(&q)                 // im Zugende tut ein Wurf nichts
        #expect(q.verbraucht == 6)
        z.zugWeiter()
        #expect(z.aktuellerSpieler == 2)
        z.wuerfeln(&q)
        z.zugWeiter()
        #expect(z.phase == .rundenwertung)
        #expect(z.runde.ausgang?.verlierer == 2)
    }

    @Test func unerlaubteAktionAendertNichts() {
        var q = ListenQuelle([5, 4, 2, 1, 1, 1])
        var z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .mensch], optionen: .standard, beginner: 0)
        z.wuerfeln(&q)
        let vorher = z
        #expect(!z.weiter(herauslegen: [5], umdrehen: 0, &q))
        #expect(z == vorher)
        #expect(q.verbraucht == 3)
    }

    @Test func zustandRundreiseUndAlteDateiLaedt() throws {
        var q = SeedQuelle(seed: 7)
        var z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .einfach], optionen: Optionen(jule: true), beginner: 0)
        z.wuerfeln(&q)
        let daten = try JSONEncoder().encode(z)
        #expect(try JSONDecoder().decode(Spielzustand.self, from: daten) == z)

        // alte Datei ohne neue Felder (Optionen, Zähler, Strategien, Phase) → Standardwerte
        var json = try #require(JSONSerialization.jsonObject(with: daten) as? [String: Any])
        for k in ["optionen", "zaehler", "strategien", "phase", "haelftenVerlierer"] { json[k] = nil }
        let alt = try JSONDecoder().decode(Spielzustand.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(alt.optionen == .standard)
        #expect(alt.zaehler.schockAus == [0, 0])
        #expect(alt.strategien == [.mensch, .mensch])
        #expect(alt.phase == .vorWurf)
    }

    /// Zugende nach dem letzten Wurf wird gespeichert und nach dem Neustart wieder als „wartet auf Weiter“ geladen.
    @Test func zugEndeUeberlebtSpeichern() throws {
        var q = ListenQuelle([5, 4, 2,   6, 3, 1])
        var z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .mensch], optionen: .standard, beginner: 0)
        z.wuerfeln(&q); z.stehen()
        z.wuerfeln(&q)
        #expect(z.phase == .zugEnde)
        let neu = try JSONDecoder().decode(Spielzustand.self, from: JSONEncoder().encode(z))
        #expect(neu == z)
        #expect(neu.phase == .zugEnde && neu.runde.zug?.fertig == true)
    }

    /// Schnelleingabe (SPEZIFIKATION 15.3): Endergebnis, Würfe und „aus einem Wurf“.
    @Test func schnelleingabe() {
        var z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .mensch], optionen: .standard, beginner: 0,
                             wuerfelModus: [.echt, .echt])
        let zuViele = z.endergebnis(wuerfel: [4, 5, 6], wuerfe: 4)               // mehr Würfe als erlaubt
        #expect(!zuViele)
        let a = z.endergebnis(wuerfel: [4, 5, 6], wuerfe: 2, ausEinemWurf: true)
        #expect(a)
        #expect(z.runde.zuege[0].ergebnis.wertung.art == .strasse)
        #expect(z.runde.maxWuerfe == 2)                                          // der Vorleger legt die Vorgabe fest
        let ueber = z.endergebnis(wuerfel: [1, 2, 3], wuerfe: 3)                 // höchstens die Vorgabe
        #expect(!ueber)
        let b = z.endergebnis(wuerfel: [1, 2, 3], wuerfe: 2, ausEinemWurf: false)
        #expect(b)
        #expect(z.runde.zuege[1].ergebnis.wertung.art == .zahl)                  // nicht aus einem Wurf: Zahl 321
        #expect(z.runde.zuege[1].aktionen.isEmpty)
        #expect(Spielzustand.fragtNachEinemWurf([6, 6, 6], optionen: .standard))
        #expect(!Spielzustand.fragtNachEinemWurf([6, 5, 3], optionen: .standard))
        #expect(z.phase == .rundenwertung && z.runde.ausgang?.verlierer == 1)
    }

    @Test func performanceGutSchwersteLage() {
        // Vorleger, erster Wurf, 3 Würfe frei, nichts draußen
        let lage = Lage(draussen: [], wurf: [4, 3, 2], wuerfe: 1, maxWuerfe: 3,
                        ziel: Ziel(ref: nil, position: 0), optionen: .standard)
        let start = ContinuousClock.now
        _ = Computer.entscheide(.gut, lage)
        let dauer = ContinuousClock.now - start
        #expect(dauer < .milliseconds(500), "Dauer: \(dauer)")      // Debug-Build, Mac unter Last
    }
}

@MainActor
@Suite("GameStore")
struct GameStoreTests {
    private func tempRepo() -> GameRepository {
        GameRepository(url: FileManager.default.temporaryDirectory
            .appending(path: "schocken-test-\(UUID().uuidString)/spielstand.json"))
    }

    @Test func speichernUndLadenMittenImZug() {
        let repo = tempRepo()
        let a = GameStore(repository: repo, seed: 99)
        a.neuePartie(namen: ["A", "B", "C"], strategien: [.mensch, .mensch, .mensch], optionen: .standard)
        a.wuerfeln()
        #expect(a.zustand?.zugLaeuft == true)

        let b = GameStore(repository: repo, seed: 1)
        #expect(b.zustand == a.zustand)
        #expect(b.quelle == a.quelle)
        // beide würfeln gleich weiter
        a.weiter(herauslegen: [], umdrehen: 0)
        b.weiter(herauslegen: [], umdrehen: 0)
        #expect(a.zustand == b.zustand)
    }

    @Test func computerSpieltPartieBisZumEnde() async {
        let repo = tempRepo()
        let s = GameStore(repository: repo, seed: 5)
        s.neuePartie(namen: ["A", "B", "C"], strategien: [.gut, .einfach, .einfach], optionen: .standard)
        var schritte = 0
        while let z = s.zustand, z.phase != .partieVorbei, schritte < 20_000 {
            schritte += 1
            switch z.phase {
            case .computer: await s.computerSchritt()
            case .zugEnde: s.zugWeiter()
            case .rundenwertung: s.rundeWeiter()
            case .haelfteVorbei: s.haelfteWeiter()
            default: Issue.record("unerwartete Phase \(z.phase)"); return
            }
        }
        #expect(s.zustand?.phase == .partieVorbei)
        #expect(s.zustand?.partieVerlierer != nil)
        #expect(GameStore(repository: repo).zustand == s.zustand)
    }
}
