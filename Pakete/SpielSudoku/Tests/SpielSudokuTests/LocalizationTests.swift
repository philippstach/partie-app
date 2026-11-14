// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSudoku

/// Prüft den String Catalog: Jeder Text hat eine englische Übersetzung mit denselben Platzhaltern.
struct LocalizationTests {
    private static var catalog: [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "App/Ressourcen/Localizable.xcstrings")
        let data = try! Data(contentsOf: url)
        let root = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        return root["strings"] as! [String: Any]
    }

    private static var sudokuQuelltext: String {
        let ordner = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources")
        let dateien = FileManager.default.enumerator(at: ordner, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
        return dateien.filter { $0.pathExtension == "swift" }.compactMap { try? String(contentsOf: $0, encoding: .utf8) }.joined()
    }

    private static func placeholders(_ s: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "%(?:\\d+\\$)?(?:lld|@|d|u|f)")
        return regex.matches(in: s, range: NSRange(s.startIndex..., in: s)).map {
            String(s[Range($0.range, in: s)!]).replacingOccurrences(of: #"\d+\$"#, with: "", options: .regularExpression)
        }
    }

    @Test(arguments: ["en", "es", "fr"])  // Deutsch ist die Quellsprache des gemeinsamen Katalogs
    func jederTextIstUebersetzt(sprache: String) {
        let strings = Self.catalog
        let quelle = Self.sudokuQuelltext
        #expect(strings.count > 100)
        var geprueft = 0
        defer { #expect(geprueft > 100, "zu wenige Sudoku-Texte gefunden: \(geprueft)") }
        for (key, value) in strings {
            // Der Katalog gehört der ganzen Sammlung: nur Texte, die im Sudoku-Code vorkommen
            let literal = "\"" + key.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            if key.trimmingCharacters(in: .whitespaces).isEmpty || !quelle.contains(literal) { continue }
            geprueft += 1
            let entry = value as! [String: Any]
            if entry["shouldTranslate"] as? Bool == false { continue }
            let loc = (entry["localizations"] as? [String: Any])?[sprache] as? [String: Any]
            // Plural-Varianten: jede Form zählt, Platzhalter-Prüfung gegen die Form „other“
            let plural = ((loc?["variations"] as? [String: Any])?["plural"] as? [String: Any])?["other"] as? [String: Any]
            let unit = (plural ?? loc)?["stringUnit"] as? [String: Any]
            let text = unit?["value"] as? String
            #expect(text?.isEmpty == false, "\(sprache) fehlt: \(key)")
            #expect(unit?["state"] as? String == "translated", "Nicht als übersetzt markiert (\(sprache)): \(key)")
            if let text {
                #expect(Self.placeholders(text).sorted() == Self.placeholders(key).sorted(), "Platzhalter passen nicht (\(sprache)): \(key)")
            }
        }
    }

    @Test func tippTextWirdUebersetzt() {
        // Englische Sprache im Bundle: die Texte des Logik-Lösers sind nicht mehr deutsch
        let sprachen = Set(Self.catalog.values.flatMap { (($0 as? [String: Any])?["localizations"] as? [String: Any])?.keys.map { $0 } ?? [] })
        #expect(sprachen.contains("en") && sprachen.contains("es") && sprachen.contains("fr"))
    }
}
