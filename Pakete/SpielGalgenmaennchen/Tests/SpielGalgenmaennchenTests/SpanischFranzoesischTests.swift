// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

/// Eigene Wortlisten für Spanisch und Französisch (ohne Referenz-Fixtures; de/en bleiben unverändert).
struct SpanischFranzoesischTests {
    private let neue: [WordLanguage] = [.es, .fr]

    @Test func listenSindVollstaendigUndGueltig() throws {
        for language in neue {
            let list = try WordList.load(language)
            #expect(list.language == language)
            #expect(list.categories.count == Category.allCases.count)
            var gesehen = Set<String>()
            for w in list.words {
                #expect(WordInput.normalize(w.text, language: language) == .success(w.solution), "\(language) \(w.text)")
                #expect(gesehen.insert(w.solution).inserted, "doppelt: \(w.solution)")
            }
            for c in Category.allCases {
                for d in Difficulty.allCases {
                    let n = list.words.filter { $0.category == c && $0.difficulty == d }.count
                    #expect(n >= 3, "\(language) \(c) \(d): nur \(n)")
                }
            }
            #expect(DailyWord.word(day: "20261106", in: list.words) != nil)
        }
    }

    @Test func eingabeFaltetAkzenteUndBehaeltEnye() {
        #expect(WordInput.normalize("Murciélago", language: .es) == .success("MURCIELAGO"))
        #expect(WordInput.normalize("piña", language: .es) == .success("PIÑA"))
        #expect(WordInput.normalize("PIÑA", language: .es) == .success("PIÑA"))
        #expect(WordInput.normalize("œuf", language: .fr) == .success("OEUF"))
        #expect(WordInput.normalize("garçon", language: .fr) == .success("GARCON"))
        #expect(WordInput.normalize("arc-en-ciel", language: .fr) == .success("ARC-EN-CIEL"))
        #expect(WordInput.normalize("piña", language: .fr) != .success("PIÑA"))   // Ñ gehört nicht zum französischen Alphabet
    }

    @Test func alphabete() {
        #expect(WordLanguage.es.alphabet.contains("Ñ"))
        #expect(WordLanguage.es.alphabet.count == 27)
        #expect(WordLanguage.fr.alphabet.count == 26)
        #expect(WordLanguage.alle.count == 4)
        #expect(WordLanguage.allCases == [.de, .en])      // Referenz-Fixtures bleiben unverändert
    }

    @Test func ratenMitEnyeUndTeilenText() {
        var g = Game(solution: "PIÑA", language: .es)
        #expect(g.guess("ñ") == .hit)
        #expect(g.guess("p") == .hit)
        let t = DailyShare.text(day: "20261106", mistakes: 0, hints: 1, won: true, appLanguage: .fr)
        #expect(t.contains("Mot du jour") && t.contains("1 indice"))
        #expect(DailyShare.text(day: "20261106", mistakes: 2, hints: 0, won: true, appLanguage: .es).contains("2 fallos"))
    }

    @Test func kategorienamenInDerListensprache() throws {
        let es = try WordList.load(.es)
        #expect(es.categoryName(.animals, in: .es) == "Animales")
        let fr = try WordList.load(.fr)
        #expect(fr.categoryName(.music, in: .fr) == "Musique")
    }
}
