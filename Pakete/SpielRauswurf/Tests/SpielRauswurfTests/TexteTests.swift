// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

private let texteKatalogVorhanden = FileManager.default.fileExists(atPath: URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "Ludo/Localizable.xcstrings").path)

/// Jeder Text-Schlüssel, den der Code benutzt, steht in `Localizable.xcstrings` (DE und EN, Platzhalter gleich).
@Suite("Texte", .enabled(if: texteKatalogVorhanden,
                       "Texte liegen im gemeinsamen Partie-Katalog (App/Ressourcen), nicht mehr neben dem Test"))
struct TexteTests {
    static var ludoOrdner: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "Ludo")
    }

    static func katalog() throws -> [String: [String: String]] {
        let daten = try Data(contentsOf: ludoOrdner.appending(path: "Localizable.xcstrings"))
        let root = try #require(JSONSerialization.jsonObject(with: daten) as? [String: Any])
        let strings = try #require(root["strings"] as? [String: [String: Any]])
        var ergebnis: [String: [String: String]] = [:]
        for (k, v) in strings {
            let loks = v["localizations"] as? [String: [String: Any]] ?? [:]
            ergebnis[k] = loks.compactMapValues { ($0["stringUnit"] as? [String: Any])?["value"] as? String }
        }
        return ergebnis
    }

    static func swiftDateien() -> [URL] {
        let e = FileManager.default.enumerator(at: ludoOrdner, includingPropertiesForKeys: nil)
        return (e?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "swift" }
    }

    @Test func alleSchluesselVorhanden() throws {
        let katalog = try Self.katalog()
        let muster = try NSRegularExpression(pattern: #"(?:\bL\(|Text\(|SectionLabel\(|Label\(|Button\(|Section\()\s*"([a-z][A-Za-z0-9]*(?:\.[A-Za-z0-9]+)+)""#)
        var gefunden = Set<String>()
        for url in Self.swiftDateien() {
            let text = try String(contentsOf: url, encoding: .utf8)
            for m in muster.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let r = Range(m.range(at: 1), in: text) { gefunden.insert(String(text[r])) }
            }
        }
        #expect(gefunden.count > 40)
        for k in gefunden.sorted() {
            #expect(katalog[k] != nil, "Text-Schlüssel fehlt: \(k)")
        }
    }

    @Test func dynamischeSchluessel() throws {
        let katalog = try Self.katalog()
        var schluessel = (0 ..< 4).map { "sitz.\($0)" }
        for r in ["rausPflicht", "startfeldRaeumen", "schlagpflicht", "dreiVersuche", "sechsNochmal", "zielUeberspringen"] {
            schluessel += ["regel.\(r)", "regel.\(r).info"]
        }
        schluessel += ["regel.spielende.erster", "regel.spielende.alle", "einst.tempo.langsam", "einst.tempo.normal", "einst.tempo.schnell"]
        for k in schluessel { #expect(katalog[k] != nil, "fehlt: \(k)") }
    }

    @Test func deutschUndEnglischMitGleichenPlatzhaltern() throws {
        func platzhalter(_ s: String) -> [String] {
            let re = try! NSRegularExpression(pattern: "%(lld|@|%)")
            return re.matches(in: s, range: NSRange(s.startIndex..., in: s)).compactMap { Range($0.range, in: s).map { String(s[$0]) } }
        }
        for (k, v) in try Self.katalog() {
            let de = v["de"] ?? "", en = v["en"] ?? ""
            #expect(!de.isEmpty && !en.isEmpty, "\(k): Übersetzung fehlt")
            #expect(platzhalter(de).sorted() == platzhalter(en).sorted(), "\(k): Platzhalter verschieden")
        }
    }

    @Test func appNameNurAusEinemSchluessel() throws {
        // Der Anzeigename steht nirgends fest im Code.
        for url in Self.swiftDateien() {
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(!text.contains("Mensch ärgere"), "\(url.lastPathComponent): Name fest im Code")
        }
    }
}
