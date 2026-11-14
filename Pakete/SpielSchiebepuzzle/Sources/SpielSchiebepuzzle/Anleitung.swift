// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension SchiebepuzzleModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "square.grid.3x3", titel: "Kachel verschieben", text: "Tippe eine Kachel in der Reihe der Lücke, um sie (und alle dazwischen) zu verschieben.", geste: .tippen(.zelle(1, 1, zeilen: 2, spalten: 3)), ["123", "45 "], ["123", "4 5"], zelle: 44),
        .raster(symbol: "flag.checkered", titel: "Ordnung herstellen", text: "Schiebe, bis die Zahlen der Reihe nach stehen und die Lücke unten rechts ist. Weniger Züge sind besser.", geste: .keine, ["123", "4 5"], ["123", "45 "], zelle: 44),
        .bild(symbol: "square.grid.3x3", titel: "Größe und Tipp", text: "Im Menü wählst du 3 × 3 bis 6 × 6. Der Tipp zeigt die nächste Kachel, Rückgängig nimmt Züge zurück.", bild: "square.grid.3x3", geste: .keine),
    ] }

    /// Neue deutsche Fassung (Regeltexte neu, Build 25): wie heute drei Raster-/Bildseiten, Texte ausführlicher. Die Zielseite kommt über `mitZielSchrittNeu`.
    static var anleitungNeu: [AnleitungSchritt] { [
        .raster(symbol: "square.grid.3x3", titel: "Kachel verschieben", text: "Tippe eine Kachel in derselben Zeile oder Spalte wie die Lücke. Sie rutscht in die Lücke, und alle Kacheln dazwischen rutschen mit. Das zählt als ein Zug. Kacheln am richtigen Platz siehst du voll, die anderen etwas blasser.", geste: .tippen(.zelle(1, 1, zeilen: 2, spalten: 3)), ["123", "45 "], ["123", "4 5"], zelle: 44),
        .raster(symbol: "flag.checkered", titel: "Ordnung herstellen", text: "Schiebe, bis die Zahlen der Reihe nach stehen und die Lücke unten rechts ist. Ein guter Weg: Ordne zuerst die oberste Zeile, dann die linke Spalte, und rühre sie danach nicht mehr an. Weniger Züge sind besser, die App merkt sich deine Bestleistung.", geste: .keine, ["123", "4 5"], ["123", "45 "], zelle: 44),
        .bild(symbol: "square.grid.3x3", titel: "Größe, Tagesrätsel und Tipp", text: "Vor dem Start wählst du die Größe von 3 × 3 bis 6 × 6 und ob du das Tagesrätsel spielst. Das bekommen am selben Tag alle. „Tipp“ zeigt dir die nächste Kachel, „Rückgängig“ unter „Mehr“ nimmt Züge zurück. Mit Tipp gibt es keine Bestleistung.", bild: "square.grid.3x3", geste: .keine),
    ] }
}
#endif
