// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

extension Wertung {
    /// „Schock 4“, „General 5“, „Straße 4-5-6“, „Zahl 653“, „Jule“, „Schock aus“
    var name: String {
        switch art {
        case .schockAus: String(localized: "Schock aus")
        case .jule: String(localized: "Jule")
        case .schock: String(localized: "Schock \(hoehe)")
        case .general: String(localized: "General \(hoehe)")
        case .strasse: String(localized: "Straße \(hoehe - 2)-\(hoehe - 1)-\(hoehe)")
        case .zahl: String(localized: "Zahl \(hoehe)")
        }
    }

    /// Nur die Art, ohne Höhe (für die Rangfolge)
    var istStark: Bool { art.rang >= WertungsArt.schock.rang }
}

func wuerfeText(_ n: Int) -> String {
    n == 1 ? String(localized: "1 Wurf") : String(localized: "\(n) Würfe")
}

extension Strategie {
    var name: String {
        switch self {
        case .mensch: String(localized: "Mensch")
        case .einfach: String(localized: "Computer einfach")
        case .gut: String(localized: "Computer gut")
        }
    }

    var kurz: String {
        switch self {
        case .mensch: ""
        case .einfach: String(localized: "Computer · einfach")
        case .gut: String(localized: "Computer · gut")
        }
    }
}

extension Haelfte.Art {
    var titel: String {
        switch self {
        case .haelfte1: String(localized: "Hälfte 1")
        case .haelfte2: String(localized: "Hälfte 2")
        case .finale: String(localized: "Finale")
        }
    }
}

extension Optionen {
    /// Kurzfassung für die Startseite: „Standard · 13 Deckel · Finale“
    var kurzfassung: String {
        var teile: [String] = []
        let abweichend = jule || herauslegen != .einsen || !sechsenUmdrehen || !schockAusEndet
        teile.append(abweichend ? String(localized: "Angepasst") : String(localized: "Standard"))
        teile.append(String(localized: "\(deckel) Deckel"))
        teile.append(spiellaenge == .partie ? String(localized: "Finale") : String(localized: "eine Hälfte"))
        return teile.joined(separator: " · ")
    }
}

extension Spielzustand {
    func name(_ i: Int) -> String { namen[i] }

    /// Ergebnis-Text der Runde für einen Spieler: „Schock 4 · 2 Würfe“ oder nil
    func rundenText(_ spieler: Int) -> String? {
        if phase == .zugEnde, aktuellerSpieler == spieler, let zug = runde.zug {
            return "\(zug.wertung().name) · \(wuerfeText(zug.wuerfe))"
        }
        guard let z = runde.zuege.first(where: { $0.spieler == spieler }) else { return nil }
        let e = z.ergebnis
        return "\(e.wertung.name) · \(wuerfeText(e.wuerfe))"
    }

    /// Heißt der Spieler „Du“ (geführte Partie), braucht der Satz die Du-Form („Du bist dran“ statt „Du ist dran“).
    func istDu(_ i: Int) -> Bool { namen[i] == String(localized: "Du") }

    func istDran(_ i: Int) -> String {
        istDu(i) ? String(localized: "Du bist dran") : String(localized: "\(namen[i]) ist dran")
    }

    func verliertHaelfte(_ i: Int) -> String {
        istDu(i) ? String(localized: "Du verlierst die Hälfte") : String(localized: "\(namen[i]) verliert die Hälfte")
    }

    func hatVerloren(_ i: Int) -> String {
        istDu(i) ? String(localized: "Du hast verloren") : String(localized: "\(namen[i]) hat verloren")
    }

    func hatGeworfen(_ i: Int) -> String {
        istDu(i) ? String(localized: "Du hast geworfen") : String(localized: "\(namen[i]) hat geworfen")
    }

    func hatAlleDeckel(_ i: Int, _ haelfte: String) -> String {
        istDu(i) ? String(localized: "Du hast alle Deckel – \(haelfte) verloren.")
                 : String(localized: "\(namen[i]) hat alle Deckel – \(haelfte) verloren.")
    }

    func beginntNaechste(_ i: Int) -> String {
        istDu(i) ? String(localized: "Du beginnst die nächste Runde.") : String(localized: "\(namen[i]) beginnt die nächste Runde.")
    }

    /// „Anna gibt Ben 3 Deckel“ (mit „Du“ als Geber oder Empfänger)
    func gibtDeckel(von g: Int, an v: Int, _ n: Int) -> String {
        if istDu(g) { return String(localized: "Du gibst \(namen[v]) \(n) Deckel") }
        if istDu(v) { return String(localized: "\(namen[g]) gibt dir \(n) Deckel") }
        return String(localized: "\(namen[g]) gibt \(namen[v]) \(n) Deckel")
    }

    /// Banner nach der Rundenwertung
    var bannerText: String? {
        guard let a = runde.ausgang else { return nil }
        let v = a.verlierer
        if istDu(v) {
            if a.schockAus { return String(localized: "Du verlierst die Runde – Schock aus: alle Deckel") }
            if a.ausStock { return String(localized: "Du verlierst die Runde – \(a.deckel) Deckel aus dem Stock") }
        } else {
            if a.schockAus { return String(localized: "\(namen[v]) verliert die Runde – Schock aus: alle Deckel") }
            if a.ausStock { return String(localized: "\(namen[v]) verliert die Runde – \(a.deckel) Deckel aus dem Stock") }
        }
        return gibtDeckel(von: a.gewinner, an: v, a.deckel)
    }
}
