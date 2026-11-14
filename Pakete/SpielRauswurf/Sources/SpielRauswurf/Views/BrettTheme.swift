// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
// design:spielinhalt-datei

/// Alle Brett- und Figurenfarben, Sitz-Symbole und Formen an einer Stelle (DESIGN.md, „Platzhalter-Optik“).
/// Name und Optik der App sind noch offen (M1/M2): Wer das Aussehen tauschen will, ändert nur diese Datei.
/// Keine View enthält einen Farbwert.
struct BrettTheme: Equatable {
    struct Sitz: Equatable {
        /// Farbe der Figuren, Häuser, Start- und Zielfelder
        var farbe: Color
        /// Textfarbe (im hellen Modus abgedunkelt)
        var textfarbe: Color
        /// SF Symbol auf Figur und Haus (für Farbenblinde, immer an)
        var symbol: String
    }

    var sitze: [Sitz]

    /// Eigene Brettfläche (Papier/Filz) hinter Feldern und Häusern; nil = Karte der App
    var flaeche: Color?
    /// feine Körnung auf der Brettfläche (2 %)
    var koernung = false
    /// Felder „geprägt“: Innenschatten oben, helle Kante unten
    var gepraegt = false
    /// Figuren mit radialem Verlauf und Glanzlicht
    var glanz = false
    /// Stärke des Innenschattens oben bei geprägten Feldern (Schwarz)
    var praegungOben: CGFloat = 0.12
    /// Größe des Glanzlichts (Anteil der Figur)
    var glanzGroesse: CGFloat = 0.18
    /// Häuser und Ziele um diesen Anteil entsättigt (0…1)
    var entsaettigung: CGFloat = 0

    // Felder
    var feldAnteil: CGFloat = 0.78            // Kreis im Verhältnis zur Zelle
    var feldFuellung = Color(.tertiarySystemFill)
    var feldRand = Color(.separator)
    var neutralFlaeche = Color(.quaternarySystemFill)
    var startFuellung: CGFloat = 0.35
    var zielFuellung: CGFloat = 0.20
    var zielRand: CGFloat = 0.60
    var hausFuellung: CGFloat = 0.15
    var hausRadius: CGFloat = 16

    // Figuren
    var figurAnteil: CGFloat = 0.70
    var figurRing = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1) : .white })
    var figurSymbol = Color.white

    // Markierungen (die App-Farbe ist nie eine Spielerfarbe)
    var markierung = Color.appFlaeche

    func farbe(_ sitz: Int) -> Color { sitze[sitz % sitze.count].farbe }

    /// Farbe für Häuser, Start- und Zielfelder (bei „Warm“ leicht entsättigt)
    func flaechenFarbe(_ sitz: Int) -> Color {
        guard entsaettigung > 0 else { return farbe(sitz) }
        return Color(uiColor: UIColor(farbe(sitz)).entsaettigt(entsaettigung))
    }
    func textfarbe(_ sitz: Int) -> Color { sitze[sitz % sitze.count].textfarbe }
    func symbol(_ sitz: Int) -> String { sitze[sitz % sitze.count].symbol }

    /// Name des Sitzes („Blau“ …), übersetzt.
    func name(_ sitz: Int) -> String { L("sitz.\(sitz % sitze.count)") }

    static let standard: BrettTheme = {
        let hex: [UInt32] = [0x5B9FD9, 0x4FBF7A, 0xE06666, 0xA66BD9]        // Blau, Grün, Koralle, Violett
        let symbole = ["circle.fill", "triangle.fill", "square.fill", "diamond.fill"]
        return BrettTheme(sitze: (0 ..< 4).map { i in
            Sitz(farbe: Color(hex: hex[i]), textfarbe: Theme.textColor(hex: hex[i]), symbol: symbole[i])
        })
    }()
}

private struct BrettThemeKey: EnvironmentKey {
    static let defaultValue = BrettTheme.standard
}

extension EnvironmentValues {
    var brettTheme: BrettTheme {
        get { self[BrettThemeKey.self] }
        set { self[BrettThemeKey.self] = newValue }
    }
}

extension BrettTheme {
    /// Zweite Optik „Warm“: Papier bzw. Filz, geprägte Felder, Figuren mit Glanz (DESIGN „Thema Warm“).
    static let warm: BrettTheme = {
        var t = BrettTheme.standard
        t.flaeche = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.165, green: 0.129, blue: 0.086, alpha: 1) : UIColor(red: 0.937, green: 0.902, blue: 0.824, alpha: 1) })
        t.koernung = true
        t.gepraegt = true
        t.glanz = true
        t.entsaettigung = 0.08
        t.feldFuellung = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.12, green: 0.09, blue: 0.055, alpha: 1) : UIColor(red: 0.89, green: 0.85, blue: 0.75, alpha: 1) })
        t.feldRand = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.07, green: 0.05, blue: 0.03, alpha: 1) : UIColor(red: 0.78, green: 0.74, blue: 0.64, alpha: 1) })     // Grund −12 % Helligkeit
        t.praegungOben = 0.18
        t.glanzGroesse = 0.24
        t.neutralFlaeche = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.05) : UIColor(white: 0, alpha: 0.05) })
        return t
    }()

    static func thema(_ art: BrettThemaArt) -> BrettTheme { art == .warm ? .warm : fuerDesign(.standard) }

    /// Designwechsel D.4: Brett der Designs Tinte (Linien auf Papier) und Salon (Creme mit Feldern in Feldgrund). Die Spielerfarben bleiben
    /// (Farbe, Symbol und Form unterscheiden die Sitze). In „Klar & Glas“ kommt `basis` unverändert zurück.
    static func fuerDesign(_ basis: BrettTheme) -> BrettTheme {
        guard !Design.ist(.klar) else { return basis }
        var t = basis
        t.gepraegt = false; t.glanz = false; t.koernung = false
        t.figurRing = Color.seitenGrund
        if Design.ist(.tinte) {
            t.flaeche = Color.seitenGrund
            t.feldFuellung = Color.kartenGrund
            t.feldRand = Color.linieStark
            t.neutralFlaeche = Color.feldGrund
            t.hausRadius = 10   // Design-Runde 3: runde Ecken auch im Haus
        } else {
            t.flaeche = Color.kartenGrund
            t.feldFuellung = Color.feldGrund
            t.feldRand = Color.linieStark.opacity(0.5)   // Lauffelder: Linien-Rolle in halber Stärke (die feine Linie war auf Feldgrund kaum zu sehen)
            t.neutralFlaeche = Color.feldGrund
            t.hausRadius = 2
        }
        return t
    }
}

/// Auswahl in den Einstellungen („Brett: Klar / Warm“).
enum BrettThemaArt: String, CaseIterable, Sendable {
    case klar, warm
}

private extension UIColor {
    func entsaettigt(_ anteil: CGFloat) -> UIColor {
        var h: CGFloat = 0, sat: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &sat, brightness: &b, alpha: &a) else { return self }
        return UIColor(hue: h, saturation: sat * (1 - anteil), brightness: b, alpha: a)
    }
}
