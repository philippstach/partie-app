// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum WordInputError: Error, Equatable, Sendable {
    case tooShort, tooLong, invalidCharacter
}

/// Zwei-Spieler-Eingabe (und Prüfung der Wortlisten): Eingabe → Lösung in Großbuchstaben.
enum WordInput {
    static let minLetters = 3
    static let maxLetters = 20
    static let maxHintLength = 30

    static func normalize(_ input: String, language: WordLanguage) -> Result<String, WordInputError> {
        // Ränder weg, Leerraum innen zu einem Leerzeichen
        var text = input.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if language == .de {
            text = text.replacingOccurrences(of: "ß", with: "ss").replacingOccurrences(of: "ẞ", with: "SS")
        }
        if language == .es || language == .fr {
            // Akzente fallen weg (é → E, ç → C); im Spanischen bleibt Ñ ein eigener Buchstabe, im Französischen steht œ für OE.
            text = text.replacingOccurrences(of: "œ", with: "oe").replacingOccurrences(of: "Œ", with: "OE")
                .replacingOccurrences(of: "æ", with: "ae").replacingOccurrences(of: "Æ", with: "AE")
            if language == .es { text = text.replacingOccurrences(of: "ñ", with: "\u{1}").replacingOccurrences(of: "Ñ", with: "\u{1}") }
            text = text.folding(options: .diacriticInsensitive, locale: nil)
            if language == .es { text = text.replacingOccurrences(of: "\u{1}", with: "Ñ") }
        }
        text = Letters.upper(text)
        guard let first = text.first, let last = text.last else { return .failure(.tooShort) }

        let alphabet = Set(language.alphabet)
        guard text.allSatisfy({ alphabet.contains($0) || Letters.open.contains($0) }),
              alphabet.contains(first), alphabet.contains(last),
              !text.contains("--"), !text.contains(" -"), !text.contains("- ")
        else { return .failure(.invalidCharacter) }

        let count = text.filter { alphabet.contains($0) }.count
        if count < minLetters { return .failure(.tooShort) }
        if count > maxLetters { return .failure(.tooLong) }
        return .success(text)
    }
}
