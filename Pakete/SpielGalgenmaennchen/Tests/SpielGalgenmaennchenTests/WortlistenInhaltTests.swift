// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

/// Inhalt der eingebauten Wortlisten in allen vier Sprachen: Zeichen, Doppelte, Abdeckung je Stufe/Kategorie/Länge und ein Filter für anstößige Wörter.
struct WortlistenInhaltTests {
    private let sprachen: [WordLanguage] = [.de, .en, .es, .fr]

    /// Mindestmenge je Sprache (de/en sind groß, es/fr kleiner).
    private func mindestensJeKategorieUndStufe(_ s: WordLanguage) -> Int { (s == .de || s == .en) ? 10 : 3 }

    @Test func nurBuchstabenDesAlphabetsPlusLeerzeichenUndBindestrich() throws {
        for s in sprachen {
            let list = try WordList.load(s)
            let erlaubt = Set(s.alphabet).union(Letters.open)
            for w in list.words {
                #expect(w.solution.allSatisfy { erlaubt.contains($0) }, "\(s) \(w.text) → \(w.solution)")
                #expect(w.solution == w.solution.trimmingCharacters(in: .whitespaces), "Leerraum am Rand: \(w.text)")
                #expect(!w.solution.contains("  "), "doppeltes Leerzeichen: \(w.text)")
                #expect(w.solution.count >= 3, "zu kurz: \(w.text)")
                #expect(s.alphabet.contains(w.solution.first!) && s.alphabet.contains(w.solution.last!), "Rand muss ein Buchstabe sein: \(w.text)")
            }
        }
    }

    @Test func keineDoppeltenUndEingabeGibtDieLoesung() throws {
        for s in sprachen {
            let list = try WordList.load(s)
            var gesehen = Set<String>()
            for w in list.words {
                #expect(gesehen.insert(w.solution).inserted, "doppelt: \(s) \(w.solution)")
                #expect(WordInput.normalize(w.text, language: s) == .success(w.solution), "\(s) \(w.text)")
            }
        }
    }

    @Test func abdeckungJeSprache() throws {
        for s in sprachen {
            let list = try WordList.load(s)
            #expect(list.words.count >= 140, "\(s): nur \(list.words.count) Wörter")
            for c in Category.allCases {
                for d in Difficulty.allCases {
                    let n = list.words.filter { $0.category == c && $0.difficulty == d }.count
                    #expect(n >= mindestensJeKategorieUndStufe(s), "\(s) \(c) \(d): nur \(n)")
                }
            }
            // Jede Stufe hat mindestens vier verschiedene Wortlängen, und jede Stufe hat genug Wörter für das Tageswort.
            for d in Difficulty.allCases {
                let w = list.words.filter { $0.difficulty == d }
                #expect(w.count >= 40, "\(s) \(d): nur \(w.count) Wörter")
                #expect(Set(w.map { $0.solution.count }).count >= 4, "\(s) \(d): zu wenig verschiedene Längen")
            }
        }
    }

    // MARK: Filter für anstößige Wörter

    /// Kurze Sperrliste je Sprache (ganze Wörter und Wortteile ab 5 Buchstaben). Bewusst klein: Es geht um Beleidigungen, Vulgäres, Gewalt und Extremismus.
    static let sperre: [WordLanguage: [String]] = [
        .de: ["ARSCH", "FOTZE", "SCHEISSE", "HURE", "NUTTE", "SCHWUCHTEL", "NEGER", "NAZI", "HITLER", "WICHSER", "SCHLAMPE", "FICKEN", "TITTEN", "PIMMEL", "VERGEWALTIG", "HAKENKREUZ", "MOESE"],
        .en: ["FUCK", "SHIT", "CUNT", "BITCH", "WHORE", "SLUT", "NIGGER", "FAGGOT", "COCK", "PUSSY", "ASSHOLE", "NAZI", "HITLER", "RAPE", "NIGGA", "DILDO"],
        .es: ["PUTA", "MIERDA", "COÑO", "CABRON", "JODER", "POLLA", "MARICON", "NAZI", "HITLER", "VIOLACION", "PUTO", "PENDEJO", "CULO"],
        .fr: ["PUTAIN", "MERDE", "CONNARD", "SALOPE", "ENCULE", "NAZI", "HITLER", "NEGRE", "PEDE", "VIOL", "BITE", "CUL"],
    ]

    @Test func keineAnstoessigenWoerter() throws {
        for s in sprachen {
            let list = try WordList.load(s)
            for w in list.words {
                let teile = w.solution.split(whereSeparator: { Letters.open.contains($0) }).map(String.init)
                for gesperrt in Self.sperre[s] ?? [] {
                    let treffer = teile.contains(gesperrt) || (gesperrt.count >= 5 && w.solution.contains(gesperrt))
                    #expect(!treffer, "\(s): gesperrtes Wort in \(w.text)")
                }
            }
        }
    }

    @Test func sperrlisteWirktAufBekannteBeispiele() {
        // Der Filter muss selbst funktionieren: ein Wort wie SCHEISSE wird erkannt, ein harmloses wie SCHEIBE nicht.
        func gesperrt(_ w: String, _ s: WordLanguage) -> Bool {
            (Self.sperre[s] ?? []).contains { w == $0 || ($0.count >= 5 && w.contains($0)) }
        }
        #expect(gesperrt("SCHEISSE", .de)); #expect(!gesperrt("SCHEIBE", .de))
        #expect(gesperrt("FUCK", .en)); #expect(!gesperrt("FUN", .en))
        #expect(gesperrt("PUTA", .es)); #expect(!gesperrt("PUERTA", .es))
        #expect(gesperrt("MERDE", .fr)); #expect(!gesperrt("MER", .fr))
    }
}
