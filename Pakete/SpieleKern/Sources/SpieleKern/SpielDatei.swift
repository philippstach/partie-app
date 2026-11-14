// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Spielstand als eine JSON-Datei, atomar geschrieben (vorher je Spiel ein eigenes `GameRepository` mit demselben Ablauf).
/// Eine nicht lesbare oder unstimmige Datei wird unter `defektName` zur Seite gelegt, damit die App nicht bei jedem Start daran scheitert.
public enum SpielDatei {
    /// Ordner für Spielstände: Application Support.
    public static var standardOrdner: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    public static func laden<T: Decodable>(_ typ: T.Type = T.self, url: URL, defektName: String,
                                           istStimmig: (T) -> Bool = { _ in true }) -> T? {
        guard let daten = try? Data(contentsOf: url) else { return nil }
        if let stand = try? JSONDecoder().decode(T.self, from: daten), istStimmig(stand) { return stand }
        let ziel = url.deletingLastPathComponent().appending(path: defektName)
        try? FileManager.default.removeItem(at: ziel)
        try? FileManager.default.moveItem(at: url, to: ziel)
        return nil
    }

    public static func speichern<T: Encodable>(_ stand: T, url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(stand).write(to: url, options: .atomic)
    }

    public static func loeschen(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
