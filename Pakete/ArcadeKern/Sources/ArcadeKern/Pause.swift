// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Pausenlogik aller Arcade-Spiele (testbar ohne Oberfläche): Das Spiel pausiert, sobald die App nicht mehr aktiv ist
/// (Hintergrund, Anruf, Kontrollzentrum) oder der Spieler es verlässt; es läuft erst nach einem Tipp weiter.
public struct ArcadePause: Equatable, Sendable {
    public private(set) var pausiert = false
    public init() {}

    /// Die App wird aktiv (`true`) oder inaktiv/im Hintergrund (`false`). Nur ein laufendes Spiel pausiert.
    public mutating func szene(aktiv: Bool, phase: ArcadePhase) { if !aktiv, phase.laeuft { pausiert = true } }
    /// Spieler verlässt die Ansicht (Zurück, Tab-Wechsel): ebenfalls pausieren, falls es lief.
    public mutating func verlassen(phase: ArcadePhase) { if phase.laeuft { pausiert = true } }
    /// Menüpunkt „Pause“ / „Weiter“.
    public mutating func umschalten(phase: ArcadePhase) { if phase.laeuft { pausiert.toggle() } }
    public mutating func weiter() { pausiert = false }
    /// „Neu beginnen“.
    public mutating func zuruecksetzen() { pausiert = false }
    /// Soll die Uhr des Spiels laufen?
    public func uhrLaeuft(phase: ArcadePhase) -> Bool { phase.laeuft && !pausiert }
    /// Darf das Spiel Eingaben annehmen (Gesten, Knöpfe)? Nicht während der Pause.
    public var nimmtEingabe: Bool { !pausiert }
}
