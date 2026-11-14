// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Meldet, was beim Laden nicht lesbar war (Wert vorhanden, aber unbrauchbar). Fehlende Felder gelten nicht als Fehler.
/// Wird über `decoder.userInfo[LoadReport.key]` weitergereicht.
final class LoadReport: @unchecked Sendable {
    static let key = CodingUserInfoKey(rawValue: "sudoku.loadReport")!
    private let lock = NSLock()
    private var items = [String]()
    func note(_ what: String) { lock.lock(); items.append(what); lock.unlock() }
    var problems: [String] { lock.lock(); defer { lock.unlock() }; return items }
    var isClean: Bool { problems.isEmpty }
}

extension KeyedDecodingContainer {
    /// Fehlt der Schlüssel oder ist der Wert unbrauchbar, gilt der Standard. Unbrauchbare Werte werden gemeldet.
    func lenient<T: Decodable>(_ type: T.Type, _ key: Key, default fallback: @autoclosure () -> T, report: LoadReport?) -> T {
        do {
            return try decodeIfPresent(type, forKey: key) ?? fallback()
        } catch {
            report?.note(key.stringValue)
            return fallback()
        }
    }

    /// Wie `lenient`, aber mit „nicht vorhanden“ (`nil`) als Standard
    func lenientOptional<T: Decodable>(_ type: T.Type, _ key: Key, report: LoadReport?) -> T? {
        do {
            return try decodeIfPresent(type, forKey: key)
        } catch {
            report?.note(key.stringValue)
            return nil
        }
    }

    /// Techniken als Liste von Nummern: unbekannte Nummern (neuere oder ältere Version) werden übersprungen
    func lenientTechniques(_ key: Key, report: LoadReport?) -> [Technique]? {
        guard let raw = lenientOptional([Int].self, key, report: report) else { return nil }
        return raw.compactMap(Technique.init(rawValue:))
    }
}

/// Ein Listenelement, das auch dann „lädt“, wenn es unbrauchbar ist (dann `nil`)
struct Lossy<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
        if value == nil { (decoder.userInfo[LoadReport.key] as? LoadReport)?.note("Listenelement") }
    }
}

extension Decoder {
    var loadReport: LoadReport? { userInfo[LoadReport.key] as? LoadReport }
}
