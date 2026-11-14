// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Wächter über die Ende-Meldung eines Spiels im `SpielRahmen` (F2): Jede Partie bekommt eine Nummer, die bei jedem Start,
/// Fortsetzen und jeder Revanche hochzählt. Das an das Spiel gereichte `ende` trägt die Nummer seiner Partie.
/// Angenommen wird eine Meldung nur, wenn die Partie noch läuft und die Nummer zur aktuellen Partie gehört: Verzögerte Meldungen
/// (Computerzug-Task, `ende` nach einer Sekunde) einer beendeten, pausierten oder schon gemeldeten Partie verbuchen nichts mehr.
public final class PartieWache {
    /// Nummer der aktuellen Partie (0 = noch keine gestartet).
    public private(set) var nummer = 0
    /// Läuft die aktuelle Partie noch und hat noch kein Ende gemeldet?
    public private(set) var offen = false
    public init() {}

    /// Neue Partie (Neues Spiel, Fortsetzen, Revanche): zählt hoch und öffnet. Gibt die neue Nummer zurück.
    @discardableResult public func starten() -> Int { nummer += 1; offen = true; return nummer }

    /// „Beenden“ oder „Pausieren“: Die Partie nimmt keine Ende-Meldung mehr an.
    public func schliessen() { offen = false }

    /// Die Entscheidung: Meldung annehmen, wenn die Partie läuft, noch offen ist und die Meldung zu ihr gehört.
    public static func nimmtAn(laeuft: Bool, offen: Bool, aktuelle: Int, gemeldete: Int) -> Bool {
        laeuft && offen && gemeldete == aktuelle
    }

    /// Prüft eine Ende-Meldung und schließt die Partie, wenn sie angenommen wird (die zweite Meldung derselben Partie fällt durch).
    public func annehmen(partie: Int, laeuft: Bool = true) -> Bool {
        guard Self.nimmtAn(laeuft: laeuft, offen: offen, aktuelle: nummer, gemeldete: partie) else { return false }
        offen = false
        return true
    }
}

/// Der eine Start einer Partie im `SpielRahmen` (F3), für Neues Spiel, Fortsetzen, Revanche und „Noch einmal“:
/// setzt die Zug-Meldung zurück (sonst zählt „Beenden“ in der Revanche sofort als Niederlage), öffnet eine neue Partie-Nummer
/// und beginnt die Live Activity (nur bei mindestens zwei Menschen, sonst wird eine alte beendet).
@MainActor
public enum PartieStart {
    @discardableResult
    public static func ausfuehren(spielID: String, spielName: String, menschen: [String], wache: PartieWache) -> Int {
        SpielZug.zuruecksetzen(spielID)
        let nummer = wache.starten()
        LaufendePartie.beginnen(spielID: spielID, spielName: spielName, menschen: menschen)
        return nummer
    }
}
