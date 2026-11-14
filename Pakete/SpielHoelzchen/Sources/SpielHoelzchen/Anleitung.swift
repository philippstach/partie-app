// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension HoelzchenModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "hand.tap", titel: "Aus einer Reihe nehmen", text: "Du nimmst aus genau einer Reihe beliebig viele Hölzchen, mindestens eines. Tippe auf ein Hölzchen: Es wird mit allen rechts davon markiert.", geste: .tippen(.zelle(1, 2, zeilen: 3, spalten: 5)), ["*****", "*****", "*****"], ["*****", "**   ", "*****"], zelle: 44),
        .bild(symbol: "flag.checkered", titel: "Klassisch", text: "Im Modus „Klassisch“ gewinnt, wer das letzte Hölzchen nimmt.", bild: "trophy.fill", geste: .keine),
        .bild(symbol: "exclamationmark.triangle", titel: "Pechvogel", text: "Im Modus „Pechvogel“ verliert, wer das letzte Hölzchen nehmen muss.", bild: "exclamationmark.triangle.fill", geste: .keine),
    ] }
}
#endif
