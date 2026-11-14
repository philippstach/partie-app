// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Die Runde von der Salon-Startseite („Wer ist dabei?“): die angetippten Personen als IDs, in der Reihenfolge der Auswahl.
/// Die Startseite speichert sie, `SpielRahmen` belegt damit das Blatt „Neues Spiel“ vor (zuerst die Runde, dann wie bisher).
/// Nur ein kleiner Speicher in `UserDefaults` (Schlüssel „start.runde“); ohne Auswahl ist die Runde leer und nichts ändert sich.
public enum AktuelleRunde {
    public static let schluessel = "start.runde"

    /// Die gespeicherten IDs in Auswahlreihenfolge (unlesbare Einträge werden übergangen).
    public static func laden(defaults: UserDefaults = .standard) -> [UUID] {
        (defaults.stringArray(forKey: schluessel) ?? []).compactMap(UUID.init(uuidString:))
    }

    public static func speichern(_ ids: [UUID], defaults: UserDefaults = .standard) {
        if ids.isEmpty { defaults.removeObject(forKey: schluessel) } else { defaults.set(ids.map(\.uuidString), forKey: schluessel) }
    }

    /// Die Runde ohne Personen, die es nicht mehr gibt, und ohne doppelte Einträge; die Reihenfolge bleibt.
    public static func bereinigt(_ ids: [UUID], vorhanden: [UUID]) -> [UUID] {
        var gesehen = Set<UUID>()
        return ids.filter { vorhanden.contains($0) && gesehen.insert($0).inserted }
    }

    /// Namen für das Blatt „Neues Spiel“: zuerst die Runde (Reihenfolge wie gewählt), dann die bisherige Vorgabe
    /// („Ich“, zuletzt Gespielte), ohne Doppelte (Groß- und Kleinschreibung zählt nicht). Die Zahl der Plätze ist wie
    /// bisher zwei, mit einer größeren Runde so viele wie gewählt, immer innerhalb der Spielerzahl des Spiels.
    /// Fehlende Namen bleiben leer. Ohne Runde ist das Ergebnis genau die bisherige Vorgabe.
    public static func aufstellung(runde: [String], bisher: [String], spieler: ClosedRange<Int>) -> [String] {
        var namen: [String] = []
        for n in runde + bisher where !n.isEmpty && !namen.contains(where: { $0.caseInsensitiveCompare(n) == .orderedSame }) {
            namen.append(n)
        }
        let plaetze = max(spieler.lowerBound, min(max(2, runde.count), spieler.upperBound))
        return (0..<plaetze).map { $0 < namen.count ? namen[$0] : "" }
    }
}

public extension AktuelleRunde {
    /// Namen der gespeicherten Runde, soweit die Personen noch im Verzeichnis stehen (in Auswahlreihenfolge).
    @MainActor static func namen(_ verzeichnis: SpielerVerzeichnis, defaults: UserDefaults = .standard) -> [String] {
        laden(defaults: defaults).compactMap { id in verzeichnis.menschen.first { $0.id == id }?.name }
    }
}
