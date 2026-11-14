// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum Difficulty: Int, Codable, CaseIterable, Sendable {
    case easy = 1, medium, hard
}

enum Category: String, Codable, CaseIterable, Sendable {
    case animals, food, countries, sports, nature, home, transport, music
}

/// Eintrag der Wortliste (`Shared/woerter/<sprache>.json`), unverändert übernommen.
struct Word: Equatable, Sendable, Decodable {
    /// Natürliche Schreibweise für den Ende-Bildschirm
    let text: String
    /// Normalisiert, Großbuchstaben
    let solution: String
    let category: Category
    let difficulty: Difficulty

    enum CodingKeys: String, CodingKey {
        case text = "wort", solution = "loesung", category = "kategorie", difficulty = "stufe"
    }
}

struct CategoryInfo: Equatable, Sendable, Decodable {
    let id: Category
    let de: String
    let en: String
    /// Optional: Spanisch und Französisch für die Oberfläche (die Wortlisten selbst gibt es nur auf Deutsch und Englisch).
    let es: String?
    let fr: String?

    func name(for language: WordLanguage) -> String {
        switch language {
        case .de: return de
        case .es: return es ?? en
        case .fr: return fr ?? en
        case .en:
            switch Bundle.main.preferredLocalizations.first {
            case "es": if let es { return es }
            case "fr": if let fr { return fr }
            default: break
            }
            return en
        }
    }
}

struct WordList: Sendable, Decodable {
    let language: WordLanguage
    let version: Int
    let categories: [CategoryInfo]
    let words: [Word]

    enum CodingKeys: String, CodingKey {
        case language = "sprache", version, categories = "kategorien", words = "woerter"
    }

    static let empty = WordList(language: .de, version: 0, categories: [], words: [])

    /// Liest `de.json` / `en.json` aus dem App-Paket (dort als Referenz auf `Shared/woerter` eingebunden).
    static func load(_ language: WordLanguage, bundle: Bundle = .main) throws -> WordList {
        var gefunden = bundle.url(forResource: language.rawValue, withExtension: "json")
        // Test auf dem Mac (auch Mac Catalyst): kein App-Paket, daher direkt aus Shared/woerter neben den Quellen.
        // Auf dem Telefon gibt es den Quellpfad nicht, die Prüfung unten greift dann ins Leere.
        if gefunden == nil {
            let wurzel = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
                .deletingLastPathComponent().deletingLastPathComponent()
            let u = wurzel.appendingPathComponent("Shared/woerter/\(language.rawValue).json")
            if FileManager.default.fileExists(atPath: u.path) { gefunden = u }
        }
        guard let url = gefunden else { throw CocoaError(.fileNoSuchFile) }
        return try JSONDecoder().decode(WordList.self, from: Data(contentsOf: url))
    }

    /// Kategoriename in der Sprache der App (nicht der Wörter), aus der JSON-Datei.
    func categoryName(_ category: Category, in uiLanguage: WordLanguage = .appLanguage) -> String {
        categories.first { $0.id == category }?.name(for: uiLanguage) ?? category.rawValue
    }
}
