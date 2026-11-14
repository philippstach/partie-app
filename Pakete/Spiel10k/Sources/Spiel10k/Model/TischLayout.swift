// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import UIKit

/// Aufbau einer Seite nach der verfügbaren Breite, nicht nach dem Gerät (Doku/SPEC-1.1-IPAD.md §2).
/// Das iPad in schmalem Split View oder kleinem Stage-Manager-Fenster bekommt das iPhone-Layout.
nonisolated enum TischLayout: Equatable, Sendable {
    case kompakt, breitHoch, breitQuer

    /// Unter dieser Breite gilt immer `kompakt` (vorläufig)
    static let kompaktUnter: CGFloat = 700
    /// Querformat erst ab dieser Breite (vorläufig)
    static let querAb: CGFloat = 1000

    static func layout(breite: CGFloat, hoehe: CGFloat, sizeClass: UserInterfaceSizeClass?,
                       grosseSchrift: Bool = false) -> TischLayout {
        if sizeClass == .compact || breite < kompaktUnter { return .kompakt }
        // Bedienungshilfen-Schriftgrößen: Spalten würden zu schmal → untereinander
        if grosseSchrift { return .breitHoch }
        return breite > hoehe && breite >= querAb ? .breitQuer : .breitHoch
    }

    var breit: Bool { self != .kompakt }
}

/// Gerätename für Texte („auf einem iPhone“ bzw. „iPad“) und gerätespezifische Schalter.
nonisolated enum Geraet {
    enum Art { case iPhone, iPad }

    static func name(_ art: Art) -> String { art == .iPad ? "iPad" : "iPhone" }

    @MainActor static var aktuell: Art { UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone }
    @MainActor static var name: String { name(aktuell) }
}

/// Tastenkürzel des iPads an einer Stelle (SPEC-1.1 §5) – damit sie eindeutig bleiben (Test).
nonisolated enum Kuerzel {
    struct Eintrag: Equatable, Sendable {
        let taste: Character
        let befehl: Bool
        let titel: String
    }

    static let neuesSpiel = Eintrag(taste: "n", befehl: true, titel: String(localized: "Neues Spiel"))
    static let einstellungen = Eintrag(taste: ",", befehl: true, titel: String(localized: "Einstellungen"))
    static let regeln = Eintrag(taste: "r", befehl: true, titel: String(localized: "Regeln"))
    static let regelChat = Eintrag(taste: "/", befehl: true, titel: String(localized: "Frag nach den Regeln"))
    static let rueckgaengig = Eintrag(taste: "z", befehl: true, titel: String(localized: "Rückgängig"))

    static let alle = [neuesSpiel, einstellungen, regeln, regelChat, rueckgaengig]
}

extension View {
    /// Kürzel aus `Kuerzel` anhängen
    func kuerzel(_ k: Kuerzel.Eintrag) -> some View {
        keyboardShortcut(KeyEquivalent(k.taste), modifiers: k.befehl ? .command : [])
    }
}

/// VoiceOver-Ansagen im Zug (Build 11) – reine Textfunktionen, unit-getestet.
nonisolated enum VoiceOverText {
    private static func punkte(_ n: Int) -> String {
        n.formatted(.number.locale(Locale(identifier: "de_DE")))
    }

    /// Nach einem digitalen Wurf: geworfene Augen und die beste Auswahl
    static func wurf(_ augen: [Int], beste: Int) -> String {
        String(localized: "Geworfen: \(augen.map(String.init).joined(separator: ", ")). ")
            + (beste > 0 ? String(localized: "Beste Auswahl \(punkte(beste)) Punkte.") : String(localized: "Keine Punkte."))
    }

    static func niete(verloren: Int, strafe: Int) -> String {
        var t = verloren > 0 ? String(localized: "Niete! \(punkte(verloren)) Punkte sind weg.") : String(localized: "Niete! Kein Würfel bringt Punkte.")
        if strafe > 0 { t += String(localized: " Strafe: minus \(punkte(strafe)) Punkte.") }
        return t
    }

    static func amZug(_ name: String, punkte stand: Int) -> String {
        String(localized: "Jetzt am Zug: \(name), \(punkte(stand)) Punkte.")
    }
}
