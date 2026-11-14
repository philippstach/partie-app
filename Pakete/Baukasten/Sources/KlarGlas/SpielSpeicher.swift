// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SwiftUI

// Klar & Glas – Spielstand sicher ablegen und laden (Konzept 3.5, Q18): ein kaputter Speicherstand löscht nie alles,
// fehlende Felder bekommen Standardwerte, und „verwerfen“ fragt immer nach (E6) – mit demselben Dialog in allen Apps.

/// Wo der Spielstand liegt. `UserDefaults` oder eine Datei; Tests nehmen den flüchtigen Speicher.
public protocol SpielAblage: AnyObject {
    func lesen() -> Data?
    func schreiben(_ daten: Data?) throws
}

/// Ablage in `UserDefaults` unter einem Schlüssel (für kleine Spielstände).
public final class DefaultsAblage: SpielAblage {
    let schluessel: String
    let defaults: UserDefaults

    public init(schluessel: String, defaults: UserDefaults = .standard) {
        self.schluessel = schluessel; self.defaults = defaults
    }

    public func lesen() -> Data? { defaults.data(forKey: schluessel) }
    public func schreiben(_ daten: Data?) throws { defaults.set(daten, forKey: schluessel) }
}

/// Ablage als Datei (atomar geschrieben) im Ordner „Application Support“ der App.
public final class DateiAblage: SpielAblage {
    public let url: URL

    public init(url: URL) { self.url = url }

    /// `DateiAblage(name: "spielstand.json")` → Application Support/<Bundle-ID>/spielstand.json
    public convenience init(name: String) {
        let basis = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        let ordner = basis.appendingPathComponent(Bundle.main.bundleIdentifier ?? "spiel", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        self.init(url: ordner.appendingPathComponent(name))
    }

    public func lesen() -> Data? { try? Data(contentsOf: url) }

    public func schreiben(_ daten: Data?) throws {
        if let daten {
            try daten.write(to: url, options: .atomic)
        } else if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}

/// Ablage im Arbeitsspeicher (Tests, Vorschau).
public final class FluechtigeAblage: SpielAblage {
    public private(set) var daten: Data?
    public init(daten: Data? = nil) { self.daten = daten }
    public func lesen() -> Data? { daten }
    public func schreiben(_ daten: Data?) throws { self.daten = daten }
}

/// Ergebnis beim Laden: nichts da, ein Stand, oder ein kaputter Stand (Daten bleiben liegen, die App entscheidet).
public enum SpielLadeErgebnis<Stand> {
    case leer
    case stand(Stand)
    case defekt(Error, Data)

    public var stand: Stand? { if case .stand(let s) = self { s } else { nil } }
}

/// Speichert und lädt einen `Codable`-Spielstand. Laden wirft nie und löscht nie: ein unlesbarer Stand kommt als `.defekt`
/// zurück, alles andere in der App bleibt unberührt. Speichern ist atomar (Datei) bzw. ein Schreibvorgang (Defaults).
public struct SpielSpeicher<Stand: Codable> {
    let ablage: SpielAblage
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    public init(ablage: SpielAblage) { self.ablage = ablage }

    public func laden() -> SpielLadeErgebnis<Stand> {
        guard let daten = ablage.lesen(), !daten.isEmpty else { return .leer }
        do { return .stand(try decoder.decode(Stand.self, from: daten)) }
        catch { return .defekt(error, daten) }
    }

    public func speichern(_ stand: Stand) throws {
        try ablage.schreiben(try encoder.encode(stand))
    }

    public func loeschen() throws {
        try ablage.schreiben(nil)
    }
}

public extension KeyedDecodingContainer {
    /// Tolerantes Lesen: fehlt das Feld oder passt der Typ nicht, gilt `sonst` (Regel „fehlende Felder → Standardwert“).
    func wert<T: Decodable>(_ key: Key, sonst: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? sonst
    }
}

#if canImport(UIKit)

public extension View {
    /// Rückfrage „Laufende Partie verwerfen?“ mit „Verwerfen“ (rot) und „Abbrechen“. Verwerfen fragt immer (E6);
    /// Home fragt nie (die Partie bleibt gespeichert).
    func spielSpeicherRueckfrage(_ gezeigt: Binding<Bool>, verwerfen: @escaping () -> Void) -> some View {
        confirmationDialog(Text("Laufende Partie verwerfen?", bundle: .module), isPresented: gezeigt, titleVisibility: .visible) {
            Button(role: .destructive, action: verwerfen) { Text("Verwerfen", bundle: .module) }
            Button(role: .cancel) {} label: { Text("Abbrechen", bundle: .module) }
        } message: {
            Text("Der Spielstand geht verloren.", bundle: .module)
        }
    }
}

#endif
