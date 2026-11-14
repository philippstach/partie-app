// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// KI-3 (Frag nach den Regeln im SpielRahmen): Wo der Rahmen das Regelwissen eines Spiels findet und wie er
/// entscheidet, ob es den Einstieg (Knopf, Menüzeile) überhaupt gibt. Ohne Oberfläche, ohne Apple-Typen
/// (nur `AppleSprachmodell` hinter `#available(iOS 26)`), damit es sich ohne Modell testen lässt.
public enum RegelWissenKatalog {
    private static let sperre = NSLock()
    nonisolated(unsafe) private static var _lieferant: (@Sendable (String) -> (any RegelWissen)?)?

    /// Liefert zu einer Spielkennung (Grund-ID wie in `Startauswahl.grundIDs`, ohne „-neu“) das Regelwissen oder `nil`.
    /// Der Lieferant wird bei jeder Anfrage neu gefragt, damit `aktiveRegeln` den jetzigen Stand der Hausregeln trägt.
    /// Beim App-Start setzen (wie `SpielRahmenHaken`).
    public static var lieferant: (@Sendable (String) -> (any RegelWissen)?)? {
        get { sperre.lock(); defer { sperre.unlock() }; return _lieferant }
        set { sperre.lock(); _lieferant = newValue; sperre.unlock() }
    }

    /// Spielkennungen im Rahmen tragen oft die Speicherkennung („maumau-neu“); das Wissen hängt an der Grund-ID.
    public static func grundID(_ id: String) -> String {
        id.hasSuffix("-neu") ? String(id.dropLast(4)) : id
    }

    public static func wissen(fuer id: String) -> (any RegelWissen)? {
        lieferant?(grundID(id))
    }
}

public enum RegelChatEinstieg {
    /// Status des Einstiegs für ein Spiel: kein Wissen oder kein Modell → `.hidden` (nichts sichtbar).
    /// `wissen` ist die eigene Quelle des Spiels (`mitRegelWissen`), sonst der Katalog.
    public static func status(spielID: String, wissen: (any RegelWissen)? = nil) -> RegelChatStatus {
        guard let wissen = wissen ?? RegelWissenKatalog.wissen(fuer: spielID) else { return .hidden }
        let status = RegelChatStatus.aktuell(nurDeutscheApp: wissen.nurDeutscheApp)
        // Ohne ein Modell, das antworten könnte, gibt es keinen Chat (Hinweise für „aus“ und „lädt“ bleiben)
        if status == .available, wissen.sprachmodell() == nil, sprachmodell() == nil { return .hidden }
        return status
    }

    /// Das Modell für den Chat: im Simulator mit Startargument `-PartieRegelChatAttrappe YES` die Attrappe (nur Debug),
    /// sonst Apples Modell auf dem Gerät (iOS 26 mit FoundationModels), sonst `nil`.
    public static func sprachmodell() -> (any RegelChatSprachmodell)? {
        if RegelChatUmgebung.attrappeAngefordert { return RegelChatUmgebung.attrappe() }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) { return AppleSprachmodell() }
        #endif
        // Test mit vorgegebenem Status (ohne Attrappe-Argument): die Attrappe antwortet
        if RegelChatUmgebung.statusVorgabe != nil { return RegelChatUmgebung.attrappe() }
        return nil
    }
}
