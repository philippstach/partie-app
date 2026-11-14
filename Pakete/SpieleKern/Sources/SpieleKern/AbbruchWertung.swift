// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Einstellung „Partie abbrechen“ (S3): Zählt „Beenden“ mitten in einer Partie als Niederlage?
/// Standard ist `nie`. Im Kinder-Modus und in Arcade-Spielen wird nie eine Niederlage gebucht.
public enum AbbruchWertung: String, CaseIterable, Sendable, Identifiable {
    /// Zählt nicht (Standard): Die Partie wird verworfen.
    case nie
    /// Nur wenn mindestens ein Computer mitspielt.
    case computer
    /// Immer: auch unter Menschen und allein (Einzelspiel = verloren).
    case immer

    public var id: String { rawValue }

    /// Schlüssel in `UserDefaults` (wie die anderen Schalter der Hülle, `@AppStorage` in den Einstellungen).
    public static let schluessel = "abbruchWertung"
    /// Schlüssel des Kinder-Modus der Hülle.
    public static let kinderSchluessel = "kinderModus"
    /// Ab dieser reinen Spielzeit (Sekunden, ohne Hintergrund und Pause) gilt eine Partie als begonnen, auch wenn das Spiel keinen Zug meldet.
    public static let mindestSpielzeit: TimeInterval = 20

    public static func gespeichert(_ d: UserDefaults = .standard) -> AbbruchWertung {
        d.string(forKey: schluessel).flatMap(AbbruchWertung.init(rawValue:)) ?? .nie
    }

    /// Hat die Partie wirklich begonnen? Ja, wenn das Spiel einen Zug gemeldet hat (`SpielZug.gemacht`), wenn ein gespeicherter
    /// Stand fortgesetzt wurde oder wenn sie mindestens `mindestSpielzeit` lief. Ein versehentliches Öffnen und sofortiges
    /// Beenden zählt so nie.
    public static func begonnen(hatZug: Bool, fortgesetzt: Bool, spielzeit: TimeInterval) -> Bool {
        hatZug || fortgesetzt || (spielzeit.isFinite && spielzeit >= mindestSpielzeit)
    }

    /// Die Entscheidung: Wird dieser Abbruch als Niederlage gebucht?
    public func bucht(begonnen: Bool, menschen: Int, computer: Int, kinder: Bool, arcade: Bool) -> Bool {
        guard begonnen, menschen > 0, !kinder, !arcade else { return false }
        switch self {
        case .nie: return false
        case .computer: return computer > 0
        case .immer: return true
        }
    }
}

/// Reine Spielzeit einer Partie: läuft nur, solange die App im Vordergrund ist und die Partie nicht pausiert.
public struct Spieluhr: Equatable, Sendable {
    private var gesammelt: TimeInterval = 0
    private var laeuftSeit: Date?
    public init() {}

    /// Neue Partie: Zeit auf null, Uhr läuft.
    public mutating func starten(_ jetzt: Date = Date()) { gesammelt = 0; laeuftSeit = jetzt }
    /// App im Hintergrund oder Partie pausiert: Uhr anhalten.
    public mutating func anhalten(_ jetzt: Date = Date()) {
        if let s = laeuftSeit { gesammelt += max(0, jetzt.timeIntervalSince(s)) }
        laeuftSeit = nil
    }
    /// Zurück im Vordergrund: Uhr läuft weiter (ohne Wirkung, wenn sie schon läuft).
    public mutating func weiter(_ jetzt: Date = Date()) { if laeuftSeit == nil { laeuftSeit = jetzt } }
    public func zeit(_ jetzt: Date = Date()) -> TimeInterval {
        gesammelt + (laeuftSeit.map { max(0, jetzt.timeIntervalSince($0)) } ?? 0)
    }
}
