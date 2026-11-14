// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension KakuroModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "sum", titel: "Summen bilden", text: "Die Zahl im Hinweisfeld ist die Summe der Ziffern daneben beziehungsweise darunter bis zum nächsten dunklen Feld.", geste: .tippen(.zelle(0, 1, zeilen: 2, spalten: 3)), ["7..", "#.."], ["725", "#.."], zelle: 44),
        .raster(symbol: "xmark.circle", titel: "Keine Ziffer doppelt", text: "Innerhalb einer Summe darf keine Ziffer doppelt vorkommen. Doppelte oder zu große Summen werden rot markiert.", geste: .keine, ["8..", "#.."], ["8rr", "#.."], zelle: 44),
    ] }

    /// Neue deutsche Fassung (Regeltexte neu, Build 25) ohne Zielseite (`mitZielSchrittNeu`): die zwei Raster-Bühnen wie heute, eine Figurenseite dazu.
    static var anleitungNeu: [AnleitungSchritt] { [
        .raster(symbol: "sum", titel: "Summen bilden", text: "Die Zahl oben rechts im dunklen Feld ist die Summe der weißen Felder rechts daneben, bis zum nächsten dunklen Feld. Die Zahl unten links gilt für die Felder darunter. So eine Reihe heißt Lauf. Jedes weiße Feld gehört meist zu zwei Läufen und muss für beide passen.", geste: .tippen(.zelle(0, 1, zeilen: 2, spalten: 3)), ["7..", "#.."], ["725", "#.."], zelle: 44),
        .raster(symbol: "xmark.circle", titel: "Keine Ziffer doppelt", text: "In einem Lauf darf jede Ziffer nur einmal stehen. Eine 8 über zwei Feldern geht also als 1 + 7, 2 + 6 oder 3 + 5, aber nicht als 4 + 4. Doppelte Ziffern und zu große Summen färbt die App rot. Manche Ziffern stehen schon fest, die gibt die App vor.", geste: .keine, ["8..", "#.."], ["8rr", "#.."], zelle: 44),
        .figuren(symbol: "lightbulb", titel: "Hilfen und Größen", text: "Unter dem Ziffernblock steht, welche Ziffern noch möglich sind. „Prüfen“ zeigt falsche Felder, „Tipp“ trägt eine richtige Ziffer ein. Mit Tipp gibt es aber keine Bestzeit. Es gibt drei Größen, die größeren öffnen sich nach drei Rätseln ohne Tipp. Jeden Tag wartet ein Tagesrätsel. Alles Weitere unter „Alle Regeln lesen“.", figuren: ["💡", "✔️", "📅"]),
    ] }
}
#endif
