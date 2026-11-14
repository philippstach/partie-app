// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Eine Datei, die da ist, aber nicht gelesen werden kann (Statistik, Spielstand), wird nie still überschrieben:
/// Vorher kommt eine Kopie `<name>-defekt-<Datum>.json` daneben. So bleibt nichts verloren, wenn ein Update das Format
/// nicht mehr versteht oder die Datei beschädigt ist.
enum DefectBackup {
    /// Kopiert `url` nach `<name>-defekt-<JJJJMMTT-HHMMSS>.json` (im selben Ordner). Gibt die Kopie zurück, nil wenn nichts zu sichern war.
    @discardableResult
    static func preserve(_ url: URL, now: Date = .now, fileManager: FileManager = .default) -> URL? {
        guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else { return nil }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        let stem = url.deletingPathExtension().lastPathComponent
        var copy = url.deletingLastPathComponent().appending(path: "\(stem)-defekt-\(f.string(from: now)).json")
        var n = 2
        while fileManager.fileExists(atPath: copy.path) {            // zwei Sicherungen in derselben Sekunde
            copy = url.deletingLastPathComponent().appending(path: "\(stem)-defekt-\(f.string(from: now))-\(n).json")
            n += 1
        }
        do { try data.write(to: copy, options: .atomic); return copy } catch { return nil }
    }
}
