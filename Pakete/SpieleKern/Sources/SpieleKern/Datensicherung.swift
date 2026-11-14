// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Eine Sicherungsdatei: alle Personen, ihre Fotos und alle Partien (auch ohne Personenzuordnung). Bleibt Klartext-JSON,
/// damit sie sich auch später noch lesen lässt. `version` steigt nur, wenn sich das Format ändert.
public struct Sicherung: Codable, Equatable, Sendable {
    public static let aktuelleVersion = 1
    public var version: Int
    public var erstellt: Date
    public var spieler: [Spieler]
    /// Foto-Dateien (JPEG) je Person, Schlüssel = Personen-ID als Text.
    public var fotos: [String: Data]
    public var partien: [PartieErgebnis]

    public init(version: Int = Sicherung.aktuelleVersion, erstellt: Date = Date(), spieler: [Spieler], fotos: [String: Data], partien: [PartieErgebnis]) {
        self.version = version; self.erstellt = erstellt; self.spieler = spieler; self.fotos = fotos; self.partien = partien
    }
}

public enum SicherungFehler: Error, Equatable, Sendable {
    /// Die Datei ist keine Partie-Sicherung.
    case keineSicherung
    /// Die Sicherung stammt aus einer neueren Fassung der App.
    case zuNeu
}

/// Ergebnis einer Übernahme: was neu dazugekommen ist.
public struct Uebernahme: Equatable, Sendable {
    public var spieler = 0, fotos = 0, partien = 0
    public init(spieler: Int = 0, fotos: Int = 0, partien: Int = 0) { self.spieler = spieler; self.fotos = fotos; self.partien = partien }
    public var nichtsNeu: Bool { spieler == 0 && fotos == 0 && partien == 0 }
}

public enum Datensicherung {
    /// Baut die Sicherungsdatei. `foto` liefert die Bilddaten einer Person (nil ohne Foto).
    public static func erstellen(spieler: [Spieler], partien: [PartieErgebnis], foto: (UUID) -> Data?, am datum: Date = Date()) throws -> Data {
        var fotos: [String: Data] = [:]
        for s in spieler where s.bildNr != nil { if let d = foto(s.id) { fotos[s.id.uuidString] = d } }
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]
        return try e.encode(Sicherung(erstellt: datum, spieler: spieler, fotos: fotos, partien: partien))
    }

    public static func lesen(_ daten: Data) throws -> Sicherung {
        struct Kopf: Decodable { var version: Int }
        guard let kopf = try? JSONDecoder().decode(Kopf.self, from: daten) else { throw SicherungFehler.keineSicherung }
        guard kopf.version <= Sicherung.aktuelleVersion else { throw SicherungFehler.zuNeu }
        guard let s = try? JSONDecoder().decode(Sicherung.self, from: daten) else { throw SicherungFehler.keineSicherung }
        return s
    }

    /// Dateiname der Sicherung, z. B. „Partie-Sicherung-2026-11-08.json“.
    public static func dateiname(am datum: Date = Date()) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return "Partie-Sicherung-\(f.string(from: datum)).json"
    }
}
