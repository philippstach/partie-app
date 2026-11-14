// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Testing
@testable import SpielGalgenmaennchen

// MARK: zufall.json

struct ZufallTests {
    struct Datei: Decodable {
        struct Fall: Decodable { let seed: String; let next: [String]; let indexVon: [Int]; let index: [Int] }
        let faelle: [Fall]
    }

    @Test func nextUndIndexWieDieReferenz() throws {
        let datei: Datei = try Fixtures.load("zufall")
        #expect(datei.faelle.count >= 5)
        for f in datei.faelle {
            let seed = try #require(UInt64(f.seed))
            var rng = SplitMix64(seed: seed)
            #expect(f.next.map { _ in rng.next() } == f.next.map { UInt64($0)! }, "next, Seed \(f.seed)")
            var rng2 = SplitMix64(seed: seed)
            #expect(f.indexVon.map { rng2.index($0) } == f.index, "index, Seed \(f.seed)")
        }
    }
}

// MARK: normalisierung.json

struct NormalisierungTests {
    struct Datei: Decodable {
        struct Fall: Decodable { let sprache: String; let eingabe: String; let loesung: String?; let fehler: String? }
        let faelle: [Fall]
    }

    static func error(_ code: String) -> WordInputError {
        switch code {
        case "zu_kurz": .tooShort
        case "zu_lang": .tooLong
        default: .invalidCharacter
        }
    }

    @Test func alleFaelle() throws {
        let datei: Datei = try Fixtures.load("normalisierung")
        #expect(datei.faelle.count >= 25)
        for f in datei.faelle {
            let result = WordInput.normalize(f.eingabe, language: WordLanguage(rawValue: f.sprache)!)
            if let loesung = f.loesung {
                #expect(result == .success(loesung), "\(f.sprache) „\(f.eingabe)“")
            } else {
                #expect(result == .failure(Self.error(f.fehler!)), "\(f.sprache) „\(f.eingabe)“")
            }
        }
    }

    @Test func grossschreibungNurUeberTabelle() {
        #expect(Letters.upper("ß") == "ß")
        #expect(Letters.upper("straße äöü") == "STRAßE ÄÖÜ")
        #expect(Letters.upper("i") == "I")
    }
}

// MARK: raten.json

struct RatenTests {
    struct Datei: Decodable {
        struct Schritt: Decodable {
            let aktion: String
            let zeichen: String?
            let eingabe: String?
            let ergebnis: String
            let buchstabe: String?
            let anzeige: String
            let fehler: Int
            let falsche: String
            let hinweise: Int
            let hinweisMoeglich: Bool
            let status: String
        }
        struct Fall: Decodable {
            let name: String; let sprache: String; let loesung: String
            let maxFehler: Int; let seed: UInt64; let schritte: [Schritt]
        }
        let loesenStrafe: Int
        let faelle: [Fall]
    }

    static func result(_ code: String) -> GuessResult {
        switch code {
        case "treffer": .hit
        case "fehler": .miss
        case "schon_geraten": .alreadyGuessed
        case "ungueltig": .invalid
        default: .over
        }
    }

    static func solveResult(_ code: String) -> SolveResult {
        switch code {
        case "geloest": .solved
        case "falsch": .wrong
        case "schon_versucht": .alreadyTried
        case "ungueltig": .invalid
        default: .over
        }
    }

    static func status(_ code: String) -> GameStatus {
        switch code {
        case "gewonnen": .won
        case "verloren": .lost
        default: .playing
        }
    }

    @Test func alleFaelleSchrittFuerSchritt() throws {
        let datei: Datei = try Fixtures.load("raten")
        #expect(datei.faelle.count >= 19)
        #expect(datei.loesenStrafe == Game.solvePenalty)
        for f in datei.faelle {
            var game = Game(solution: f.loesung, language: WordLanguage(rawValue: f.sprache)!, maxMistakes: f.maxFehler)
            var rng = SplitMix64(seed: f.seed)
            for (i, s) in f.schritte.enumerated() {
                let wo = "\(f.name), Schritt \(i + 1)"
                if s.aktion == "hinweis" {
                    let letter = game.hint(using: &rng)
                    #expect(letter.map(String.init) == s.buchstabe, "Hinweis-Buchstabe: \(wo)")
                    #expect((letter != nil) == (s.ergebnis == "ok"), "Hinweis ok: \(wo)")
                } else if s.aktion == "loesen" {
                    #expect(game.solve(s.eingabe ?? "") == Self.solveResult(s.ergebnis), "Lösen: \(wo)")
                } else {
                    #expect(game.guess(s.zeichen ?? "") == Self.result(s.ergebnis), "Ergebnis: \(wo)")
                }
                #expect(game.display == s.anzeige, "Anzeige: \(wo)")
                #expect(game.mistakes == s.fehler, "Fehler: \(wo)")
                #expect(String(game.wrongLetters) == s.falsche, "Falsche: \(wo)")
                #expect(game.hints.count == s.hinweise, "Hinweise: \(wo)")
                #expect(game.canHint == s.hinweisMoeglich, "Hinweis möglich: \(wo)")
                #expect(game.status == Self.status(s.status), "Status: \(wo)")
            }
        }
    }
}

// MARK: auswahl.json

