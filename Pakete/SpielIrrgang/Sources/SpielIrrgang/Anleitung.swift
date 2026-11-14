// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension IrrgangModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "arrow.right", titel: "Wischen und laufen", text: "Wische in eine Richtung: Dein Läufer geht geradeaus und hält erst vor einer Wand, an einer Abzweigung, an einem Funken oder am Ausgang an.", geste: .wischen(von: UnitPoint(x: 0.3, y: 0.5), nach: UnitPoint(x: 0.7, y: 0.5)), ["*..~"], ["...*"], zelle: 44),
        .bild(symbol: "sparkles", titel: "Funken sammeln", text: "Funken liegen in Sackgassen und bringen 50 Punkte extra. Je kürzer dein Weg, desto mehr Bonus.", bild: "sparkles", geste: .keine),
        .bild(symbol: "chart.line.uptrend.xyaxis", titel: "Stufen und Tipp", text: "Jede Stufe bringt ein größeres Labyrinth, ab Stufe 4 siehst du nur noch einen Ausschnitt, der auf höheren Stufen kleiner wird. „Zug zurück“ behält die Schritte. Ein Tipp zeigt die Richtung, kostet aber 25 Punkte.", bild: "chart.line.uptrend.xyaxis", geste: .keine),
    ] }

    /// Neue deutsche Fassung (Regeltexte neu, Build 25) ohne Zielseite (`mitZielSchrittNeu`): dieselben drei Bühnen, Texte ergänzt.
    static var anleitungNeu: [AnleitungSchritt] { [
        .raster(symbol: "arrow.right", titel: "Wischen und laufen", text: "Wische in eine Richtung: Dein Läufer geht geradeaus und hält erst vor einer Wand, an einer Abzweigung, an einem Funken oder am Ausgang an. Er biegt nie von allein ab. Du kannst überall auf dem Bildschirm wischen.", geste: .wischen(von: UnitPoint(x: 0.3, y: 0.5), nach: UnitPoint(x: 0.7, y: 0.5)), ["*..~"], ["...*"], zelle: 44),
        .bild(symbol: "sparkles", titel: "Funken sammeln", text: "Funken liegen in Sackgassen und bringen 50 Punkte extra. Jede Stufe bringt 100 Punkte mal die Stufe, und für einen kurzen Weg gibt es einen Bonus dazu. Wäge ab: Lohnt sich der Abstecher zum Funken?", bild: "sparkles", geste: .keine),
        .bild(symbol: "chart.line.uptrend.xyaxis", titel: "Stufen und Tipp", text: "Jede Stufe bringt ein größeres Labyrinth. Ab Stufe 4 siehst du nur noch einen Ausschnitt, der auf höheren Stufen kleiner wird. „Zug zurück“ nimmt einen Wisch zurück, die Schritte bleiben gezählt. Ein Tipp zeigt die Richtung, kostet aber 25 Punkte. Jeden Tag gibt es einen Tageslauf, der für alle gleich ist.", bild: "chart.line.uptrend.xyaxis", geste: .keine),
    ] }
}
#endif
