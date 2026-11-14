// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

// MARK: party.json

struct PartyRegelTests {
    struct Datei: Decodable {
        struct Runde: Decodable { let rater: Int; let wortgeber: Int? }
        struct Rollen: Decodable { let spieler: Int; let eigeneWoerter: Bool; let runden: [Runde] }
        struct Punkte: Decodable { let gewonnen: Bool; let fehler: Int; let hinweise: Int; let punkte: Int }
        struct Ergebnis: Decodable { let gewonnen: Bool; let fehler: Int; let hinweise: Int; let stand: [Int] }
        struct Partie: Decodable { let spieler: Int; let eigeneWoerter: Bool; let runden: [Ergebnis]; let rangliste: [Int] }
        struct Rangliste: Decodable { let punkte: [Int]; let plaetze: [Int] }
        let siegSockel: Int
        let wortgeberPunkte: Int
        let rollen: [Rollen]
        let punkte: [Punkte]
        let partie: Partie
        let ranglisten: [Rangliste]
    }

    @Test func konstanten() throws {
        let d: Datei = try Fixtures.load("party")
        #expect(d.siegSockel == PartyMatch.winBase)
        #expect(d.wortgeberPunkte == PartyMatch.giverPoints)
    }

    @Test func rollenJeRunde() throws {
        let d: Datei = try Fixtures.load("party")
        #expect(d.rollen.count >= 6)
        for f in d.rollen {
            for (r, runde) in f.runden.enumerated() {
                #expect(PartyMatch.guesser(round: r, players: f.spieler) == runde.rater,
                        "\(f.spieler) Spieler, Runde \(r): Rater")
                #expect(PartyMatch.giver(round: r, players: f.spieler, ownWords: f.eigeneWoerter) == runde.wortgeber,
                        "\(f.spieler) Spieler, Runde \(r): Wortgeber")
            }
        }
    }

    @Test func punkteJeRunde() throws {
        let d: Datei = try Fixtures.load("party")
        #expect(d.punkte.count >= 7)
        for p in d.punkte {
            #expect(PartyMatch.points(won: p.gewonnen, mistakes: p.fehler, hints: p.hinweise) == p.punkte,
                    "gewonnen \(p.gewonnen), \(p.fehler) Fehler, \(p.hinweise) Hinweise")
        }
    }

    @Test func ganzePartieRundeFuerRunde() throws {
        let d: Datei = try Fixtures.load("party")
        let p = d.partie
        var settings = PartySettings()
        settings.ownWords = p.eigeneWoerter
        settings.roundsPerPlayer = p.runden.count / p.spieler
        var match = PartyMatch(names: (1...p.spieler).map { "S\($0)" }, settings: settings)
        #expect(match.totalRounds == p.runden.count)
        for (i, r) in p.runden.enumerated() {
            match.finishRound(won: r.gewonnen, mistakes: r.fehler, hints: r.hinweise)
            #expect(match.scores == r.stand, "Runde \(i + 1): Stand")
        }
        #expect(match.isFinished)
        #expect(match.places == p.rangliste)
    }

    @Test func ranglistenMitGleichstand() throws {
        let d: Datei = try Fixtures.load("party")
        #expect(d.ranglisten.count >= 5)
        for r in d.ranglisten {
            #expect(PartyMatch.places(r.punkte) == r.plaetze, "\(r.punkte)")
        }
    }
}

// MARK: Store

@MainActor
struct PartyStoreTests {
    private func url() -> URL { FileManager.default.temporaryDirectory.appending(path: "galgen-party-\(UUID()).json") }

