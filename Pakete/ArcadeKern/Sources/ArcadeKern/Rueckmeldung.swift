// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Einheitliche Rückmeldung (Haptik und Ton) für alle Arcade-Spiele. Die Entscheidung, *was* bei *welchem* Ereignis kommt, ist hier
/// reine Logik (testbar); das Abspielen übernimmt die Hülle in `SpieleKern`.
public enum ArcadeEreignis: Hashable, Sendable {
    /// Punkte sind gestiegen (Treffer, Reihe, Wolke, Stein …).
    case treffer
    /// Ein Leben oder ein Punkt gegen den Spieler (das Spiel läuft weiter).
    case lebenVerloren
    /// Das Spiel ist aus, ohne neuen Rekord (oder das Duell ist verloren).
    case verlust
    /// Neuer Rekord oder Duell gewonnen.
    case rekord
}

public enum ArcadeHaptik: Equatable, Sendable { case leicht, mittel, erfolg, fehler }
public enum ArcadeTon: Equatable, Sendable { case tick, aus, fanfare }

public struct ArcadeAusgabe: Equatable, Sendable {
    public var haptik: ArcadeHaptik?
    public var ton: ArcadeTon?
}

public struct ArcadeRueckmeldung: Equatable, Sendable {
    /// Kürzester Abstand je Ereignis (Sekunden): viele Treffer kurz hintereinander ergeben nur einen Impuls.
    public static func mindestAbstand(_ e: ArcadeEreignis) -> Double {
        switch e { case .treffer: 0.12; case .lebenVerloren: 0.5; case .verlust, .rekord: 1.0 }
    }

    private var letzte: [ArcadeEreignis: Double] = [:]
    public init() {}

    /// Was soll jetzt passieren? `nil` = nichts (beide Schalter aus, zu kurz nach dem letzten gleichen Ereignis oder Pause).
    public mutating func melden(_ e: ArcadeEreignis, zeit: Double, haptikAn: Bool, tonAn: Bool, pausiert: Bool = false) -> ArcadeAusgabe? {
        guard !pausiert, haptikAn || tonAn else { return nil }
        if let l = letzte[e], zeit - l < ArcadeRueckmeldung.mindestAbstand(e) { return nil }
        letzte[e] = zeit
        let h: ArcadeHaptik, t: ArcadeTon
        switch e {
        case .treffer: h = .leicht; t = .tick
        case .lebenVerloren: h = .mittel; t = .aus
        case .verlust: h = .fehler; t = .aus
        case .rekord: h = .erfolg; t = .fanfare
        }
        return ArcadeAusgabe(haptik: haptikAn ? h : nil, ton: tonAn ? t : nil)
    }

    /// Ereignis am Ende eines Punktespiels: Rekord (echt höher als bisher, größer als 0) oder Verlust.
    public static func endeEreignis(punkte: Int, bisherigerRekord: Int?) -> ArcadeEreignis {
        Rekord.istNeu(punkte: punkte, bisher: bisherigerRekord) ? .rekord : .verlust
    }
}
