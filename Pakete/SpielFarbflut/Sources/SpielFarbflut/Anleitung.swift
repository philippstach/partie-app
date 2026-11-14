// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension FarbflutModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "drop.fill", titel: "Farbe wählen", text: "Die Flut beginnt oben links. Tippe unten eine Farbe an: Die ganze Flut nimmt sie an und schluckt angrenzende Felder in dieser Farbe.", geste: .tippen(UnitPoint(x: 0.5, y: 0.9)), ["rbb", "bgg", "rgr"], ["bbb", "bgg", "rgr"], zelle: 44),
        .bild(symbol: "checkmark.seal", titel: "Eine Farbe, wenige Züge", text: "Färbe das ganze Feld in einer Farbe, bevor deine Züge aufgebraucht sind. Jedes Feld ist garantiert lösbar.", bild: "checkmark.seal.fill", geste: .keine),
    ] }

    /// Neue deutsche Fassung (Regeltexte neu, Build 25) ohne Zielseite (`mitZielSchrittNeu`): die zwei Bühnen wie heute, eine Figurenseite dazu.
    static var anleitungNeu: [AnleitungSchritt] { [
        .raster(symbol: "drop.fill", titel: "Farbe wählen", text: "Die Flut beginnt oben links. Tippe unten eine Farbe an: Die ganze Flut nimmt sie an und schluckt alle angrenzenden Felder in dieser Farbe. So wächst sie mit jedem Zug. Die Felder der Flut haben einen weißen Rahmen.", geste: .tippen(UnitPoint(x: 0.5, y: 0.9)), ["rbb", "bgg", "rgr"], ["bbb", "bgg", "rgr"], zelle: 44),
        .bild(symbol: "checkmark.seal", titel: "Eine Farbe, wenige Züge", text: "Oben siehst du, wie viele Züge du noch hast. Ist das Feld einfarbig, hast du gewonnen. Jeder übrige Zug bringt 10 Extrapunkte. Jedes Feld ist lösbar. Tipp: Arbeite dich zur Mitte vor, von dort erreichst du viele Felder auf einmal.", bild: "checkmark.seal.fill", geste: .keine),
        .figuren(symbol: "slider.horizontal.3", titel: "Stufen, Tagesrätsel und Hilfen", text: "Mit drei Siegen ohne Tipp schaltest du die nächste Stufe frei: Leicht, Normal, Schwer. Das Tagesrätsel bekommen am selben Tag alle. „Tipp“ zeigt eine gute Farbe, „Zurück“ nimmt Züge zurück. Mit Tipp gibt es keine Bestleistung.", figuren: ["🟥", "🟦", "🟩", "📅"]),
    ] }
}
#endif