    private func makeStore(url: URL) -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        var seed: UInt64 = 1
        return GameStore(repository: GameRepository(url: url), preferences: prefs, seedSource: { defer { seed += 1 }; return seed })
    }

    private func win(_ store: GameStore) {
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
    }

    @Test func eigeneWoerterAblaufUndPunkte() {
        let store = makeStore(url: url())
        store.startParty(names: ["Anna", "Ben", "Clara"], settings: PartySettings())
        #expect(store.screen == .party)
        #expect(store.party?.step == .giverHandover)
        store.partyContinue()                                           // Wortgeber ist bereit
        #expect(store.party?.step == .entry)
        store.submitPartyWord(solution: "KATZE", hintText: "  Tier ")
        #expect(store.party?.step == .guesserHandover)
        #expect(store.party?.game?.hintText == "Tier")
        store.partyContinue()                                           // Rater ist bereit
        #expect(store.screen == .game && store.playingParty)
        #expect(store.game?.mode == .party)
        win(store)                                                      // Anna (Rater 0) ohne Fehler: 10
        #expect(store.party?.scores == [10, 0, 0])
        #expect(store.party?.step == .score)
        #expect(store.stats.played == 0 && store.collected(for: .de).isEmpty)   // zählt nicht in Statistik und Sammlung
        store.nextPartyRound()
        #expect(store.party?.round == 1 && store.party?.guesser == 1 && store.party?.giver == 2)
        #expect(store.party?.step == .giverHandover)
    }

    @Test func verlorenGibtDemWortgeberDreiPunkte() {
        let store = makeStore(url: url())
        store.startParty(names: ["Anna", "Ben"], settings: PartySettings())
        store.partyContinue()
        store.submitPartyWord(solution: "KATZE", hintText: nil)
        store.partyContinue()
        while store.game?.status == .playing {
            let g = store.game!
            store.guess(String(g.language.alphabet.first { !g.solution.contains($0) && !g.guessed.contains($0) }!))
        }
        #expect(store.party?.scores == [0, 3])                          // Wortgeber Ben
    }

    @Test func ganzePartieBisZurRanglisteUndRevanche() {
        var settings = PartySettings()
        settings.ownWords = false
        settings.roundsPerPlayer = 1
        let store = makeStore(url: url())
        store.startParty(names: ["Anna", "Ben"], settings: settings)
        #expect(store.party?.step == .guesserHandover)                  // App-Wörter: keine Eingabe
        for _ in 0..<2 {
            store.partyContinue()
            win(store)
            store.nextPartyRound()
        }
        #expect(store.party?.isFinished == true)
        #expect(store.screen == .party)
        #expect(store.party?.places == PartyMatch.places(store.party!.scores))
        store.rematch()
        #expect(store.party?.round == 0 && store.party?.scores == [0, 0])
        #expect(store.party?.names == ["Anna", "Ben"])
        store.endParty()
        #expect(store.party == nil && store.screen == .home)
    }

    @Test func partieUeberlebtNeustartUndLaeuftNebenEinzelspielUndTageswort() throws {
        let file = url()
        let store = makeStore(url: file)
        store.startGame(category: nil, difficulty: nil)
        let single = try #require(store.game).solution
        store.goHome()
        store.startParty(names: ["Anna", "Ben"], settings: PartySettings())
        store.partyContinue()
        store.submitPartyWord(solution: "KATZE", hintText: nil)
        store.partyContinue()
        store.guess("K")
        store.goHome()
        #expect(store.runningGame?.solution == single)                   // Einzelspiel unberührt

        let reloaded = makeStore(url: file)
        #expect(reloaded.party?.game?.guessed == ["K"])
        #expect(reloaded.runningGame?.solution == single)
        reloaded.resumeParty()
        #expect(reloaded.party?.step == .guesserHandover)               // das Wort bleibt bis zur Übergabe verdeckt
        #expect(reloaded.screen == .party)
        #expect(reloaded.partyNames == ["Anna", "Ben"])
    }

    @Test func aeltererSpielstandOhnePartieLaedt() throws {
        let file = url()
        try Data(#"{"version":1}"#.utf8).write(to: file)
        let store = makeStore(url: file)
        #expect(store.party == nil)
        #expect(store.partyNames.isEmpty)
    }
}
