// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Die eingebauten Rätselpakete (`Shared/raetsel/*.json`, als Ordner ins Bundle kopiert).
struct PackLibrary: Sendable {
    private(set) var packs: [String: PuzzlePack] = [:]

    static let names = ["leicht", "mittel", "schwer", "taeglich", "themen"]

    /// Lädt alle Paketdateien aus einem Ordner. Fehlende oder kaputte Dateien fehlen einfach (die App zeigt dann einen Hinweis).
    init(directory: URL) {
        for name in Self.names {
            if let pack = PuzzlePack.load(from: directory.appending(path: "\(name).json")) { packs[name] = pack }
        }
    }

    /// Der Ordner „raetsel“ im App-Bundle
    static func bundled(_ bundle: Bundle = .main) -> PackLibrary {
        guard let url = bundle.url(forResource: "raetsel", withExtension: nil) else { return PackLibrary(packs: [:]) }
        return PackLibrary(directory: url)
    }

    init(packs: [String: PuzzlePack]) { self.packs = packs }

    func puzzles(_ level: Level) -> [Puzzle] { packs[level.rawValue]?.raetsel ?? [] }
    var themes: [ThemeInfo] { packs["themen"]?.themen ?? [] }
    func themePuzzles(_ id: String) -> [Puzzle] { (packs["themen"]?.raetsel ?? []).filter { $0.thema == id } }

    var daily: [Puzzle] { packs["taeglich"]?.raetsel ?? [] }
    var isEmpty: Bool { packs.values.allSatisfy { $0.raetsel.isEmpty } }
    var isDemo: Bool { packs.values.contains { $0.demo } }

    func dailyPuzzle(for day: Day) -> Puzzle? {
        let all = daily
        return all.isEmpty ? nil : all[Daily.index(day: day, count: all.count)]
    }
}
