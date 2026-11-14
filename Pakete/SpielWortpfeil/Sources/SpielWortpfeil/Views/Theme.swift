// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
// design:spielinhalt-datei – Rätselgitter: Felder, Fragetinte, Linien (Spielmaterial)
import SwiftUI
import KlarGlas
import SpieleKern

extension Color {
    // MARK: Klar & Glas – Kreuzworträtsel in Blau (Design-Akzent 1658D8, 10.11.2026)
    // Alle Werte sind feste, deckende Farben, damit der Kontrast in hell und dunkel feststeht (Tests: `FarbKontrastTests`).

    /// Akzent für Text, Symbole, Linien und gefüllte Flächen: hell 1658D8, dunkel 6FA8FF
    static let kwAkzent = Color(hell: KwFarbe.akzent.hell, dunkel: KwFarbe.akzent.dunkel)
    /// Schrift und Symbole AUF einer Akzentfläche: hell Weiß, dunkel Nachtblau (Weiß auf 6FA8FF wäre nur 2,4:1)
    static let kwAufAkzent = Color(hell: KwFarbe.aufAkzent.hell, dunkel: KwFarbe.aufAkzent.dunkel)
    /// Heldenkarte der Startseite und Schrift darauf
    static let kwHeld = Color(hell: KwFarbe.held.hell, dunkel: KwFarbe.held.dunkel)
    static let kwAufHeld = Color(hell: KwFarbe.aufHeld.hell, dunkel: KwFarbe.aufHeld.dunkel)
    /// App-Hintergrund
    static var papier: Color { Color.seitenGrund }   // var statt let: sonst bleibt der Wert des zuerst gelesenen Designs stehen
    /// Karten, Frageleiste, Tasten
    static var karte: Color { Color.kartenGrund }
    /// Buchstabenfeld (zum Ausfüllen)
    static let feldLeer = Color(hell: KwFarbe.feldLeer.hell, dunkel: KwFarbe.feldLeer.dunkel)
    /// Fragefeld: zartes Blau, deckend
    static let feldFrage = Color(hell: KwFarbe.feldFrage.hell, dunkel: KwFarbe.feldFrage.dunkel)
    /// Gesperrtes Leerfeld: neutrales Grau
    static let feldSperre = Color(hell: KwFarbe.feldSperre.hell, dunkel: KwFarbe.feldSperre.dunkel)
    /// Eigene Buchstaben
    static let tinte = Color.primary
    /// Fragetext im Feld: fast schwarz bzw. fast weiß (kleine Schrift braucht den größten Kontrast)
    static let frageTinte = Color(hell: KwFarbe.frageTinte.hell, dunkel: KwFarbe.frageTinte.dunkel)
    /// Falsche Buchstaben
    static let fehler = Color(hell: KwFarbe.fehler.hell, dunkel: KwFarbe.fehler.dunkel)
    // Gitter-Rollen (Punkt 1, Runde 3): Klar = bisherige Blau-Werte, Tinte/Salon = Rollen des Designs. `var`, damit der Wechsel greift.
    static var gAkzent: Color { Design.art == .klar ? kwAkzent : .knopfFlaeche }
    static var gAufAkzent: Color { Design.art == .klar ? kwAufAkzent : .schriftAufKnopf }
    /// Fund 19: Leerfeld in Tinte/Salon dunkel deutlich heller als der Grund (vorher fast schwarz 1C1C1E auf dunklem Tisch)
    static var gFeldLeer: Color { Design.art == .klar ? feldLeer : Color(hell: 0xFFFFFF, dunkel: 0x3A3A3F) }
    static var gFrageFeld: Color { Design.art == .klar ? feldFrage : .feldGrund }
    static var gFrageText: Color { Design.art == .klar ? frageTinte : .schrift }
    static var gPfeil: Color { Design.art == .klar ? kwAkzent : .schriftZweit }
    static var gLinie: Color { Design.art == .klar ? linie : (Design.werte.linie?.color ?? .linieStark) }
    /// Aktives Wort im Buchstabenfeld: Klar Akzent mit Deckkraft, sonst accentSoft des Designs (Akzent-Rolle mit Deckkraft)
    static func gWort(dunkel: Bool) -> Color {
        Design.art == .klar ? kwAkzent.opacity(dunkel ? KwFarbe.wortMarkierung.dunkel : KwFarbe.wortMarkierung.hell)
                            : gAkzent.opacity(dunkel ? 0.22 : 0.16)
    }
    /// Gitterlinien
    static let linie = Color(hell: KwFarbe.linie.hell, dunkel: KwFarbe.linie.dunkel)
}

extension View {
    func card(padding: CGFloat) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.karte, in: .rect(cornerRadius: Theme.cardRadius))
    }
}
#endif
