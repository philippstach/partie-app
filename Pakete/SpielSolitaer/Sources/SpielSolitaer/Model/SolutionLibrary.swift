// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

private final class SolutionBundleToken {}

/// Zugschrift der gespeicherten Lösungen (`Shared/partien/loesungen/<liste>.json`, SPEZIFIKATION-EXTRAS §3):
/// Züge mit Leerzeichen getrennt. `s` = Stapel; sonst Quelle + Ziel (`S3Z1`, `AS4`, `S1S0x4`); `x3` = Anzahl;
/// Spider-Abräumen `S2Z` = 13 Karten.
enum SolutionNotation {
    /// Ein Ort: `A` (Ablage), `S3`, `Z1` (Ziel), bei Spider `Z` ohne Nummer
    private static func pile(_ chars: [Character], _ i: inout Int) -> Pile? {
        guard i < chars.count else { return nil }
        let letter = chars[i]
        i += 1
        if letter == "A" { return .waste }
        var number: Int?
        if i < chars.count, let d = chars[i].wholeNumberValue { number = d; i += 1 }
        switch letter {
        case "S": return number.map { .column($0) }
        case "Z": return .foundation(number ?? 0)       // Spider: nur ein Ziel, die Nummer zählt dort nicht
        default: return nil
        }
    }

    /// Ein Zug in Zugschrift; nil, wenn er nicht lesbar ist
    static func move(_ token: String) -> Move? {
        if token == "s" { return .draw }
        let chars = Array(token)
        var i = 0
        guard let from = pile(chars, &i), let to = pile(chars, &i) else { return nil }
        var count = 1
        if i < chars.count, chars[i] == "x" {
            guard let n = Int(String(chars[(i + 1)...])) else { return nil }
            count = n
        } else if i < chars.count {
            return nil
        }
        if case .foundation = to, case .column = from, count == 1, token.hasSuffix("Z") { count = 13 }   // Spider-Abräumen „S2Z“
        return .move(from: from, to: to, count: count)
    }

    static func moves(_ text: String) -> [Move]? {
        var out: [Move] = []
        for token in text.split(separator: " ") {
            guard let m = move(String(token)) else { return nil }
            out.append(m)
        }
        return out
    }
}

/// Lädt Lösungen erst beim Ansehen (die Dateien sind zusammen ca. 2,8 MB).
enum SolutionLibrary {
    private struct File: Decodable {
        struct Entry: Decodable { let seed: UInt64; let zuege: String }
        let loesungen: [Entry]
    }

    /// Hat diese Partie eine gespeicherte Lösung? (lösbare oder Tagespartie aus einer Liste; Zufall und FreeCell nicht)
    static func hasSolution(for deal: DealInfo, catalog: DealCatalog = .shared) -> Bool {
        guard deal.kind != .random, let name = catalog.listName(for: deal.mode) else { return false }
        return catalog.levels[name]?[deal.seed] != nil || catalog.solutionLengths[name]?[deal.seed] != nil
    }

    /// Zugschrift der Lösung einer Partie (ohne sie zu lesen: das macht die Regel des Spiels)
    static func text(for deal: DealInfo, catalog: DealCatalog = .shared, bundle: Bundle = partienBundle(SolutionBundleToken.self)) -> String? {
        guard deal.kind != .random, let name = catalog.listName(for: deal.mode),
              let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "loesungen"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return nil }
        return file.loesungen.first(where: { $0.seed == deal.seed })?.zuege
    }

    /// Die Züge der Lösung einer Partie (von der Startaufstellung, ohne Automatik)
    static func moves(for deal: DealInfo, catalog: DealCatalog = .shared, bundle: Bundle = partienBundle(SolutionBundleToken.self),
                      parse: (String) -> [Move]? = SolutionNotation.moves) -> [Move]? {
        guard deal.kind != .random, let name = catalog.listName(for: deal.mode),
              let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "loesungen"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data),
              let entry = file.loesungen.first(where: { $0.seed == deal.seed }) else { return nil }
        return parse(entry.zuege)
    }

    /// Alle Lösungen einer Liste in Reihenfolge der Liste (für Tests)
    static func all(listName name: String, bundle: Bundle = partienBundle(SolutionBundleToken.self),
                    parse: (String) -> [Move]? = SolutionNotation.moves) -> [(seed: UInt64, moves: [Move])] {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "loesungen"),
              let data = try? Data(contentsOf: url), let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.loesungen.compactMap { e in parse(e.zuege).map { (e.seed, $0) } }
    }
}
