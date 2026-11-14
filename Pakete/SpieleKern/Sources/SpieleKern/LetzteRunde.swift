// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Merkt sich je Spiel die Aufstellung der letzten gestarteten Partie (Namen, Mensch/Computer) für „Letzte Runde wieder“ (B4).
public struct LetzteRunde: Codable, Equatable, Sendable {
    public struct Platz: Codable, Equatable, Sendable {
        public var name: String
        public var computer: Bool
        public init(name: String, computer: Bool) { self.name = name; self.computer = computer }
    }
    public var plaetze: [Platz]
    public init(plaetze: [Platz]) { self.plaetze = plaetze }

    /// Kurztext „Anna, Ben, Computer“ für die Beschriftung.
    public var kurz: String { plaetze.map(\.name).joined(separator: ", ") }

    private static func schluessel(_ spiel: String) -> String { "partie.letzteRunde.\(spiel)" }

    public static func laden(_ spiel: String, defaults: UserDefaults = .standard) -> LetzteRunde? {
        guard let d = defaults.data(forKey: schluessel(spiel)) else { return nil }
        return try? JSONDecoder().decode(LetzteRunde.self, from: d)
    }

    public func speichern(_ spiel: String, defaults: UserDefaults = .standard) {
        guard let d = try? JSONEncoder().encode(self) else { return }   // nie nil schreiben: das würde die letzte Runde löschen
        defaults.set(d, forKey: Self.schluessel(spiel))
    }

    public static func loeschen(_ spiel: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: schluessel(spiel))
    }
}