struct AuswahlTests {
    struct Datei: Decodable {
        struct Fall: Decodable {
            let name: String; let sprache: String; let kategorie: String?; let stufe: Int?
            let seed: UInt64; let zuletzt: [String]; let erwartet: [String]
        }
        let zuletztMax: Int
        let faelle: [Fall]
    }

    @Test func alleFaelleGegenDieBundleListe() throws {
        let datei: Datei = try Fixtures.load("auswahl")
        #expect(datei.zuletztMax == WordPicker.recentLimit)
        for f in datei.faelle {
            let language = WordLanguage(rawValue: f.sprache)!
            let list = try WordList.load(language)
            var rng = SplitMix64(seed: f.seed)
            var recent = f.zuletzt
            var picked: [String] = []
            for _ in f.erwartet {
                let word = try #require(WordPicker.pick(
                    from: list.words, category: f.kategorie.flatMap(Category.init),
                    difficulty: f.stufe.flatMap(Difficulty.init), recent: recent, rng: &rng), "\(f.name)")
                picked.append(word.solution)
                recent = WordPicker.remember(word.solution, in: recent)
            }
            #expect(picked == f.erwartet, "\(f.name)")
        }
    }

    @Test func zuletztBegrenztAufZweihundert() {
        let many = (0..<250).map { "W\($0)" }
        var recent: [String] = []
        for w in many { recent = WordPicker.remember(w, in: recent) }
        #expect(recent.count == 200)
        #expect(recent.first == "W50" && recent.last == "W249")
        #expect(WordPicker.remember("W100", in: recent).last == "W100")
        #expect(WordPicker.remember("W100", in: recent).count == 200)
    }
}

// MARK: statistik.json

struct StatistikTests {
    struct Datei: Decodable {
        struct Ereignis: Decodable { let art: String; let stufe: Int; let fehler: Int; let hinweise: Int; let geraten: Int? }
        struct Stufe: Decodable { let gespielt: Int; let gewonnen: Int }
        struct Erwartet: Decodable {
            let gespielt: Int; let gewonnen: Int; let serie: Int; let besteSerie: Int
            let perfekt: Int; let verteilung: [Int]; let jeStufe: [String: Stufe]
        }
        struct Fall: Decodable { let name: String; let ereignisse: [Ereignis]; let erwartet: Erwartet }
        let faelle: [Fall]
    }

    @Test func alleFaelle() throws {
        let datei: Datei = try Fixtures.load("statistik")
        for f in datei.faelle {
            var stats = Stats()
            for e in f.ereignisse {
                let level = Difficulty(rawValue: e.stufe)!
                switch e.art {
                case "gewonnen": stats.record(.won(difficulty: level, mistakes: e.fehler, hints: e.hinweise))
                case "verloren": stats.record(.lost(difficulty: level, mistakes: e.fehler, hints: e.hinweise))
                default: stats.record(.abandoned(difficulty: level, guessedCount: e.geraten ?? 0))
                }
            }
            let x = f.erwartet
            #expect(stats.played == x.gespielt, "\(f.name): gespielt")
            #expect(stats.won == x.gewonnen, "\(f.name): gewonnen")
            #expect(stats.streak == x.serie, "\(f.name): Serie")
            #expect(stats.bestStreak == x.besteSerie, "\(f.name): beste Serie")
            #expect(stats.perfect == x.perfekt, "\(f.name): perfekt")
            #expect(stats.distribution == x.verteilung, "\(f.name): Verteilung")
            for d in Difficulty.allCases {
                let s = x.jeStufe[String(d.rawValue)]!
                #expect(stats[d].played == s.gespielt && stats[d].won == s.gewonnen, "\(f.name): Stufe \(d.rawValue)")
            }
        }
    }
}

// MARK: stufe.json und Wortlisten

struct WortlistenTests {
    struct Datei: Decodable {
        struct Fall: Decodable { let sprache: String; let loesung: String; let stufe: Int }
        let faelle: [Fall]
    }

    @Test func stufeStehtInDerListeWieInDerReferenz() throws {
        let datei: Datei = try Fixtures.load("stufe")
        var lists: [String: [String: Word]] = [:]
        for l in WordLanguage.allCases {
            lists[l.rawValue] = Dictionary(uniqueKeysWithValues: try WordList.load(l).words.map { ($0.solution, $0) })
        }
        #expect(datei.faelle.count == lists.values.reduce(0) { $0 + $1.count })
        for f in datei.faelle {
            let word = try #require(lists[f.sprache]?[f.loesung], "\(f.sprache) \(f.loesung) fehlt in der Liste")
            #expect(word.difficulty.rawValue == f.stufe, "\(f.sprache) \(f.loesung)")
        }
    }

    @Test func jedeLoesungIstGueltigUndJedeKombinationHatDreiWoerter() throws {
        for language in WordLanguage.allCases {
            let list = try WordList.load(language)
            #expect(list.language == language)
            #expect(list.categories.count == Category.allCases.count)
            for w in list.words {
                #expect(WordInput.normalize(w.text, language: language) == .success(w.solution), "\(w.text)")
            }
            for c in Category.allCases {
                for d in Difficulty.allCases {
                    let n = list.words.filter { $0.category == c && $0.difficulty == d }.count
                    #expect(n >= 3, "\(language) \(c) \(d): nur \(n)")
                }
            }
        }
    }
}
