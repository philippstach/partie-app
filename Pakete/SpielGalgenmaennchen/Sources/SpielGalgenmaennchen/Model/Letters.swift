// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Sprache der Wörter (und damit der Tastatur). Nicht die Sprache der App.
enum WordLanguage: String, Codable, CaseIterable, Sendable {
    case de, en, es, fr

    /// Nur die ursprünglichen Listen (Referenz-Tests und gemeinsame Fixtures); alle Listen: `alle`.
    static var allCases: [WordLanguage] { [.de, .en] }
    /// Alle Wortlisten, auch Spanisch und Französisch (eigene Listen ohne Referenz-Fixtures).
    static let alle: [WordLanguage] = [.de, .en, .es, .fr]

    /// Tasten in fester Reihenfolge; gilt auch für die Hinweis-Auswahl.
    var alphabet: [Character] {
        switch self {
        case .de: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ")
        case .en, .fr: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        case .es: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÑ")
        }
    }

    /// Sprache der App (folgt dem Gerät): Deutsch, Spanisch oder Französisch, sonst Englisch.
    static var appLanguage: WordLanguage {
        switch Bundle.main.preferredLocalizations.first {
        case "de": .de
        case "es": .es
        case "fr": .fr
        default: .en
        }
    }

    /// Standard für „Wörter auf“: die Sprache der App.
    static var deviceDefault: WordLanguage { appLanguage }
}

/// Großschreibung über eine feste Tabelle (a–z, ä, ö, ü).
/// Nicht `uppercased()`: das macht aus ß ein SS und hängt vom Gebietsschema ab.
enum Letters {
    private static let table: [Character: Character] = {
        var t: [Character: Character] = [:]
        for u in UInt8(ascii: "a")...UInt8(ascii: "z") {
            t[Character(UnicodeScalar(u))] = Character(UnicodeScalar(u - 32))
        }
        t["ä"] = "Ä"; t["ö"] = "Ö"; t["ü"] = "Ü"; t["ñ"] = "Ñ"
        return t
    }()

    static func upper(_ c: Character) -> Character { table[c] ?? c }
    static func upper(_ s: String) -> String { String(s.map(upper)) }

    /// Zeichen, die nie geraten werden, sondern sofort offen stehen.
    static let open: Set<Character> = [" ", "-"]

    /// Gehört das Zeichen zum Alphabet der Sprache (also kein Leerzeichen, Bindestrich oder `_`)?
    static func isLetter(_ c: Character, in language: WordLanguage) -> Bool { language.alphabet.contains(c) }
}
